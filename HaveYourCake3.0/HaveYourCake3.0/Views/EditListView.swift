//
//  EditListView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//

import SwiftUI

struct EditListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel
    @State private var listTitle: String
    @State private var listItems: [ListModel.ListItem]

    var list: ListModel

    init(viewModel: HomeViewModel, list: ListModel) {
        self.viewModel = viewModel
        self._listTitle = State(initialValue: list.title)
        self._listItems = State(initialValue: list.items.filter { !$0.name.isEmpty })
        self.list = list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CakeListView(listTitle: $listTitle, listItems: $listItems) // Embedding CakeListView
                // Navigation buttons
                HStack {
                    Button(action: dismissView) {
                        Text("Cancel")
                            .font(.custom("Palatino", size: 18).weight(.bold))
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()

                    Button(action: saveChanges) {
                        Text("Update")
                            .font(.custom("Palatino", size: 18).weight(.bold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .background(Constants.Colors.mainBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Functions
    private func saveChanges() {
        let filteredItems = listItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        viewModel.updateList(id: list.id, newTitle: listTitle, newItems: filteredItems)
        dismiss()
    }

    private func dismissView() {
        dismiss()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    let sampleList = ListModel(id: UUID(), title: "Sample List", cakeno: 4, items: [
        ListModel.ListItem(name: "Milk"),
        ListModel.ListItem(name: "Eggs"),
        ListModel.ListItem(name: "Butter")
    ])

    let sampleViewModel = HomeViewModel()

    EditListView(viewModel: sampleViewModel, list: sampleList)
}
