//
//  SettingsViewModel.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

class SettingsViewModel: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var notificationsEnabled: Bool = true
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var birthDate: Date? = nil
    @Published var isGuestUser: Bool = false // Flag to determine if the user is a guest

    private let db = Firestore.firestore()
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        checkIfGuestUser()
        fetchUserDetails()
    }

    // MARK: - Check if User is Guest
    private func checkIfGuestUser() {
        if let user = Auth.auth().currentUser {
            isGuestUser = user.isAnonymous
        } else {
            isGuestUser = false
        }
    }

    // MARK: - Fetch User Details
    func fetchUserDetails() {
        guard let userID = userID else {
            errorMessage = "User not logged in."
            return
        }

        db.collection("users").document(userID).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = "Failed to fetch user details: \(error.localizedDescription)"
                return
            }

            guard let data = document?.data() else {
                self?.errorMessage = "No user data found."
                return
            }

            self?.notificationsEnabled = data["notifications"] as? Bool ?? true
            self?.firstName = data["firstName"] as? String ?? ""
            self?.lastName = data["lastName"] as? String ?? ""
            self?.email = data["email"] as? String ?? ""
            if let timestamp = data["birthDate"] as? Timestamp {
                self?.birthDate = timestamp.dateValue()
            }
        }
    }

    // MARK: - Save User Preferences
    func saveUserPreferences() {
        guard let userID = userID else {
            errorMessage = "User not logged in."
            return
        }

        let data: [String: Any] = [
            "notifications": notificationsEnabled,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "birthDate": birthDate ?? FieldValue.delete()
        ]

        db.collection("users").document(userID).setData(data, merge: true) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to save user preferences: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Logout
    func logOut(completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseAuthService.shared.logOut { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    // MARK: - Delete Account
    func deleteAccount(password: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in."])
            completion(.failure(error))
            return
        }

        if isGuestUser {
            firebaseUser.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else if let password = password {
            reauthenticateUser(firebaseUser: firebaseUser, password: password) { success in
                if success {
                    firebaseUser.delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    let error = NSError(domain: "FirebaseAuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Reauthentication failed."])
                    completion(.failure(error))
                }
            }
        } else {
            let error = NSError(domain: "FirebaseAuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Password is required for account deletion."])
            completion(.failure(error))
        }
    }

    // MARK: - Toggle Notifications
    func toggleNotifications(isEnabled: Bool) {
        notificationsEnabled = isEnabled
        saveUserPreferences()
    }

    // MARK: - Reauthenticate User
    private func reauthenticateUser(firebaseUser: User, password: String, completion: @escaping (Bool) -> Void) {
        guard let email = firebaseUser.email else {
            completion(false)
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        firebaseUser.reauthenticate(with: credential) { _, error in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func reauthenticate(password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in."])))
            return
        }

        guard let email = firebaseUser.email else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Email not available."])))
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        firebaseUser.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
