//
//  HomeViewModel.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var lists: [ListModel] = [] // Active Lists
    @Published var recentlyDeletedLists: [ListModel] = [] // Recently Deleted Lists
    @Published var errorMessage: String? = nil
    @Published var showMenu: Bool = false
    @Published var searchQuery: String = "" // Search Query for filtering
    @Published var currentPieIndex: Int = 0 // Tracks the most recent pie index

    let maxListsPerPie = 8 // Maximum number of slices per pie chart
    private let databaseService = FirebaseDatabaseService() // Use the new database service
    private var hasLoadedData = false

    // MARK: - Initialization
    init() {
        loadDataIfNeeded()
    }

    // MARK: - Load Data
    func loadDataIfNeeded() {
        guard !hasLoadedData else { return }
        loadData()
        hasLoadedData = true
    }

    private func loadData() {
        databaseService.loadLists { [weak self] result in
            switch result {
            case .success(let (activeLists, deletedLists)):
                self?.lists = activeLists
                self?.recentlyDeletedLists = deletedLists
                self?.updateCurrentPieIndex()
                self?.printDebugData()
            case .failure(let error):
                self?.errorMessage = "Failed to load lists: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Add List
    func addList(title: String, items: [String]) {
        guard !title.isEmpty else {
            errorMessage = "List title cannot be empty."
            printDebugData()
            return
        }

        let listItems = items.map { ListModel.ListItem(name: $0) }
        var newList = ListModel(title: title, cakeno: 0, items: listItems)

        assignImage(to: &newList)

        databaseService.addList(newList) { [weak self] result in
            switch result {
            case .success:
                self?.lists.append(newList)
                self?.updateCurrentPieIndex()
                self?.updatePieSlices()
                self?.printDebugData()
            case .failure(let error):
                self?.errorMessage = "Failed to add list: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Delete List and Update UI
    func deleteAndUpdate(list: ListModel) {
        guard let index = lists.firstIndex(of: list) else { return }

        let deletedCakeno = list.cakeno
        lists.remove(at: index)

        // If there is only one pie, no need for cascading changes
        if lists.count <= maxListsPerPie {
            updatePieSlices()
            databaseService.deleteList(list, permanently: false) { [weak self] result in
                switch result {
                case .success:
                    self?.recentlyDeletedLists.append(list)
                    self?.printDebugData()
                case .failure(let error):
                    self?.errorMessage = "Failed to delete list: \(error.localizedDescription)"
                }
            }
            return
        }

        reassignCakenos(fromPieIndex: currentPieIndex - 1, targetCakeno: deletedCakeno)

        databaseService.deleteList(list, permanently: false) { [weak self] result in
            switch result {
            case .success:
                self?.recentlyDeletedLists.append(list)
                self?.updateCurrentPieIndex()
                self?.updatePieSlices()
                self?.printDebugData()
            case .failure(let error):
                self?.errorMessage = "Failed to delete list: \(error.localizedDescription)"
            }
        }
    }

    // Recursive reassignment of cakenos
    private func reassignCakenos(fromPieIndex pieIndex: Int, targetCakeno: Int) {
        guard pieIndex >= 0 else { return }

        let pies = getPieData()
        guard pieIndex < pies.count, let replacementListIndex = lists.firstIndex(where: { $0.id == pies[pieIndex].first?.id }) else { return }

        // Make a mutable copy of the list
        var replacementList = lists[replacementListIndex]

        // Reassign cakeno
        let nextTargetCakeno = replacementList.cakeno
        replacementList.cakeno = targetCakeno

        // Replace the updated list back in the lists array
        lists[replacementListIndex] = replacementList

        // Recursively reassign for the next oldest pie
        reassignCakenos(fromPieIndex: pieIndex - 1, targetCakeno: nextTargetCakeno)
    }
    
    private func updateCurrentPieIndex() {
        currentPieIndex = (lists.count - 1) / maxListsPerPie
    }
    
    func permanentlyDeleteList(list: ListModel) {
        // Remove the list from the recentlyDeletedLists array
        recentlyDeletedLists.removeAll { $0.id == list.id }

        // Optionally delete the list from persistent storage
        databaseService.deleteList(list, permanently: true) { [weak self] result in
            switch result {
            case .success:
                print("List permanently deleted: \(list.title)")
            case .failure(let error):
                self?.errorMessage = "Failed to permanently delete list: \(error.localizedDescription)"
            }
        }
    }
    
    func getListIndex(in pieIndex: Int, sliceIndex: Int) -> Int? {
        let overallIndex = pieIndex * maxListsPerPie + sliceIndex
        return overallIndex < lists.count ? overallIndex : nil
    }
    
    func updateList(id: UUID, newTitle: String, newItems: [ListModel.ListItem]) {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            errorMessage = "List not found."
            return
        }

        lists[index].title = newTitle
        lists[index].items = newItems

        databaseService.updateList(lists[index]) { [weak self] result in
            switch result {
            case .success:
                self?.objectWillChange.send()
                self?.printDebugData()
            case .failure(let error):
                self?.errorMessage = "Failed to update list: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Restore List
    func restoreList(list: ListModel) {
        var restoredList = list
        restoredList.isDeleted = false

        assignImage(to: &restoredList)

        databaseService.restoreList(restoredList) { [weak self] result in
            switch result {
            case .success:
                self?.recentlyDeletedLists.removeAll { $0.id == restoredList.id }
                self?.lists.append(restoredList)
                self?.updateCurrentPieIndex()
                self?.updatePieSlices()
                self?.printDebugData()
            case .failure(let error):
                self?.errorMessage = "Failed to restore list: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Image Management
    func assignImage(to list: inout ListModel) {
        let pies = getPieData()

        if let lastPie = pies.last, !lastPie.isEmpty && lastPie.count < maxListsPerPie {
            let usedCakenos = lastPie.map { $0.cakeno }
            for cakeno in 1...maxListsPerPie {
                if !usedCakenos.contains(cakeno) {
                    list.cakeno = cakeno
                    return
                }
            }
        } else {
            list.cakeno = 1 // New pie
        }
    }

    // MARK: - Pie Data Management
    func getPieData() -> [[ListModel]] {
        return stride(from: 0, to: lists.count, by: maxListsPerPie).map { startIndex in
            let endIndex = min(startIndex + maxListsPerPie, lists.count)
            return Array(lists[startIndex..<endIndex])
        }
    }
    
    func getRecentlyDeletedPieData() -> [[ListModel]] {
        return stride(from: 0, to: recentlyDeletedLists.count, by: maxListsPerPie).map { startIndex in
            let endIndex = min(startIndex + maxListsPerPie, recentlyDeletedLists.count)
            return Array(recentlyDeletedLists[startIndex..<endIndex])
        }
    }

    // MARK: - Trigger View Updates
    func updatePieSlices() {
        objectWillChange.send()
    }

    // MARK: - Debugging Helper
    private func printDebugData() {
        print("Active Lists: \(lists.map { $0.title })")
        print("Recently Deleted Lists: \(recentlyDeletedLists.map { $0.title })")
    }
    func getPieSliceData(for lists: [ListModel]) -> [PieSliceData] {
        guard !lists.isEmpty else { return [] } // Avoid division by zero

        let total = lists.count
        return lists.enumerated().map { index, list in
            let startAngle = Angle(degrees: Double(index) / Double(total) * 360.0)
            let endAngle = Angle(degrees: Double(index + 1) / Double(total) * 360.0)
            return PieSliceData(startAngle: startAngle, endAngle: endAngle, label: list.title)
        }
    }
}

// MARK: - HomeViewModel Image Management
extension HomeViewModel {
    func getImage(for list: ListModel) -> Image {
        guard (1...maxListsPerPie).contains(list.cakeno) else {
            fatalError("Invalid cakeno: \(list.cakeno).")
        }
        return Image("cake\(list.cakeno)")
    }
}

// MARK: - PieSlice and PieSliceData
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct PieSliceData {
    var startAngle: Angle
    var endAngle: Angle
    var label: String
}
