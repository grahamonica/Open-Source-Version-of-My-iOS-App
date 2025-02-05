import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedList: ListModel?
    @State private var showMenu = false
    @State private var showResultsOverlay = false
    @State private var showNewListPopup = false
    @State private var showDeleteConfirmation = false
    @State private var listToDelete: ListModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(Constants.Colors.mainBackground)
                    .ignoresSafeArea()
                    .onTapGesture { dismissKeyboard() }

                VStack(spacing: 20) {
                    headerView
                    Spacer()
                    pieChartsOrAltplateView
                    Spacer()
                    newListButton // Moved inside the VStack
                }

                if showMenu {
                    menuView
                }

                if showResultsOverlay {
                    SearchResultsOverlay(
                        query: $viewModel.searchQuery,
                        allLists: viewModel.lists,
                        onListSelected: { list in
                            selectedList = list
                            showResultsOverlay = false
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: showResultsOverlay)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadDataIfNeeded()
            }
            .sheet(isPresented: $showNewListPopup) {
                NewListPopup(viewModel: viewModel)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                deleteConfirmationAlert
            }
            .navigationDestination(for: ListModel.self) { list in
                EditListView(viewModel: viewModel, list: list)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { showMenu.toggle() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title)
                    .foregroundColor(Constants.Colors.mainButtonColor)
                    .padding()
            }

            SearchBar(
                query: $viewModel.searchQuery,
                allLists: viewModel.lists,
                onListSelected: { list in
                    selectedList = list
                    showResultsOverlay = false
                }
            )
            .onChange(of: viewModel.searchQuery) { query in
                showResultsOverlay = !query.isEmpty
            }
        }
    }

    private var pieChartsOrAltplateView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    if viewModel.lists.isEmpty {
                        Image("altplate")
                            .resizable()
                            .frame(width: 300, height: 300)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.9))
                                    .blur(radius: 5)
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                         } else {
                        ForEach(viewModel.getPieData().indices, id: \.self) { pieIndex in
                            let pieData = viewModel.getPieData()[pieIndex]
                            let slices = viewModel.getPieSliceData(for: pieData)
                            let images = pieData.map { viewModel.getImage(for: $0) }

                            PieChartView(
                                slices: slices,
                                images: images,
                                onSliceTapped: { sliceIndex in
                                    handleSliceTapped(pieIndex: pieIndex, sliceIndex: sliceIndex)
                                },
                                onSliceLongPressed: { sliceIndex in
                                    handleSliceLongPressed(pieIndex: pieIndex, sliceIndex: sliceIndex)
                                }
                            )
                            .frame(width: 300, height: 300)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.8))
                                    .blur(radius: 4)
                            )
                            .padding(.horizontal, 10)
                            .padding(.top, 20)
                            .id(pieIndex)
                        }
                    }
                }
            }
            .onChange(of: viewModel.currentPieIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                withAnimation {
                    proxy.scrollTo(viewModel.currentPieIndex, anchor: .center)
                }
            }
            .overlay(
                NavigationLink(
                    destination: selectedList.map { list in
                        EditListView(viewModel: viewModel, list: list)
                    },
                    isActive: Binding(
                        get: { selectedList != nil },
                        set: { if !$0 { selectedList = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    private var deleteConfirmationAlert: Alert {
        Alert(
            title: Text("Delete List"),
            message: Text("Are you sure you want to delete this list?"),
            primaryButton: .destructive(Text("Delete")) {
                if let listToDelete = listToDelete {
                    viewModel.deleteAndUpdate(list: listToDelete)
                    self.listToDelete = nil
                }
            },
            secondaryButton: .cancel {
                self.listToDelete = nil
            }
        )
    }

    private var newListButton: some View {
        Button(action: { showNewListPopup = true }) {
            Text("Create A New List")
                .font(.custom("Palatino", size:18))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(Constants.Colors.mainButtonColor))
                .cornerRadius(25)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }

    private func handleSliceTapped(pieIndex: Int, sliceIndex: Int) {
        if let listIndex = viewModel.getListIndex(in: pieIndex, sliceIndex: sliceIndex) {
            selectedList = viewModel.lists[listIndex]
        }
    }

    private func handleSliceLongPressed(pieIndex: Int, sliceIndex: Int) {
        if let listIndex = viewModel.getListIndex(in: pieIndex, sliceIndex: sliceIndex) {
            listToDelete = viewModel.lists[listIndex]
            showDeleteConfirmation = true
        }
    }

    private var menuView: some View {
        MenuView(
            isOpen: $showMenu,
            homeViewModel: viewModel,
            settingsViewModel: SettingsViewModel()
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
