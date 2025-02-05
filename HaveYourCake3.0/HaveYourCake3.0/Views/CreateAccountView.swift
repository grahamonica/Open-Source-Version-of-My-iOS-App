//  CreateAccountView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct CreateAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToCreateWithUsername = false
    @State private var errorMessage: String? = nil
    @Binding var navigateToHome: Bool
    @State private var currentNonce: String?
    @State private var birthDate: Date = Date() // Birthdate state
    @State private var showAgeError: Bool = false // Age error state

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header: Back Button and Title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Constants.Colors.mainButtonColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, Constants.Layout.padding)

                // Top Part: Step 1 - Birthdate Selection
                VStack(spacing: 20) {
                    Text("Step 1: Select Your Birthdate")
                        .font(.custom("Palatino", size: 24).weight(.bold))
                        .foregroundColor(Constants.Colors.mainText)

                    DatePicker("Birthdate", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                        .shadow(radius: 2)
                }
                .padding(.horizontal, Constants.Layout.padding)
                .onChange(of: birthDate) { _ in
                    validateAge()
                }

                Divider()
                    .padding(.horizontal)

                // Bottom Part: Step 2 - Authentication Method
                VStack(spacing: 20) {
                    Text("Step 2: Select Your Authentication Method")
                        .font(.custom("Palatino", size: 24).weight(.bold))
                        .foregroundColor(Constants.Colors.mainText)

                    // Sign up with Username
                    Button(action: {
                        if validateAge() {
                            navigateToCreateWithUsername = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)

                            Text("Sign up with Username")
                                .font(.custom("San Fransisco", size: 20).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                    }

                    // Sign up with Google
                    Button(action: {
                        if validateAge() {
                            signUpWithGoogle()
                        }
                    }) {
                        HStack {
                            Image("google_logo")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)

                            Text("Sign up with Google")
                                .font(.custom("San Fransisco", size: 20).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                    }

                    // Sign up with Apple
                    ZStack {
                        // Apple Sign-In Button
                        SignInWithAppleButton(.signUp) { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                if validateAge(), let nonce = currentNonce {
                                    signUpWithApple(authorization: authorization, nonce: nonce)
                                }
                            case .failure(let error):
                                print("Apple Sign-In failed: \(error.localizedDescription)")
                            }
                        }
                        .frame(height: 55)
                        .signInWithAppleButtonStyle(.black)
                        .cornerRadius(Constants.Layout.cornerRadius)

                        // Invisible overlay for underage restriction
                        if !validateAge() {
                            Color.clear
                                .contentShape(Rectangle()) // Ensure tappable area matches button size
                                .onTapGesture {
                                    showAgeError = true
                                }
                        }
                    }
                    .frame(height: 55) // Fixed height to prevent layout shifts
                }
                .padding(.horizontal, Constants.Layout.padding)

                Spacer()
            }
            .padding(.vertical)
            .background(Constants.Colors.mainBackground)
            .navigationDestination(isPresented: $navigateToCreateWithUsername) {
                CreateAccountWithUsernameView(navigateToHome: $navigateToHome, birthDate: birthDate)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(isPresented: $showAgeError) {
                Alert(
                    title: Text("Error"),
                    message: Text("User is too young"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Age Validation
    private func validateAge() -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        if let age = ageComponents.year, age < 8 {
            showAgeError = true
            return false
        }
        return true
    }

    // MARK: - Firebase Signup Methods

    private func signUpWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Debug Error: Unable to find root view controller.")
            return
        }

        FirebaseAuthService.shared.loginWithGoogle(presentingViewController: rootViewController) { result in
            switch result {
            case .success:
                navigateToHome = true
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Debug Error: Google Sign-In failed: \(error.localizedDescription)")
            }
        }
    }

    private func signUpWithApple(authorization: ASAuthorization, nonce: String) {
        FirebaseAuthService.shared.loginWithApple(authorization: authorization, nonce: nonce) { result in
            switch result {
            case .success:
                navigateToHome = true
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Debug Error: Apple Sign-In failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Nonce Utilities

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
