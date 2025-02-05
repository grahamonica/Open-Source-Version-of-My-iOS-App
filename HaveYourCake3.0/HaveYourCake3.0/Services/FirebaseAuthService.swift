
//
//  FirebaseAuthService.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import FirebaseFirestore

class FirebaseAuthService {
    static let shared = FirebaseAuthService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Log In with Google
    func loginWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("FirebaseAuthService: Missing Client ID for Google Sign-In.")
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing Client ID."])))
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                print("FirebaseAuthService: Google Sign-In Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("FirebaseAuthService: Failed to retrieve Google user or token.")
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Google user or token."])))
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("FirebaseAuthService: Firebase Google Sign-In Error: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let firebaseUser = authResult?.user {
                    print("FirebaseAuthService: Successfully signed in with Google: \(firebaseUser.uid)")
                    completion(.success(firebaseUser))
                } else {
                    print("FirebaseAuthService: Unknown error during Google authentication.")
                    completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during Google authentication."])))
                }
            }
        }
    }
    
    func loginWithApple(authorization: ASAuthorization, nonce: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            let error = NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve Apple credentials."])
            completion(.failure(error))
            return
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                print("FirebaseAuthService: Successfully authenticated with Apple: \(user.uid)")
                completion(.success(user))
            } else {
                let unknownError = NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during Apple authentication."])
                completion(.failure(unknownError))
            }
        }
    }

    // MARK: - Sign Up with Username
    func signUpWithUsername(username: String, email: String?, password: String?, birthDate: Date, completion: @escaping (Result<User, Error>) -> Void) {
        if let email = email, let password = password {
            // Sign up with email and password
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    print("FirebaseAuthService: Sign-Up with Email Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create user."])))
                    return
                }
                self?.saveUserData(userID: user.uid, username: username, email: email, birthDate: birthDate, isGuest: false, completion: completion)
            }
        } else {
            // Anonymous sign-up
            Auth.auth().signInAnonymously { [weak self] result, error in
                if let error = error {
                    print("FirebaseAuthService: Anonymous Sign-Up Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create anonymous user."])))
                    return
                }
                self?.saveUserData(userID: user.uid, username: username, email: nil, birthDate: birthDate, isGuest: true, completion: completion)
            }
        }
    }

    // MARK: - Save User Data
    private func saveUserData(userID: String, username: String, email: String?, birthDate: Date, isGuest: Bool, completion: @escaping (Result<User, Error>) -> Void) {
        let userData: [String: Any] = [
            "username": username,
            "email": email ?? FieldValue.delete(),
            "birthDate": Timestamp(date: birthDate),
            "isGuest": isGuest
        ]

        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("FirebaseAuthService: Failed to save user data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let user = Auth.auth().currentUser {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch current user."])))
            }
        }
    }

    // MARK: - Login with Username
    func loginWithUsername(email: String?, password: String?, completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = email, let password = password else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email and password required for login."])))
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("FirebaseAuthService: Login with Email Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                print("FirebaseAuthService: Successfully logged in with Username.")
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during login."])))
            }
        }
    }

    // MARK: - Log In as Guest
    func loginAsGuest(completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("FirebaseAuthService: Anonymous Login Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                print("FirebaseAuthService: Successfully logged in as Guest.")
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to log in as Guest."])))
            }
        }
    }

    // MARK: - Delete Account
    func deleteAccount(password: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in."])))
            return
        }

        if firebaseUser.isAnonymous {
            firebaseUser.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else if let password = password {
            reauthenticateUser(firebaseUser: firebaseUser, password: password) { success in
                guard success else {
                    completion(.failure(NSError(domain: "FirebaseAuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Reauthentication failed."])))
                    return
                }
                firebaseUser.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // MARK: - Reauthenticate User
    private func reauthenticateUser(firebaseUser: User, password: String, completion: @escaping (Bool) -> Void) {
        guard let email = firebaseUser.email else {
            completion(false)
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        firebaseUser.reauthenticate(with: credential) { _, error in
            completion(error == nil)
        }
    }

    // MARK: - Log Out
    func logOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    func resetPassword(forUsername username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Query Firestore to find user by username
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot?.documents.first else {
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user found with this username."])))
                return
            }
            
            // Extract user data
            let userData = document.data()
            let email = userData["email"] as? String
            let phone = userData["phoneNumber"] as? String
            
            if let email = email, !email.isEmpty {
                // Send password reset email
                Auth.auth().sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(())) // Email reset successful
                    }
                }
            } else if let phone = phone, !phone.isEmpty {
                // Use the stored phone number for SMS verification
                self.sendSMSToPhoneNumber(phone) { result in
                    switch result {
                    case .success:
                        completion(.success(())) // SMS reset successful
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                // No backup options
                completion(.failure(NSError(domain: "FirebaseAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No email or phone associated with this username."])))
            }
        }
    }

    // MARK: - SMS Sending Placeholder
    private func sendSMSToPhoneNumber(_ phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Placeholder for SMS sending logic
        // In production, integrate with a service like Twilio, Nexmo, or Firebase Cloud Functions.
        print("Simulating SMS send to \(phoneNumber).")
        completion(.success(()))
    }
}
