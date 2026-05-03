//
//  LocalNotfication.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import UIKit
import UserNotifications

final class LocalNotificationManager {
    
    static let shared = LocalNotificationManager()
    private init() {}
    
    // MARK: - Request Permission
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Permission denied")
            }
        }
    }
    
    // MARK: - Generic Scheduler
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled: \(id)")
            }
        }
    }
    
    // MARK: - Cancel
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    // MARK: - Clear All
    func cancelAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
}


extension LocalNotificationManager {
    
    func schedulePostRegistrationReminder() {
        
        scheduleNotification(
            id: "create_group_reminder",
            title: "Start Your Journey 🚀",
            body: "Create your first group and start planning your trip!",
            timeInterval: 20 * 60 // 20 minutes
        )
    }
}
