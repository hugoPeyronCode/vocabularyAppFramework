import Foundation
import SagaceCore
import UserNotifications

/// Ouverture d'une notification : la fiche s'ouvre et `notification_opened` est émis.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    @MainActor private weak var router: AppRouter?
    @MainActor private var analytics: (any Analytics)?

    @MainActor
    func attach(router: AppRouter, analytics: any Analytics) {
        self.router = router
        self.analytics = analytics
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        let ficheID = info["ficheID"] as? String
        let source = info["source"] as? String ?? "evening_streak"
        await MainActor.run {
            analytics?.track(.notificationOpened(reminderSource: source))
            if let ficheID { router?.open(.fiche(ficheID, origin: .notification)) }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
