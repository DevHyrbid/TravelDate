//
//  AppDelegate.swift
//  TravelDate
//
//  Created by Dev CodingZone on 31/03/26.
//

import UIKit
import GoogleSignIn
import IQKeyboardManagerSwift
import UserNotifications
import Firebase
import FirebaseMessaging
@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        IQKeyboardManager.shared.enableAutoToolbar = true

        
        FirebaseApp.configure()
        // Notification setup
        requestNotificationPermission(application)
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    // MARK: - Push Notification Permission
    private func requestNotificationPermission(_ application: UIApplication) {

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error:", error)
                return
            }

            print("✅ Notification permission granted:", granted)

            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - APNs Device Token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📲 APNs Device Token:", token)

        // Pass token to Firebase
        Messaging.messaging().apnsToken = deviceToken

        // 🔥 Save token to backend if needed
        // saveDeviceTokenToServer(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for notifications:", error)
    }

    // MARK: - Google Sign-In
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Scene Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}

extension AppDelegate: MessagingDelegate {

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let token = fcmToken else { return }

        print("🔥 Firebase FCM Token:", token)
        UserDefaults.standard.set(token, forKey: "device_token")

        // Save token to backend
        // sendFCMTokenToServer(token)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}


extension AppDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let screen = userInfo["screen"] as? String,
           screen == "downloadScreen" {
            
            if let window = UIApplication.shared.windows.first {
                let nav = window.rootViewController as? UINavigationController
//                let vc = MindsetVC()
//                nav?.pushViewController(vc, animated: true)
            }
        }
        
        completionHandler()
    }
}
