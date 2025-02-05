//  MainLoginView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct MainLoginView: View {
    @State private var showLoginPopup: Bool = false
    @State private var showCreateAccount: Bool = false
    @Binding var navigateToHome: Bool
    @State private var errorMessage: String? = nil
    @State private var currentNonce: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Centered Title
                Text("Welcome to Have Your Cake")
                    .font(.custom("Palatino", size: 32).weight(.bold))
                    .foregroundColor(Constants.Colors.mainText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 50)

                Spacer()

                // Login Buttons
                VStack(spacing: 20) {
                    // Login with Email Button
                    Button(action: {
                        showLoginPopup = true
                    }) {
                        HStack {
                            Image(systemName: "person.fill") // White mail icon
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)

                            Text("Sign in with Username")
                                .font(.custom("San Fransisco", size: 20).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                    }

                    // Google Sign-In Button
                    Button(action: {
                        loginWithGoogle()
                    }) {
                        HStack {
                            Image("google_logo") // Ensure this is the correct Google logo asset
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)

                            Text("Sign in with Google")
                                .font(.custom("San Fransisco", size: 20).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                    }

                    // Sign in with Apple Button
                    SignInWithAppleButton { request in
                        let nonce = generateNonce()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let nonce = currentNonce {
                                loginWithApple(authorization: authorization, nonce: nonce)
                            } else {
                                errorMessage = "Failed to generate nonce."
                            }
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 55)
                    .cornerRadius(Constants.Layout.cornerRadius)

                    // Continue as Guest Button
                    Button(action: {
                        loginAsGuest()
                    }) {
                        HStack {
                            Image(systemName: "person.fill") // White user icon
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 8)

                            Text("Continue as Guest")
                                .font(.custom("San Fransisco", size: 20).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Layout.cornerRadius)
                    }
                }
                .padding(.horizontal, Constants.Layout.padding)

                Spacer()

                // Create Account Button
                Button(action: {
                    showCreateAccount = true
                }) {
                    Text("Create Account")
                        .font(.custom("Palatino", size: 20).weight(.semibold))
                        .foregroundColor(Constants.Colors.mainText)
                        .underline()
                }

                Spacer()

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("San Fransisco", size: 14))
                        .foregroundColor(Constants.Colors.errorColor)
                }
            }
            .padding()
            .background(Constants.Colors.mainBackground)
            .fullScreenCover(isPresented: $showLoginPopup) {
                LoginWithUsernamePopup(navigateToHome: $navigateToHome)
            }
            .fullScreenCover(isPresented: $showCreateAccount) {
                CreateAccountView(navigateToHome: $navigateToHome)
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
                    .onAppear {
                        // Reset the navigation state after navigating to HomeView
                        navigateToHome = false
                    }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Reset navigation state when the view appears
            navigateToHome = false
        }
    }

    // MARK: - Firebase Login Methods

    private func loginWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller."
            return
        }

        FirebaseAuthService.shared.loginWithGoogle(presentingViewController: rootViewController) { result in
            switch result {
            case .success:
                navigateToHome = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loginWithApple(authorization: ASAuthorization, nonce: String) {
        FirebaseAuthService.shared.loginWithApple(authorization: authorization, nonce: nonce) { result in
            switch result {
            case .success:
                navigateToHome = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loginAsGuest() {
        FirebaseAuthService.shared.loginAsGuest { result in
            switch result {
            case .success:
                navigateToHome = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce Helper Functions

    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
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
        return hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
