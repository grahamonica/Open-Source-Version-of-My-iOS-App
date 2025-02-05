//
//  App.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 12/18/24.
//
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import FirebaseCore
import GoogleSignIn
import UIKit

// AppDelegate handles Firebase initialization and other app-level configurations
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("Initializing Firebase...")
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.warning)

        // Configure Google Sign-In
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("Google Sign-In configured with clientID: \(clientID)")
        } else {
            print("Google Sign-In configuration failed. Client ID is missing.")
        }

        print("Firebase initialized successfully.")
        return true
    }
}

@main
struct HaveYourCakeApp: App {
    @Environment(\.scenePhase) var scenePhase;    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if #available(iOS 17.0, *) {
                handleScenePhaseChange(oldPhase: nil, newPhase: newPhase)
            } else {
                // For earlier iOS versions
                handleScenePhaseChange(oldPhase: nil, newPhase: newPhase)
            }
        }
    }

    private func handleScenePhaseChange(oldPhase: ScenePhase?, newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            print("App moved to the background or became inactive.")
        case .active:
            print("App is active.")
        @unknown default:
            print("Unexpected new scene phase.")
        }
    }
}
