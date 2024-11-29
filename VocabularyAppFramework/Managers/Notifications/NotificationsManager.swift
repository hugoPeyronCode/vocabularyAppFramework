//
//  NotificationsManager.swift
//  VocabularyAppFramework
//
//  Created by Hugo Peyron on 30/10/2023.
//

import Foundation
import SwiftUI
import UserNotifications

//
//class NotificationsManager {
//    
//    let words = WordManager.shared.allWords
//    
//    static let current = NotificationsManager()
//    
//    
//    func askPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
//            if success {
//                print("access granted")
//            } else if let error = error {
//                print(error.localizedDescription)
//            }
//        }
//    }
//    
//    func hasNotificationPermission(completion: @escaping (Bool) -> Void) {
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            if settings.alertSetting == .enabled {
//                completion(true)
//            } else {
//                completion(false)
//            }
//        }
//    }
//    
//    func sendNotification(date : Date, type: String, timeInterval : Double = 10, title: String, body: String, sound: NotificationSound) {
//        var trigger: UNNotificationTrigger?
//        
//        if type == "date" {
//            let dateComponent = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: date)
//            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
//        } else if type == "time" {
//            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
//        }
//        
//        let randomWord = words.randomElement()
//        
//        let content = UNMutableNotificationContent()
//        content.title = "Word of the day: \(randomWord?.Headword.capitalized ?? "Floccinaucinihilipilification")"
//        content.body = randomWord?.Definition ?? "The act or habit of describing or regarding something as unimportant, of having no value or being worthless."
//        content.sound = UNNotificationSound.default
//        
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request)
//        
//        switch sound {
//        case .default:
//            content.sound = UNNotificationSound.default
//        case .positive:
////            content.sound = UNNotificationSound.defaultRingtone
//            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "positive"))
//        case .classical:
//            content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 10)
////            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "classical.caf"))
//        }
//    }
//}
