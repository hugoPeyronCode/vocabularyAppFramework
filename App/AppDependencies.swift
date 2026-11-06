import Foundation
import Observation
import OSLog
import SagaceCore
import SagaceData
import SagaceUI
import SwiftData
import UIKit
import UserNotifications

/// Services de l'app, créés une fois et injectés par l'environnement (`03_ARCHITECTURE.md` section 5).
@MainActor @Observable
final class AppDependencies {
    enum State {
        case loading
        case ready(content: ContentRepository, topics: Topics)
        case failed
    }

    private(set) var state: State = .loading
    let container: ModelContainer
    let store: ProgressStore
    let library: LibraryStore
    let practice: PracticeStore
    let profile: ProfileStore
    let reminders: ReminderScheduler
    let widgets: WidgetBridge
    let notifications = NotificationRouter()
    let audio = AudioService()
    let router = AppRouter()
    let connectivity = Connectivity()
    let haptics = HapticsService.shared
    let analytics: any Analytics = ConsoleAnalytics()
    let entitlements: EntitlementService
    let day = SagaceDay()
    /// Développement, TestFlight ou App Store : lu au lancement, avant le chargement du pack.
    private(set) var channel: DistributionChannel = .appStore

    /// Boutons de relecture bêta. En debug, `-hideBetaReview` les masque (captures App Store).
    var showsBetaReview: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-hideBetaReview") { return false }
        #endif
        return channel.showsBetaReview
    }
    /// Horloge de l'app. En debug, `-debugDaysAhead <n>` la décale pour tester révisions et séries.
    let now: () -> Date

    private let logger = Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "app")

    init() {
        do {
            container = try SagaceStore.makeContainer()
        } catch {
            Logger(subsystem: "com.cortex.VocabularyAppFramework", category: "app").error("Base SwiftData indisponible : \(error)")
            container = try! SagaceStore.makeContainer(inMemory: true)
        }
        now = Self.makeClock()
        entitlements = EntitlementService(analytics: analytics, now: now)
        store = ProgressStore(context: container.mainContext, day: day)
        library = LibraryStore(context: container.mainContext, now: now)
        practice = PracticeStore(context: container.mainContext, day: day)
        profile = ProfileStore(context: container.mainContext)
        reminders = ReminderScheduler(progress: store, library: library, profile: profile, entitlements: entitlements, day: day, now: now)
        widgets = WidgetBridge(progress: store, library: library, entitlements: entitlements, analytics: analytics, day: day, now: now)
        notifications.attach(router: router, analytics: analytics)
        haptics.isEnabled = store.preferences.hapticsEnabled
        audio.voiceIdentifier = store.preferences.voiceIdentifier
    }

    private static func makeClock() -> () -> Date {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-debugDaysAhead"), let days = arguments.dropFirst(index + 1).first.flatMap(Double.init) {
            return { Date.now.addingTimeInterval(days * 86_400) }
        }
        #endif
        return { .now }
    }


    func start() async {
        guard case .loading = state else { return }
        let englishPack = Bundle.main.url(forResource: "fiches", withExtension: "json", subdirectory: "Content/en")
        let language = ContentLanguage.preferred(Locale.preferredLanguages, englishPackAvailable: englishPack != nil)
        guard let fichesURL = language == .en ? englishPack : Bundle.main.url(forResource: "fiches", withExtension: "json", subdirectory: "Content/fr"),
              let topicsURL = Bundle.main.url(forResource: "topics", withExtension: "json", subdirectory: "Content/fr") else {
            logger.error("Pack de contenu absent du bundle")
            state = .failed
            return
        }
        channel = await DistributionChannel.current()
        do {
            let content = try await ContentRepository.load(contentsOf: fichesURL, visibility: channel.contentVisibility)
            let topics = try JSONDecoder().decode(Topics.self, from: Data(contentsOf: topicsURL))
            if !content.issues.isEmpty { logger.error("Fiches écartées : \(content.issues.map(\.description))") }
            await migrateFromV3IfNeeded(content: content)
            importPendingV3Words(content: content)
            if router.fullScreen == nil {
                await entitlements.start(legacyPremiumFlag: store.profile.legacyPremiumFlag)
            }
            reminders.content = content
            await reminders.reschedule()
            widgets.content = content
            widgets.applyInbox()
            widgets.refresh()
            state = .ready(content: content, topics: topics)
        } catch {
            logger.error("Chargement du contenu impossible : \(error)")
            state = .failed
        }
    }

    // MARK: Migration Words v3 (04_MIGRATION.md section 7)

    /// Mots aimés v3 restés en attente (pack anglais absent à la migration) : importés dès que le pack anglais est chargé.
    private func importPendingV3Words(content: ContentRepository) {
        let pending = store.profile.pendingV3Headwords
        guard !pending.isEmpty, content.fiches.contains(where: { $0.language == .en }),
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let imported = V3Migration(defaults: .standard, documentsURL: documents, store: store, content: content).importLikedWords(pending, at: now())
        logger.info("Mots aimés v3 importés : \(imported)")
    }

    private func migrateFromV3IfNeeded(content: ContentRepository) async {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let migration = V3Migration(defaults: .standard, documentsURL: documents, store: store, content: content)
        guard migration.isNeeded else { return }
        let report = migration.run(at: now())
        if report.hadAlternateIcon, UIApplication.shared.alternateIconName != nil {
            try? await UIApplication.shared.setAlternateIconName(nil)
        }
        // Les rappels v3 sont retirés ; la replanification selon le nouveau modèle arrive avec ReminderScheduler (M5).
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await entitlements.start(legacyPremiumFlag: report.legacyPremiumFlag)
        analytics.track(.migrationV3Completed(hadSavedWords: report.hadSavedWords, wasPremium: entitlements.isPremium))
        router.fullScreen = .migration(report, isPremium: entitlements.isPremium)
    }
}
