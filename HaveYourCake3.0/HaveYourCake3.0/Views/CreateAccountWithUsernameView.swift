//
//  CreateAccountWithUsernameView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI

struct CreateAccountWithUsernameView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Input Fields
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Error Message
    @State private var errorMessage: String? = nil
    @State private var showWarning: Bool = false
    
    // Navigation
    @Binding var navigateToHome: Bool
    var birthDate: Date // Birthdate passed from CreateAccountView
    
    var body: some View {
        VStack(spacing: 30) {
            // Back Button and Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .shadow(color: .black, radius: 0.4, x: 0, y: 0)
                    }
                    .foregroundColor(Constants.Colors.mainButtonColor)
                }
                Spacer()
            }
            .padding(.top, Constants.Layout.padding)
            
            // Header
            Text("Create Account")
                .font(.custom("Palatino", size: 32).weight(.bold))
                .foregroundColor(Constants.Colors.mainText)
                .multilineTextAlignment(.center)
            
            // Input Fields
            VStack(spacing: 15) {
                CustomTextField(placeholder: "Username", text: $username).shadow(color: .black, radius: 1, x: 0, y: 0)
                CustomSecureField(placeholder: "Password", text: $password).shadow(color: .black, radius: 1, x: 0, y: 0)
                CustomSecureField(placeholder: "Re-enter Password", text: $confirmPassword).shadow(color: .black, radius: 1, x: 0, y: 0)
                CustomTextField(placeholder: "Email (optional)", text: $email, keyboardType: .emailAddress).shadow(color: .black, radius: 1, x: 0, y: 0)
                CustomTextField(placeholder: "Phone Number (optional)", text: $phoneNumber, keyboardType: .phonePad).shadow(color: .black, radius: 1, x: 0, y: 0)
            }
            .padding(.horizontal, Constants.Layout.padding)
            
            // Warning Message for Password Recovery
            if showWarning {
                Text("Warning: Without email or phone, you won't be able to reset your password.")
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(Constants.Colors.errorColor)
            }
            
            // Create Account Button
            Button(action: {
                validateAndRegister()
            }) {
                Text("Create Account")
                    .font(.custom("Palatino", size: 20).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.mainButtonColor)
                    .foregroundColor(Constants.Colors.mainButtonTextColor)
                    .cornerRadius(Constants.Layout.cornerRadius)
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .background(Constants.Colors.mainBackground)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
    
    // MARK: - Validation and Registration
    private func validateAndRegister() {
        // Input Validation
        guard !username.isEmpty else {
            errorMessage = "Username is required."
            return
        }
        
        guard !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Password and confirmation are required."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        // Warn user if both email and phone are empty
        if email.isEmpty && phoneNumber.isEmpty {
            showWarning = true
        } else {
            showWarning = false
        }
        
        // Firebase Registration
        FirebaseAuthService.shared.signUpWithUsername(
            username: username,
            email: email.isEmpty ? nil : email,
            password: password,
            birthDate: birthDate
        ) { result in
            switch result {
            case .success:
                print("User signed up successfully.")
                errorMessage = nil
                navigateToHome = true
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                errorMessage = "Error signing up: \(error.localizedDescription)"
                print(errorMessage ?? "Unknown error")
            }
        }
    }
}

// MARK: - Custom Components for Input Fields
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .font(.custom("Palatino", size: 18))
            .padding()
            .background(Constants.Colors.enterTextFieldBackground)
            .cornerRadius(Constants.Layout.cornerRadius)
            .foregroundColor(Constants.Colors.textFieldDefaultText)
    }
}

struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .font(.custom("Palatino", size: 18))
            .padding()
            .background(Constants.Colors.enterTextFieldBackground)
            .cornerRadius(Constants.Layout.cornerRadius)
            .foregroundColor(Constants.Colors.textFieldDefaultText)
    }
}
