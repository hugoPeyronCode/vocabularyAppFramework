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
    private(set) var languagePreference = AppLanguagePreference.saved()
    private(set) var isChangingLanguage = false
    private(set) var contentRevision = 0
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
        let language = languagePreference.resolved(englishPackAvailable: englishPack != nil)
        channel = await DistributionChannel.current()
        do {
            let (content, topics) = try await AppContent.load(language, visibility: channel.contentVisibility)
            if !content.issues.isEmpty { logger.error("Fiches écartées : \(content.issues.map(\.description))") }
            await migrateFromV3IfNeeded(content: content)
            importPendingV3Words(content: content)
            if router.fullScreen == nil {
                await startEntitlements(legacyPremiumFlag: store.profile.legacyPremiumFlag)
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

    /// Charge avant de valider le choix : une erreur conserve le pack et la langue précédents.
    @discardableResult
    func setLanguage(_ preference: AppLanguagePreference) async -> Bool {
        guard !isChangingLanguage, case .ready = state else { return false }
        guard preference != languagePreference else { return true }
        isChangingLanguage = true
        defer { isChangingLanguage = false }
        do {
            let (content, topics) = try await AppContent.load(preference.resolved(), visibility: channel.contentVisibility)
            widgets.applyInbox()
            importPendingV3Words(content: content)
            preference.save()
            languagePreference = preference
            reminders.content = content
            widgets.content = content
            widgets.refresh()
            router.sheet = nil
            router.stackedPaywall = nil
            state = .ready(content: content, topics: topics)
            contentRevision += 1
            await reminders.reschedule()
            return true
        } catch {
            logger.error("Changement de langue impossible : \(error)")
            return false
        }
    }

    /// Produits et droits StoreKit, attendus au plus `Rules.storeKitLaunchTimeout` secondes : sur un appareil,
    /// `Transaction.currentEntitlements` peut ne jamais répondre et laissait l'app sur le chargement. Passé ce délai,
    /// les droits arrivent en arrière-plan (`isPremium` est observé).
    private func startEntitlements(legacyPremiumFlag: Bool) async {
        let entitlements = entitlements
        let answered = await value(within: Rules.storeKitLaunchTimeout) {
            await entitlements.start(legacyPremiumFlag: legacyPremiumFlag)
        }
        if answered == nil { logger.notice("StoreKit sans réponse au lancement, droits relus en arrière-plan") }
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
        await startEntitlements(legacyPremiumFlag: report.legacyPremiumFlag)
        analytics.track(.migrationV3Completed(hadSavedWords: report.hadSavedWords, wasPremium: entitlements.isPremium))
        router.fullScreen = .migration(report, isPremium: entitlements.isPremium)
    }
}
