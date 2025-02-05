//
//  NewListPopup.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI

struct NewListPopup: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: HomeViewModel // Dependency injection of the ViewModel

    @State private var listTitle: String = ""
    @State private var listItems: [String] = [""]
    @FocusState private var focusedField: FocusableField? // Focus state for fields

    // MARK: - Enum for Focused Fields
    enum FocusableField: Hashable {
        case title
        case item(Int)
    }

    // MARK: - Body
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    dismissKeyboard()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()

                Button(action: addNewList) {
                    Text("Add")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                        .padding()
                }
            }

            // Title Input
            TextField("List Title (Icing)", text: $listTitle)
                .focused($focusedField, equals: .title) // Focus binding
                .keyboardType(.default)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            // Items Input
            ScrollView {
                ForEach(listItems.indices, id: \.self) { index in
                    HStack {
                        TextField("Item \(index + 1)", text: $listItems[index])
                            .focused($focusedField, equals: .item(index)) // Focus binding
                            .keyboardType(.default)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)

                        // Delete Button
                        if listItems.count > 1 {
                            Button(action: {
                                removeItem(at: index)
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Add New Item Button
            Button(action: {
                listItems.append("")
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                    Text("Add Item")
                        .foregroundColor(.green)
                }
                .padding()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.white // Background to detect taps outside input fields
                .onTapGesture {
                    dismissKeyboard()
                }
        )
        .padding()
    }

    // MARK: - Functions
    private func addNewList() {
        dismissKeyboard()
        viewModel.addList(title: listTitle, items: listItems)
        presentationMode.wrappedValue.dismiss()
    }

    private func removeItem(at index: Int) {
        listItems.remove(at: index)
    }

    private func dismissKeyboard() {
        focusedField = nil
    }
}
