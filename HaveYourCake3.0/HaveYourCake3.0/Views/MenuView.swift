//
//  MenuView.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//

import SwiftUI

struct MenuView: View {
    @Binding var isOpen: Bool

    // ViewModels
    var homeViewModel: HomeViewModel
    var settingsViewModel: SettingsViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // Background overlay to close menu
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isOpen = false
                        }
                    }

                // Slide-out menu
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink(destination: HomeView()) {
                        HStack {
                            Image(systemName: "house")
                                .foregroundColor(Constants.Colors.mainText) // Menu item icon color
                            Text("Home")
                                .font(.custom("Palatino", size: 18))
                                .foregroundColor(Constants.Colors.popupText) // Menu item text color
                        }
                        .padding()
                    }

                    NavigationLink(destination: AccountSettingsView(viewModel: settingsViewModel)) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Constants.Colors.mainText) // Menu item icon color
                            Text("Account Settings")
                                .font(.custom("Palatino", size: 18))
                                .foregroundColor(Constants.Colors.popupText) // Menu item text color
                        }
                        .padding()
                    }

                    NavigationLink(destination: RecentlyDeletedView(viewModel: homeViewModel)) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(Constants.Colors.mainText) // Menu item icon color
                            Text("Recently Deleted")
                                .font(.custom("Palatino", size: 18))
                                .foregroundColor(Constants.Colors.popupText) // Menu item text color
                        }
                        .padding()
                    }

                    NavigationLink(destination: ContactUsView()) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(Constants.Colors.mainText) // Menu item icon color
                            Text("Contact Us")
                                .font(.custom("Palatino", size: 18))
                                .foregroundColor(Constants.Colors.popupText) // Menu item text color
                        }
                        .padding()
                    }

                    Spacer()
                }
                .frame(width: 250)
                .background(Constants.Colors.popupBackground) // Background of the menu
                .cornerRadius(20)
                .shadow(radius: 10)
                .offset(x: 0)
                .transition(.move(edge: .leading))
            }
        }
    }
}
