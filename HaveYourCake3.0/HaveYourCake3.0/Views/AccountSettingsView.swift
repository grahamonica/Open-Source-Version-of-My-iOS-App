import SwiftUI

enum AlertType: Identifiable {
    case logout, deleteAccount, accountDeleted, guestWarning

    var id: String {
        switch self {
        case .logout: return "logout"
        case .deleteAccount: return "deleteAccount"
        case .accountDeleted: return "accountDeleted"
        case .guestWarning: return "guestWarning"
        }
    }
}

struct AccountSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isMenuOpen: Bool = false
    @State private var showAlert: AlertType? = nil
    @State private var isProcessing = false
    @State private var passwordInput: String = ""
    @State private var showReauthPopup = false
    @State private var navigateToMainLogin: Bool = false // State for navigation binding

    var body: some View {
        NavigationStack { // Wrap in a NavigationStack
            ZStack(alignment: .topLeading) {
                // Main Background
                Constants.Colors.mainBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            isMenuOpen.toggle()
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title)
                                .foregroundColor(Constants.Colors.mainButtonColor)
                                .padding(.leading, 16)
                        }

                        Spacer()

                        Text("Account Settings")
                            .font(.custom("Palatino", size: 28).weight(.bold))
                            .foregroundColor(Constants.Colors.mainText)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer()
                    }
                    .padding(.vertical, 20)

                    // Preferences Section
                    List {
                        Section(header: Text("Preferences")
                            .font(.custom("Palatino", size: 20).weight(.bold))
                            .foregroundColor(Constants.Colors.mainText)) {
                            Toggle(isOn: $viewModel.notificationsEnabled) {
                                Text("Enable Notifications")
                                    .font(.custom("Palatino", size: 18))
                                    .foregroundColor(Constants.Colors.mainButtonTextColor)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                            .padding()
                            .background(Constants.Colors.mainButtonColor)
                            .cornerRadius(18)
                        }
                        .listRowBackground(Constants.Colors.mainBackground)

                        // Account Actions Section
                        Section(header: Text("Account Actions")
                            .font(.custom("Palatino", size: 20).weight(.bold))
                            .foregroundColor(Constants.Colors.mainText)) {
                            VStack(spacing: 10) {
                                Button(action: {
                                    if viewModel.isGuestUser {
                                        showAlert = .guestWarning
                                    } else {
                                        showAlert = .deleteAccount
                                    }
                                }) {
                                    Text("Delete Account")
                                        .font(.custom("Palatino", size: 18))
                                        .foregroundColor(Constants.Colors.mainButtonTextColor)
                                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Constants.Colors.mainButtonColor)
                                        .cornerRadius(18)
                                }

                                Button(action: {
                                    showAlert = .logout
                                }) {
                                    Text("Log Out")
                                        .font(.custom("Palatino", size: 18))
                                        .foregroundColor(Constants.Colors.mainButtonTextColor)
                                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Constants.Colors.mainButtonColor)
                                        .cornerRadius(18)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                        }
                        .listRowBackground(Constants.Colors.mainBackground)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .background(Constants.Colors.mainBackground)
                    .scrollContentBackground(.hidden)

                    Spacer()
                }
                .padding(.horizontal, Constants.Layout.padding)
                .alert(item: $showAlert) { alert in
                    alertForType(alert)
                }

                // Hamburger Menu
                if isMenuOpen {
                    MenuView(
                        isOpen: $isMenuOpen,
                        homeViewModel: HomeViewModel(),
                        settingsViewModel: viewModel
                    )
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showReauthPopup) {
                ReauthPopup(password: $passwordInput) {
                    handleReauthentication()
                }
            }
            .onChange(of: navigateToMainLogin) { newValue in
                if newValue {
                    navigateToMainLoginView()
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func alertForType(_ alert: AlertType) -> Alert {
        switch alert {
        case .logout:
            return Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    handleLogout()
                },
                secondaryButton: .cancel()
            )
        case .deleteAccount:
            return Alert(
                title: Text("Delete Account"),
                message: Text("This action is irreversible."),
                primaryButton: .destructive(Text("Delete")) {
                    showReauthPopup = true // Trigger reauthentication popup
                },
                secondaryButton: .cancel()
            )
        case .guestWarning:
            return Alert(
                title: Text("Guest Account"),
                message: Text("As a guest, you cannot delete your account."),
                dismissButton: .default(Text("OK"))
            )
        case .accountDeleted:
            return Alert(
                title: Text("Account Deleted"),
                message: Text("Your account has been deleted."),
                dismissButton: .default(Text("OK")) {
                    navigateToMainLogin = true // Trigger navigation
                }
            )
        }
    }

    private func handleLogout() {
        isProcessing = true
        viewModel.logOut { result in
            isProcessing = false
            switch result {
            case .success:
                // Reset the navigation state before navigating to MainLoginView
                DispatchQueue.main.async {
                    navigateToMainLogin = true
                }
            case .failure(let error):
                print("Logout failed: \(error.localizedDescription)")
            }
        }
    }

    private func handleReauthentication() {
        isProcessing = true
        viewModel.reauthenticate(password: passwordInput) { result in
            isProcessing = false
            switch result {
            case .success:
                handleDeleteAccount()
            case .failure(let error):
                print("Reauthentication failed: \(error.localizedDescription)")
            }
        }
    }

    private func handleDeleteAccount() {
        isProcessing = true
        viewModel.deleteAccount(password: passwordInput) { result in
            isProcessing = false
            switch result {
            case .success:
                showAlert = .accountDeleted
            case .failure(let error):
                print("Account deletion failed: \(error.localizedDescription)")
            }
        }
    }

    private func navigateToMainLoginView() {
        DispatchQueue.main.async {
            // Replace the current view with MainLoginView and ensure a fresh state
            guard let window = UIApplication.shared.windows.first else {
                return
            }

            // Create a fresh instance of MainLoginView with a new binding
            let mainLoginView = MainLoginView(navigateToHome: .constant(false))
            let hostingController = UIHostingController(rootView: mainLoginView)

            // Set the new root view controller directly
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
        }
    }
}

struct ReauthPopup: View {
    @Binding var password: String
    var onAuthenticate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Reauthenticate")
                .font(.custom("Palatino", size: 24).weight(.bold))
                .foregroundColor(Constants.Colors.mainText)

            SecureField("Enter Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Constants.Colors.enterTextFieldBackground)
                .cornerRadius(8)

            Button(action: {
                onAuthenticate()
            }) {
                Text("Authenticate")
                    .font(.custom("Palatino", size: 18).weight(.bold))
                    .foregroundColor(Constants.Colors.mainButtonTextColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Constants.Colors.mainButtonColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Constants.Colors.popupBackground)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(maxWidth: 300)
    }
}
