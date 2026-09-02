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

    var subscriptionPresenter: SubscriptionPresenter?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        if User.currentUserExists {
            subscriptionPresenter = SubscriptionPresenter(view: nil)
            
            subscriptionPresenter?.load()
        }
        IQKeyboardManager.shared.isEnabled = true
            
              // Show toolbar above keyboard
              // Optional configs (recommended)
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 20

        
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

extension AppDelegate: UNUserNotificationCenterDelegate  {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        let userInfo = notification.request.content.userInfo

        print("📩 Foreground Push:", userInfo)

        let pushEnabled = User.curentUser?.is_push_notification == true

        guard let type = userInfo["type"] as? String else {
            
            // No type → only show notification if user has enabled push
            if pushEnabled {
                completionHandler([.banner, .sound, .badge])
            } else {
                completionHandler([])
            }
            
            return
        }

        // MARK: - CHAT MESSAGE
        if type == "CHAT_MESSAGE" {

            // Always update chat internally
            NotificationCenter.default.post(
                name: .didReceiveChatMessage,
                object: nil,
                userInfo: userInfo
            )

            // If push notifications are disabled → don't show anything
            guard pushEnabled else {
                completionHandler([])
                return
            }

            // If already inside chat → sound only
            if ChatState.shared.isChatOpen {

                completionHandler([.sound])

            } else {

                // Outside chat → banner + sound + badge
                completionHandler([.banner, .sound, .badge])
            }

            return
        }

        // MARK: - GROUP JOIN
        if type == "GROUP_JOIN" {

            // Always update app data internally
            NotificationCenter.default.post(
                name: .valueUpdated,
                object: nil,
                userInfo: userInfo
            )

            // Push disabled → no banner
            guard pushEnabled else {
                completionHandler([])
                return
            }

            // Push enabled → show notification
            completionHandler([.banner, .sound, .badge])

            return
        }

        // MARK: - OTHER NOTIFICATIONS

        // Your app can still process/update data here if required.

        if pushEnabled {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([])
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}


extension AppDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        let userInfo = response.notification.request.content.userInfo
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("📩 Notification Clicked:", userInfo)

        NotificationCenter.default.post(
            name: .openChatFromPush,
            object: nil,
            userInfo: userInfo
        )

        completionHandler()
    }
}

import Foundation

extension Notification.Name {
    static let didReceiveChatMessage = Notification.Name("didReceiveChatMessage")
    static let openChatFromPush = Notification.Name("openChatFromPush")
}
final class ChatState {

    static let shared = ChatState()

    var isChatOpen = false
    var activeRoomId: String?
}
