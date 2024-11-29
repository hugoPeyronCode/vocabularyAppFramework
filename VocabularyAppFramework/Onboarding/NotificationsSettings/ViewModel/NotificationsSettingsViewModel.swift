//
//  NotificationsSettingsViewModel.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import Foundation
import UserNotifications
import SwiftUI

// First, let's define the NotificationSound enum that's missing
enum NotificationSound: String, CaseIterable {
    case `default` = "default"
    case bell = "bell"
    case chime = "chime"
    case success = "success"

    var filename: String {
        return self.rawValue
    }
}

extension NotificationsSettingsView {
    class NotificationManager {
        static let shared = NotificationManager()
        private let notificationId = "dailyReminder"

        private init() {}

        func scheduleDailyNotification(at date: Date, sound: NotificationSound) {
            // Remove any existing notifications first
            removeDailyNotification()

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Time for your daily vocabulary! 📚")
            content.body = String(localized: "Expand your knowledge with today's word.")

            // Set the notification sound
            if sound == .default {
                content.sound = .default
            } else {
                content.sound = UNNotificationSound(named: UNNotificationSoundName("\(sound.filename).caf"))
            }

            // Create date components from the selected date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)

            // Create the trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            // Create the request
            let request = UNNotificationRequest(
                identifier: notificationId,
                content: content,
                trigger: trigger
            )

            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("Error scheduling notification: \(error)")
                }
            }
        }

        func removeDailyNotification() {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }

        func handleNotificationPermission(
            preferredTime: Date,
            sound: NotificationSound,
            completion: @escaping (_ granted: Bool, _ isFirstTime: Bool) -> Void
        ) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        self.requestNotificationPermission { granted in
                            if granted {
                                self.scheduleDailyNotification(at: preferredTime, sound: sound)
                            }
                            completion(granted, true)
                        }
                    case .authorized, .ephemeral:
                        self.scheduleDailyNotification(at: preferredTime, sound: sound)
                        completion(true, false)
                    case .denied, .provisional:
                        completion(false, false)
                    @unknown default:
                        completion(false, false)
                    }
                }
            }
        }

        private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
}
