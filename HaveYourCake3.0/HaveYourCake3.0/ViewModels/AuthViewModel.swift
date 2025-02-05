//
//  AuthViewModel.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import Foundation
import FirebaseAuth
import AuthenticationServices
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserModel? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Login with Username
    func loginWithUsername(email: String?, password: String?) {
        guard let email = email, let password = password, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Username (email) and password cannot be empty."
            print("AuthViewModel: Username or password is empty.")
            return
        }

        print("AuthViewModel: Attempting to log in with username.")
        FirebaseAuthService.shared.loginWithUsername(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let user):
                self?.currentUser = self?.mapFirebaseUserToModel(user: user)
                self?.isAuthenticated = true
                self?.errorMessage = nil
                print("AuthViewModel: Login successful for user \(user.uid).")
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                print("AuthViewModel: Login failed - \(error.localizedDescription).")
            }
        }
    }

    // MARK: - Login with Google
    func loginWithGoogle(presentingViewController: UIViewController) {
        print("AuthViewModel: Attempting to log in with Google.")
        FirebaseAuthService.shared.loginWithGoogle(presentingViewController: presentingViewController) { [weak self] result in
            switch result {
            case .success(let user):
                self?.currentUser = self?.mapFirebaseUserToModel(user: user)
                self?.isAuthenticated = true
                self?.errorMessage = nil
                print("AuthViewModel: Google login successful for user \(user.uid).")
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                print("AuthViewModel: Google login failed - \(error.localizedDescription).")
            }
        }
    }

    // MARK: - Login with Apple
    func loginWithApple(authorization: ASAuthorization, nonce: String) {
        print("AuthViewModel: Attempting to log in with Apple.")
        FirebaseAuthService.shared.loginWithApple(authorization: authorization, nonce: nonce) { [weak self] result in
            switch result {
            case .success(let user):
                self?.currentUser = self?.mapFirebaseUserToModel(user: user)
                self?.isAuthenticated = true
                self?.errorMessage = nil
                print("AuthViewModel: Apple login successful for user \(user.uid).")
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                print("AuthViewModel: Apple login failed - \(error.localizedDescription).")
            }
        }
    }

    // MARK: - Login as Guest
    func loginAsGuest() {
        print("AuthViewModel: Attempting to log in as guest.")
        FirebaseAuthService.shared.loginAsGuest { [weak self] result in
            switch result {
            case .success(let user):
                self?.currentUser = self?.mapFirebaseUserToModel(user: user)
                self?.isAuthenticated = true
                self?.errorMessage = nil
                print("AuthViewModel: Guest login successful for user \(user.uid).")
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                print("AuthViewModel: Guest login failed - \(error.localizedDescription).")
            }
        }
    }

    // MARK: - Logout
    func logout() {
        print("AuthViewModel: Attempting to log out.")
        FirebaseAuthService.shared.logOut { [weak self] result in
            switch result {
            case .success:
                self?.currentUser = nil
                self?.isAuthenticated = false
                self?.errorMessage = nil
                print("AuthViewModel: Logout successful.")
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                print("AuthViewModel: Logout failed - \(error.localizedDescription).")
            }
        }
    }

    // MARK: - Helper to Map Firebase User to UserModel
    private func mapFirebaseUserToModel(user: User) -> UserModel {
        return UserModel(
            firstName: user.displayName,
            email: user.email,
            isGuest: user.isAnonymous
        )
    }
}
