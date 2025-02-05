//
//  RecentlyDeletedView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI

struct RecentlyDeletedView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showMenu = false
    @State private var selectedList: ListModel? // For popup with restore and delete options
    @State private var showRestorePopup = false // For short-tap preview popup
    @State private var showDeleteConfirmation = false // For long-tap confirmation popup

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main Background
            Constants.Colors.mainBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with Menu and Title
                headerView

                Spacer()

                // Content: Empty State or Pie Charts
                if viewModel.recentlyDeletedLists.isEmpty {
                    emptyStateView
                    Spacer()
                } else {
                    pieChartsView
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // Menu Overlay
            if showMenu {
                MenuView(isOpen: $showMenu, homeViewModel: viewModel, settingsViewModel: SettingsViewModel())

                    .zIndex(2)
            }

            // Restore Popup
            if showRestorePopup, let selectedList = selectedList {
                restorePopup(for: selectedList)
            }

            // Delete Confirmation Popup
            if showDeleteConfirmation, let selectedList = selectedList {
                deleteConfirmationPopup(for: selectedList)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Hamburger Menu Button
            Button(action: {
                showMenu.toggle()
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(Constants.Colors.mainButtonColor)
                    .padding(.leading, 16)
            }

            Spacer()

            // Title
            Text("Recently Deleted")
                .font(.custom("Palatino", size: 28).weight(.bold))
                .foregroundColor(Constants.Colors.mainText)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        Image("deleteplate")
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300)
            .padding(.horizontal, 10)
            .padding(.top, 20)
    }

    // MARK: - Pie Charts View
    private var pieChartsView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    ForEach(viewModel.getRecentlyDeletedPieData(), id: \.self) { pieData in
                        let slices = viewModel.getPieSliceData(for: pieData)
                        let images = pieData
                            .filter { $0.cakeno > 0 && $0.cakeno <= viewModel.maxListsPerPie }
                            .map { viewModel.getImage(for: $0) }

                        PieChartView(
                            slices: slices,
                            images: images,
                            onSliceTapped: { sliceIndex in
                                handleSliceTapped(
                                    pieIndex: viewModel.getRecentlyDeletedPieData().firstIndex(of: pieData) ?? 0,
                                    sliceIndex: sliceIndex
                                )
                            },
                            onSliceLongPressed: { sliceIndex in
                                handleSliceLongPressed(
                                    pieIndex: viewModel.getRecentlyDeletedPieData().firstIndex(of: pieData) ?? 0,
                                    sliceIndex: sliceIndex
                                )
                            }
                        )
                        .frame(width: 300, height: 300)
                        .padding(.horizontal, 10)
                        .padding(.top, 20)
                        .id(viewModel.getRecentlyDeletedPieData().firstIndex(of: pieData) ?? 0)
                    }
                }
            }
            .onAppear {
                withAnimation {
                    if viewModel.currentPieIndex >= 0 {
                        proxy.scrollTo(viewModel.currentPieIndex, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Restore Popup
    private func restorePopup(for list: ListModel) -> some View {
        VStack {
            Text("\(list.title)")
                .font(.headline)
                .padding()

            HStack {
                // Permanently Delete Button
                Button(action: {
                    viewModel.permanentlyDeleteList(list: list)
                    showRestorePopup = false
                }) {
                    Text("Delete")
                        .padding()
                        .background(Constants.Colors.popupButtonColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // Cancel Button
                Button(action: {
                    showRestorePopup = false
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Constants.Colors.popupButtonColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // Restore Button
                Button(action: {
                    viewModel.restoreList(list: list)
                    showRestorePopup = false
                }) {
                    Text("Restore")
                        .padding()
                        .background(Constants.Colors.popupButtonColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(width: 300, height: 200)
        .background(Constants.Colors.popupBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
    }

    // MARK: - Delete Confirmation Popup
    private func deleteConfirmationPopup(for list: ListModel) -> some View {
        VStack {
            Text("Are you sure you want to delete \(list.title)?")
                .font(.headline)
                .padding()

            HStack {
                // Permanently Delete Button
                Button(action: {
                    viewModel.permanentlyDeleteList(list: list)
                    showDeleteConfirmation = false
                }) {
                    Text("Delete")
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // Cancel Button
                Button(action: {
                    showDeleteConfirmation = false
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // Restore Button
                Button(action: {
                    viewModel.restoreList(list: list)
                    showDeleteConfirmation = false
                }) {
                    Text("Restore")
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(width: 300, height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }

    // MARK: - Handle Slice Tapped
    private func handleSliceTapped(pieIndex: Int, sliceIndex: Int) {
        let overallIndex = pieIndex * viewModel.maxListsPerPie + sliceIndex
        if overallIndex < viewModel.recentlyDeletedLists.count {
            selectedList = viewModel.recentlyDeletedLists[overallIndex]
            showRestorePopup = true
        }
    }

    // MARK: - Handle Slice Long Pressed
    private func handleSliceLongPressed(pieIndex: Int, sliceIndex: Int) {
        let overallIndex = pieIndex * viewModel.maxListsPerPie + sliceIndex
        if overallIndex < viewModel.recentlyDeletedLists.count {
            selectedList = viewModel.recentlyDeletedLists[overallIndex]
            showDeleteConfirmation = true
        }
    }
}
