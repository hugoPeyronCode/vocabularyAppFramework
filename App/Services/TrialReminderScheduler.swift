import Foundation
import UserNotifications

@MainActor
protocol TrialReminderScheduling: AnyObject {
    func schedule(at date: Date) async
}

/// Notification locale "votre essai se termine demain" (PAY-01, toggle activé par défaut).
@MainActor
final class TrialReminderScheduler: TrialReminderScheduling {
    static let identifier = "sagace.trial-reminder"
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func schedule(at date: Date) async {
        let status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Votre essai gratuit se termine demain.")
        content.body = String(localized: "Vous pouvez annuler à tout moment depuis les réglages de votre compte Apple.")
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: Self.identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        try? await center.add(request)
    }
}
