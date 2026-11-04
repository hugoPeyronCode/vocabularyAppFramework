import Foundation
import SagaceCore
import SwiftData
import Testing
@testable import SagaceData

enum TestEnv {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    static let day = SagaceDay(calendar: calendar)

    static func date(days: Int = 0, hour: Int = 12) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: hour))!
        return calendar.date(byAdding: .day, value: days, to: base)!
    }

    @MainActor
    static func makeStore() throws -> (ProgressStore, ModelContainer) {
        let container = try SagaceStore.makeContainer(inMemory: true)
        return (ProgressStore(context: container.mainContext, day: day), container)
    }
}

@MainActor
@Suite("Progression")
struct ProgressStoreTests {

    @Test("Profil et préférences sont des singletons aux valeurs de la spec")
    func singletons() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        #expect(store.preferences.dailyGoal == 5)
        #expect(store.preferences.hapticsEnabled)
        #expect(store.profile.level == Level.intermediaire.rawValue)
        store.preferences.dailyGoal = 3
        #expect(store.preferences.dailyGoal == 3)
    }

    @Test("Vue une première fois, puis revue")
    func markSeen() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        #expect(store.markSeen("fr.a", at: TestEnv.date()))
        #expect(!store.markSeen("fr.a", at: TestEnv.date(hour: 13)))
        #expect(store.allProgress()["fr.a"]?.lastSeenAt == TestEnv.date(hour: 13))
    }

    @Test("Trier compte dans l'objectif une seule fois par fiche, et signale l'objectif atteint")
    func sortingAndGoal() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        store.preferences.dailyGoal = 3
        #expect(store.sort("fr.a", as: .known, at: TestEnv.date()) == SortResult(sortedToday: 1, goalJustReached: false))
        #expect(store.sort("fr.a", as: .toLearn, at: TestEnv.date()).sortedToday == 1)
        #expect(store.sort("fr.b", as: .toLearn, at: TestEnv.date()).sortedToday == 2)
        #expect(store.sort("fr.c", as: .known, at: TestEnv.date()) == SortResult(sortedToday: 3, goalJustReached: true))
        #expect(store.sort("fr.d", as: .known, at: TestEnv.date()) == SortResult(sortedToday: 4, goalJustReached: false))
        #expect(store.activity().first?.goalReached == true)
    }

    @Test("À retenir met la fiche en boîte 1 ; Je savais la sort des révisions")
    func sortingDrivesReview() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        _ = store.sort("fr.a", as: .toLearn, at: TestEnv.date())
        #expect(store.allProgress()["fr.a"]?.review.box == 1)
        _ = store.sort("fr.a", as: .known, at: TestEnv.date())
        #expect(store.allProgress()["fr.a"]?.review == ReviewState())
    }

    @Test("Quatre bonnes révisions rendent le mot maîtrisé")
    func reviewToMastery() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        _ = store.sort("fr.a", as: .toLearn, at: TestEnv.date())
        var results: [ReviewResult] = []
        for offset in [1, 4, 11, 32] {
            results.append(store.answerReview("fr.a", correct: true, at: TestEnv.date(days: offset)))
        }
        #expect(results.map(\.outcome) == [
            .promoted(box: 2, nextInDays: 3), .promoted(box: 3, nextInDays: 7), .promoted(box: 4, nextInDays: 21), .mastered,
        ])
        #expect(results.last?.daysToMaster == 32)
        #expect(store.masteredCount() == 1)
        #expect(store.activity().map(\.reviewsDone).reduce(0, +) == 4)
    }

    @Test("Une mauvaise révision remet en boîte 1")
    func wrongReview() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        _ = store.sort("fr.a", as: .toLearn, at: TestEnv.date())
        _ = store.answerReview("fr.a", correct: true, at: TestEnv.date(days: 1))
        let result = store.answerReview("fr.a", correct: false, at: TestEnv.date(days: 4))
        #expect(result.outcome == .reset(nextInDays: 1))
        #expect(result.previousBox == 2)
        #expect(store.allProgress()["fr.a"]?.review.box == 1)
    }

    @Test("Les fiches triées d'une journée, dans l'ordre")
    func sortedOnDay() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        _ = store.sort("fr.a", as: .known, at: TestEnv.date(hour: 9))
        _ = store.sort("fr.b", as: .toLearn, at: TestEnv.date(hour: 10))
        _ = store.sort("fr.c", as: .known, at: TestEnv.date(days: 1, hour: 9))
        let today = store.sortedFiches(on: TestEnv.day.day(of: TestEnv.date()))
        #expect(today.map(\.ficheID) == ["fr.a", "fr.b"])
        #expect(today.map(\.sorting) == [.known, .toLearn])
    }
}
