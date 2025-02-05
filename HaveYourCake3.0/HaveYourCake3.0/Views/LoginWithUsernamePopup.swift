//
//  LoginWithUsernamePopup.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI

struct LoginWithUsernamePopup: View {
    @Environment(\.presentationMode) var presentationMode

    // Input Fields
    @State private var username: String = "" // Username as primary input
    @State private var password: String = ""

    // Error Message
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil // For reset password feedback

    // Navigation
    @Binding var navigateToHome: Bool

    var body: some View {
        VStack(spacing: 30) { // Adjusted spacing for aesthetics
            // Back Button and Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .shadow(color: .black, radius: 0.4, x: 0, y: 0)
                        .foregroundColor(Constants.Colors.mainButtonColor)
                }
                Spacer()
            }
            .padding(.top, Constants.Layout.padding)

            // Header
            Text("Sign in")
                .font(.custom("Palatino", size: 32).weight(.bold))
                .foregroundColor(Constants.Colors.mainText)
                .multilineTextAlignment(.center)

            // Input Fields
            VStack(spacing: 15) {
                CustomTextField(placeholder: "Username", text: $username)
                CustomSecureField(placeholder: "Password", text: $password)
            }
            .padding(.horizontal, Constants.Layout.padding)

            // Error and Success Messages
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(Constants.Colors.popupBackground)
            }
            if let successMessage = successMessage {
                Text(successMessage)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.green)
            }

            // Login Button
            Button(action: {
                loginWithUsername()
            }) {
                Text("Sign in")
                    .font(.custom("Palatino", size: 20).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.mainButtonColor)
                    .foregroundColor(Constants.Colors.mainButtonTextColor)
                    .cornerRadius(Constants.Layout.cornerRadius)
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 10)

            // Reset Password Button
            Button(action: {
                resetPassword()
            }) {
                Text("Forgot Password?")
                    .font(.custom("Palatino", size: 16).weight(.medium))
                    .foregroundColor(Constants.Colors.mainText)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .background(Constants.Colors.mainBackground)
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    // MARK: - Login Method
    private func loginWithUsername() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        FirebaseAuthService.shared.loginWithUsername(email: username, password: password) { result in
            switch result {
            case .success:
                errorMessage = nil
                navigateToHome = true
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                errorMessage = "Error logging in: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Reset Password Method
    private func resetPassword() {
        guard !username.isEmpty else {
            errorMessage = "Please provide your username."
            return
        }

        FirebaseAuthService.shared.resetPassword(forUsername: username) { result in
            switch result {
            case .success:
                successMessage = "Password reset instructions sent."
                errorMessage = nil
            case .failure(let error):
                successMessage = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
