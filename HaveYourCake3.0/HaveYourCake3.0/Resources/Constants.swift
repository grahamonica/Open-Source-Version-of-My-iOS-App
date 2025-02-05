//
//  Constants.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//

import Foundation
import SwiftUI

struct Constants {
    // MARK: - App Metadata
    static let appName = "HaveYourCake3.0"
    static let version = "1.0.0"

    // MARK: - Colors
    struct Colors {
        // Added Colors
        static let mainBackground = Color(hex: "f3f0ec")
        static let mainText = Color(hex: "5e3f24")
        static let popupBackground = Color(hex: "f7f6f5")
        static let popupText = Color(hex: "231504")
        static let mainButtonColor = Color(hex: "85A1CE")
        static let popupButtonColor = Color(hex: "90C2E2")
        static let mainButtonTextColor = Color(hex: "EDE7E4")
        static let popupButtonColorText = Color(hex: "EDE7E4")
        static let enterTextFieldBackground = Color(hex: "eef2f9")
        static let textFieldDefaultText = Color(hex: "351D0A")
        static let accentColor = Color(hex: "F7C7BD")
        static let errorColor = Color(hex: "f1d9d0")
        static let separatorColor = Color(hex: "bbb39e")
        static let icingRectangleColor = Color(hex: "d4c3a7")
    }

    // MARK: - Firebase Keys
    struct FirebaseKeys {
        static let userCollection = "users"
        static let listCollection = "lists"
    }

    // MARK: - Layout Dimensions
    struct Layout {
        static let cornerRadius: CGFloat = 8.0
        static let buttonHeight: CGFloat = 50.0
        static let padding: CGFloat = 16.0
        static let spacing: CGFloat = 10.0
    }

    // MARK: - Placeholder Texts
    struct Placeholders {
        static let username = "Enter your username"
        static let email = "Enter your email"
        static let password = "Enter your password"
        static let listTitle = "List title"
        static let listItem = "Add a new item"
    }

    // MARK: - Error Messages
    struct Errors {
        static let genericError = "Something went wrong. Please try again."
        static let emptyFieldsError = "Please fill in all required fields."
    }

    // MARK: - Icons
    struct Icons {
        static let backButton = "chevron.left"
        static let deleteButton = "trash"
        static let addButton = "plus"
        static let shareButton = "square.and.arrow.up"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)

        // Remove the hash if it exists
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
