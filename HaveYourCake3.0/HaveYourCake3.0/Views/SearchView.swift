import SwiftUI
import UIKit

// MARK: - SearchBar
struct SearchBar: UIViewRepresentable {
    @Binding var query: String
    var allLists: [ListModel]
    var onListSelected: (ListModel) -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var query: String
        var allLists: [ListModel]
        var onListSelected: (ListModel) -> Void

        init(query: Binding<String>, allLists: [ListModel], onListSelected: @escaping (ListModel) -> Void) {
            _query = query
            self.allLists = allLists
            self.onListSelected = onListSelected
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            query = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            query = ""
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(query: $query, allLists: allLists, onListSelected: onListSelected)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        searchBar.placeholder = "Search Lists"
        searchBar.searchTextField.font = UIFont(name: "Palatino", size: 16)
        searchBar.backgroundImage = UIImage() // Removes borders
        searchBar.layer.masksToBounds = false
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowOpacity = 0.1
        searchBar.layer.shadowRadius = 4

        if #available(iOS 13.0, *) {
            let searchTextField = searchBar.searchTextField
            searchTextField.backgroundColor = UIColor(Constants.Colors.enterTextFieldBackground)
            searchTextField.layer.cornerRadius = searchTextField.frame.height
            searchTextField.clipsToBounds = false
            searchTextField.textColor = UIColor(Constants.Colors.mainText)
            
            // Use the system-provided search icon on the right
            searchTextField.rightView = nil // Remove default rightView
            searchTextField.leftViewMode = .never // Remove left magnifying glass
            searchTextField.rightViewMode = .always // Add right magnifying glass
        }

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = query
    }
}

// MARK: - SearchResultsOverlay
struct SearchResultsOverlay: View {
    @Binding var query: String
    var allLists: [ListModel]
    var onListSelected: (ListModel) -> Void
    @Environment(\.presentationMode) var presentationMode // Used to return to HomeView

    var filteredLists: [SearchResult] {
        guard !query.isEmpty else { return [] }
        return allLists.flatMap { list -> [SearchResult] in
            let titleMatch = list.title.localizedCaseInsensitiveContains(query) ? [SearchResult(list: list, matchedText: list.title)] : []
            let itemMatches = list.items.compactMap { item in
                item.name.localizedCaseInsensitiveContains(query) ? SearchResult(list: list, matchedText: item.name) : nil
            }
            return titleMatch + itemMatches
        }
    }

    var body: some View {
        ZStack {
            // Background to detect taps outside the popup
            if !query.isEmpty {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        query = ""
                        presentationMode.wrappedValue.dismiss()
                    }
            }

            // Popup
            if !query.isEmpty {
                VStack {
                    Spacer()

                    VStack {
                        if filteredLists.isEmpty {
                            noResultsView
                        } else {
                            resultsListView
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                    .background(Constants.Colors.popupBackground)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
        }
    }

    private var noResultsView: some View {
        Text("No results found")
            .font(Font.custom("Palatino", size: 16))
            .foregroundColor(Constants.Colors.popupText)
            .padding()
    }

    private var resultsListView: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(filteredLists, id: \.id) { result in
                    searchResultButton(for: result)
                }
            }
            .padding()
        }
    }

    private func searchResultButton(for result: SearchResult) -> some View {
        Button(action: {
            onListSelected(result.list)
            query = ""
        }) {
            HStack {
                Image("cupcake") // Cupcake icon on the left
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.list.title)
                        .font(Font.custom("Palatino", size: 16).weight(.bold))
                        .foregroundColor(Constants.Colors.mainText)

                    if let highlightedText = highlightedMatchedText(for: result.matchedText, query: query) {
                        Text(highlightedText)
                            .font(Font.custom("Palatino", size: 14))
                            .foregroundColor(Constants.Colors.mainText)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Constants.Colors.popupBackground)
            .cornerRadius(8)
            .shadow(color: Constants.Colors.accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
        }
        .padding(.horizontal)
    }

    private func highlightedMatchedText(for text: String?, query: String) -> AttributedString? {
        guard let text = text else { return nil }
        var attributedString = AttributedString(text)
        if let range = text.range(of: query, options: .caseInsensitive) {
            let swiftRange = NSRange(range, in: text)
            if let attributedRange = Range(swiftRange, in: attributedString) {
                attributedString[attributedRange].font = .boldSystemFont(ofSize: 14)
            }
        }
        return attributedString
    }
}

// MARK: - SearchResult Struct
struct SearchResult: Identifiable {
    let list: ListModel
    var matchedText: String?
    var id: UUID { list.id }
}
