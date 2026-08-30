//
//  navikontApp.swift
//  navikont
//
//  Created by Deniz on 14.06.2026.
//

import SwiftUI

import UserNotifications

// AppDelegate for handling APNs
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request authorization for push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        return true
    }

    func application(_ application: UIApplication, 
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Save the token locally to be sent to backend upon login
        UserDefaults.standard.set(token, forKey: "APNsDeviceToken")
        
        // If user is already logged in, send it immediately
        if let _ = UserDefaults.standard.string(forKey: "authToken") {
            Task {
                try? await NetworkManager.shared.sendDeviceToken(token)
            }
        }
    }

    func application(_ application: UIApplication, 
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct navikontApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isShowingSplash = true
    
    @AppStorage("app_language") private var appLanguage: String = "system"
    
    init() {
        // Yenileme animasyonunun (spinner) rengini temanın ana rengi yapıyoruz
        UIRefreshControl.appearance().tintColor = UIColor(Color(hex: "06B6D4"))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .id(appLanguage) // Force redraw when language changes

                if isShowingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .environmentObject(authService)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.currentMode.colorScheme)
            .task {
                guard isShowingSplash else { return }
                try? await Task.sleep(for: .milliseconds(1_650))
                withAnimation(.easeOut(duration: 0.42)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
