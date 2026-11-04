import BackgroundTasks
import Foundation
import OSLog
import SagaceCore
import SagaceData
import UserNotifications

/// Planifie les rappels (REM-01) et le rappel du soir : 7 jours glissants, 60 notifications au plus,
/// replanifiés à chaque ouverture, au passage en arrière-plan et par `BGAppRefreshTask`.
@MainActor
final class ReminderScheduler {
    static let identifierPrefix = "sagace.reminder."
    static let refreshTaskIdentifier = "com.cortex.VocabularyAppFramework.refresh"

    private let center: UNUserNotificationCenter
    private let progress: any ProgressStoring
    private let library: any LibraryStoring
    private let profile: any ProfileStoring
    private let entitlements: any PremiumProviding
    private let day: SagaceDay
    private let now: () -> Date
    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "reminders")
    var content: ContentRepository?

    init(center: UNUserNotificationCenter = .current(), progress: any ProgressStoring, library: any LibraryStoring,
         profile: any ProfileStoring, entitlements: any PremiumProviding, day: SagaceDay, now: @escaping () -> Date) {
        self.center = center; self.progress = progress; self.library = library; self.profile = profile
        self.entitlements = entitlements; self.day = day; self.now = now
    }

    /// Rappels actifs : gratuit = le premier seulement.
    private var activeSpecs: [ReminderSpec] {
        let specs = profile.reminders().map(\.spec)
        return entitlements.isPremium ? specs : Array(specs.prefix(Rules.freeReminderCount))
    }

    func reschedule() async {
        guard let content else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let activity = progress.activity()
        let evening = progress.preferences.eveningStreakReminder && StreakCalculator(day: day).needsEveningReminder(activity, at: now())
        let planned = ReminderPlanner(calendar: day.calendar).plan(activeSpecs, eveningStreak: evening, from: now())
        let streak = StreakCalculator(day: day).summary(of: activity, at: now()).current
        var cursor: [String: Int] = [:]
        for (index, item) in planned.enumerated() {
            let notification = UNMutableNotificationContent()
            switch item.kind {
            case .eveningStreak:
                notification.title = String(localized: "Votre série de \(streak) jours vous attend.")
                notification.body = String(localized: "Une fiche suffit pour la garder.")
            case let .reminder(id, source, sourceID, soundID):
                let fiches = self.fiches(for: source, sourceID: sourceID, content: content)
                guard !fiches.isEmpty else { continue }
                let position = cursor[id, default: 0]
                cursor[id] = position + 1
                let fiche = fiches[position % fiches.count]
                if let confusion = fiche.confusions.first {
                    notification.title = String(localized: "\(fiche.headword) ou \(confusion.word) ?")
                } else {
                    notification.title = fiche.headword
                }
                notification.body = fiche.shortDefinition
                notification.userInfo = ["ficheID": fiche.id, "source": source.rawValue]
                notification.sound = soundID == "default" ? .default : UNNotificationSound(named: UNNotificationSoundName("\(soundID).caf"))
            }
            if notification.sound == nil { notification.sound = .default }
            let components = day.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let request = UNNotificationRequest(identifier: "\(Self.identifierPrefix)\(index)", content: notification,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
            try? await center.add(request)
        }
        logger.info("\(planned.count) rappels planifiés")
    }

    /// Fiches du rappel, contenu figé à la planification.
    private func fiches(for source: ReminderSource, sourceID: String?, content: ContentRepository) -> [Fiche] {
        let all = content.fiches
        let progress = progress.allProgress()
        let fiches: [Fiche] = switch source {
        case .fichesDuJour:
            FeedEngine(day: day).eligible(all, progress: progress, profile: FeedProfile(), at: now())
        case .aRetenir:
            Library(day: day).toLearn(progress.values, at: now()).compactMap { content.fiche(id: $0.ficheID) }
        case .collection:
            library.collections().first { $0.name == sourceID }?.ficheIDs.compactMap(content.fiche(id:)) ?? []
        case .famille:
            sourceID.flatMap(Family.init(rawValue:)).map(content.fiches(in:)) ?? []
        }
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(day.day(of: now()).timeIntervalSinceReferenceDate)))
        return (fiches.isEmpty ? all : fiches).shuffled(using: &rng)
    }

    /// Prochaine replanification en arrière-plan.
    func submitBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = now().addingTimeInterval(6 * 3_600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("Tâche de fond refusée : \(error)")
        }
    }
}
