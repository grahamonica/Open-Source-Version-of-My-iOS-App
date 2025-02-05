//
//  ContentView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore

struct ContentView: View {
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationView {
            if navigateToHome {
                HomeView()
                    .onAppear {
                        print("Navigated to HomeView.")
                    }
            } else {
                MainLoginView(navigateToHome: $navigateToHome)
                    .onAppear {
                        print("Navigated to MainLoginView.")
                    }
            }
        }
        .onAppear {
            checkFirebaseInitialization()
            checkIfUserIsLoggedIn()
        }
    }

    // MARK: - Check Firebase Initialization
    private func checkFirebaseInitialization() {
        if FirebaseApp.app() == nil {
            print("FirebaseApp is NOT initialized!")
        } else {
            print("FirebaseApp is initialized successfully.")
        }
    }

    // MARK: - Check User Login State
    private func checkIfUserIsLoggedIn() {
        if let currentUser = Auth.auth().currentUser {
            if currentUser.isAnonymous {
                print("Guest user found. Navigate to HomeView.")
            } else {
                print("Authenticated user found: \(currentUser.email ?? "No email"). Navigate to HomeView.")
            }
            navigateToHome = true
        } else {
            print("No logged-in user. Stay on MainLoginView.")
            navigateToHome = false
        }
    }
}
