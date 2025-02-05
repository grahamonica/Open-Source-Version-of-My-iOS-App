//
//  UserModel.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import Foundation

struct UserModel: Codable, Identifiable {
    var id: UUID
    var firstName: String?
    var lastName: String?
    var email: String?
    var phoneNumber: String?
    var creationDate: Date
    var birthDate: Date?
    var isGuest: Bool
    var listIDs: [UUID] // Array of list IDs associated with the user
    var notifications: Bool // Field for push notifications preference

    init(
        id: UUID = UUID(),
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        birthDate: Date? = nil,
        phoneNumber: String? = nil,
        creationDate: Date = Date(),
        isGuest: Bool = true,
        listIDs: [UUID] = [],
        notifications: Bool = true // Default to true
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.creationDate = creationDate
        self.birthDate = birthDate
        self.isGuest = isGuest
        self.listIDs = listIDs
        self.notifications = notifications
    }

    // Computed Property: Full Name
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else {
            return "Guest User"
        }
    }
}
