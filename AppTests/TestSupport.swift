import Foundation
import Synchronization
import SagaceCore
import SagaceData
import SagaceUI
import SwiftData
@testable import VocabularyAppFramework

/// Fichiers du dépôt lus directement par les tests (le simulateur voit le disque du Mac).
enum RepoFiles {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    static let storeKitConfiguration = root.appending(path: "Config/Sagace.storekit")
    static let seedFiches = root.appending(path: "content/fr/seed_fiches.json")
    static let topics = root.appending(path: "content/fr/topics.json")
}

@MainActor
final class FakePremium: PremiumProviding {
    var isPremium: Bool
    init(_ isPremium: Bool) { self.isPremium = isPremium }
}

@MainActor
final class SilentHaptics: HapticPlaying {
    func play(_ event: HapticEvent) {}
}

@MainActor
final class SilentAudio: Speaking {
    func speak(_ text: String, language: Language) {}
}

final class RecordingAnalytics: Analytics {
    private let recorded = Mutex<[AnalyticsEvent]>([])
    var events: [AnalyticsEvent] { recorded.withLock { $0 } }
    func track(_ event: AnalyticsEvent) { recorded.withLock { $0.append(event) } }
}

/// Dépendances en mémoire pour tester les view models.
@MainActor
struct TestWorld {
    let container: ModelContainer
    let progress: ProgressStore
    let library: LibraryStore
    let practice: PracticeStore
    let content: ContentRepository
    let topics: Topics

    init() throws {
        container = try SagaceStore.makeContainer(inMemory: true)
        progress = ProgressStore(context: container.mainContext)
        library = LibraryStore(context: container.mainContext)
        practice = PracticeStore(context: container.mainContext)
        content = try ContentRepository(data: Data(contentsOf: RepoFiles.seedFiches), visibility: .development)
        topics = try JSONDecoder().decode(Topics.self, from: Data(contentsOf: RepoFiles.topics))
    }
}
