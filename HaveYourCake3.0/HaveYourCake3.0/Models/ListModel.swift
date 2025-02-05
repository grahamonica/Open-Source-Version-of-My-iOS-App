
//
//  ListModel.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import Foundation

struct ListModel: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var cakeno: Int // Corresponds to the assigned cake image number
    var items: [ListItem] // Array of list items
    var creationDate: Date
    var recentDeletedDate: Date?
    var isDeleted: Bool
    var ownerID: String? // Reference to the owner's UID (FirebaseAuth user ID)

    init(id: UUID = UUID(), title: String, cakeno: Int, items: [ListItem] = [], creationDate: Date = Date(), isDeleted: Bool = false, ownerID: String? = nil) {
        self.id = id
        self.title = title
        self.cakeno = cakeno
        self.items = items
        self.creationDate = creationDate
        self.isDeleted = isDeleted
        self.ownerID = ownerID
    }

    // Conformance to `Hashable`
    static func == (lhs: ListModel, rhs: ListModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Embedded ListItem Model
    struct ListItem: Codable, Identifiable, Hashable {
        var id: UUID
        var name: String
        //var isCompleted: Bool = false

        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
            //self.isCompleted = isCompleted
        }
    }
}
