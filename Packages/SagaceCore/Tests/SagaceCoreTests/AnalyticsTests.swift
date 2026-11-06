import Foundation
import Testing
@testable import SagaceCore

/// Critère M7 : les événements du code sont exactement ceux de `03_ARCHITECTURE.md` section 11, avec leurs propriétés.
@Suite("Analytics")
struct AnalyticsTests {
    /// Un exemple de chaque événement.
    static let samples: [AnalyticsEvent] = [
        .onboardingStepViewed(step: "welcome"),
        .onboardingCompleted(miniTestScore: 3, dailyGoal: 5, notificationsGranted: true),
        .paywallViewed(source: "crown"),
        .purchaseCompleted(productID: "weekly"),
        .ficheViewed(ficheID: "fr.x", family: .paronyme, origin: .feed),
        .ficheSorted(ficheID: "fr.x", sorting: .known),
        .reviewAnswered(ficheID: "fr.x", box: 1, correct: true),
        .ficheMastered(ficheID: "fr.x", daysToMaster: 30),
        .dailyGoalCompleted(streak: 3),
        .practiceStarted(mode: .sens),
        .practiceCompleted(mode: .sens, score: 8, total: 10),
        .levelTestCompleted(score: 20, level: .intermediaire),
        .widgetInteraction(kind: .revision, action: .answer),
        .notificationOpened(reminderSource: "fichesDuJour"),
        .errorReported(ficheID: "fr.x", reason: .definition),
        .migrationV3Completed(hadSavedWords: true, wasPremium: false),
    ]

    /// Lignes du tableau de la section 11 : événement(s) et propriétés.
    static func documented() throws -> [String: Set<String>] {
        let url = SeedContent.repoRoot.appending(path: "docs/sagace/03_ARCHITECTURE.md")
        let text = try String(contentsOf: url, encoding: .utf8)
        let section = try #require(text.components(separatedBy: "## 11.").dropFirst().first?.components(separatedBy: "\n## ").first)
        var events: [String: Set<String>] = [:]
        for line in section.split(separator: "\n") where line.hasPrefix("| `") {
            let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            let names = cells[0].split(separator: "/").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " `")) }
            let listed = cells[1].replacing(/\s*\([^)]*\)/, with: "")
            let properties = Set(listed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
            for name in names { events[name] = properties }
        }
        return events
    }

    @Test("Chaque événement documenté est émis par le code, et inversement")
    func names() throws {
        #expect(Set(Self.samples.map(\.name)) == Set(try Self.documented().keys))
    }

    @Test("Propriétés conformes à la documentation", arguments: samples)
    func properties(event: AnalyticsEvent) throws {
        #expect(Set(event.properties.keys) == (try Self.documented()[event.name]))
    }
}
