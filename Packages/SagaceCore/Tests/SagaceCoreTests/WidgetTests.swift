import Foundation
import Testing
@testable import SagaceCore

@Suite("Widgets")
struct WidgetTests {
    private let day = TestClock.day
    private let now = TestClock.date(hour: 12)

    private func pack() throws -> [Fiche] {
        try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development).fiches
    }

    private func build(_ fiches: [Fiche], progress: [String: FicheProgress] = [:], isPremium: Bool = false,
                       activity: [DayActivity] = []) -> WidgetSnapshot {
        WidgetSnapshotBuilder(day: day).build(
            .init(fiches: fiches, progress: progress, profile: FeedProfile(), isPremium: isPremium, dailyGoal: 5, activity: activity),
            at: now, grammar: { $0.partOfSpeech.rawValue }, gameTitle: { $0.rawValue }
        )
    }

    @Test("Snapshot : la fiche vue en premier aujourd'hui (mot du jour) d'abord, puis des fiches non triées")
    func cards() throws {
        let fiches = try pack()
        let first = fiches[3]
        let progress = [first.id: FicheProgress(ficheID: first.id, firstSeenAt: TestClock.date(hour: 8), lastSeenAt: TestClock.date(hour: 8))]
        let snapshot = build(fiches, progress: progress)
        #expect(snapshot.cards.first?.id == first.id)
        #expect(snapshot.cards.count <= Rules.widgetCardCount)
        #expect(Set(snapshot.cards.map(\.id)).count == snapshot.cards.count)
        #expect(snapshot.cardsByFamily.isEmpty)
    }

    @Test("Filtre par famille : premium seulement")
    func families() throws {
        let fiches = try pack()
        let premium = build(fiches, isPremium: true)
        let filtered = premium.cards(for: .paronyme)
        #expect(!filtered.isEmpty && filtered.allSatisfy { $0.family == Family.paronyme.rawValue })
        #expect(build(fiches).cards(for: .paronyme) == build(fiches).cards)
    }

    @Test("Révisions dues mises en questions à choix de mots : ni Juste ou fautif, ni Sens (définitions trop longues)")
    func reviews() throws {
        let fiches = try pack()
        let due = ReviewState(box: 1, nextReviewAt: TestClock.date(days: -1))
        let progress = Dictionary(uniqueKeysWithValues: fiches.prefix(8).map {
            ($0.id, FicheProgress(ficheID: $0.id, sorting: .toLearn, sortedAt: TestClock.date(days: -2), review: due))
        })
        let snapshot = build(fiches, progress: progress)
        #expect(snapshot.dueReviewCount == 8)
        #expect(!snapshot.reviews.isEmpty && snapshot.reviews.count <= Rules.widgetReviewCount)
        for review in snapshot.reviews {
            #expect(review.title != GameType.justeOuFautif.rawValue && review.title != GameType.sens.rawValue)
            #expect(review.choices.indices.contains(review.correctIndex))
            #expect(!review.explanation.isEmpty)
        }
    }

    @Test("Widget de révision : réponse, explication jusqu'à Continuer, puis révision suivante")
    func reviewFlow() throws {
        let reviews = (1...2).map {
            WidgetSnapshot.Review(ficheID: "f\($0)", headword: "mot\($0)", title: "Sens", prompt: "?", choices: ["a", "b", "c"], correctIndex: 1, explanation: "Parce que.")
        }
        let snapshot = WidgetSnapshot(generatedAt: now, day: day.day(of: now), isPremium: false, cards: [], cardsByFamily: [:], reviews: reviews,
                                      dueReviewCount: 3, streak: 0, isActiveToday: false, sortedToday: 0, dailyGoal: 5)
        var inbox = WidgetInbox()
        #expect(snapshot.reviewDisplay(inbox) == .question(reviews[0]))
        inbox.answer(reviews[0], choice: 2, at: now)
        #expect(snapshot.reviewDisplay(inbox) == .feedback(reviews[0], chosenIndex: 2, isCorrect: false))
        inbox.answer(reviews[0], choice: 1, at: now)
        #expect(inbox.actions == [.review(ficheID: "f1", correct: false, at: now)])
        inbox.continueReview()
        #expect(snapshot.reviewDisplay(inbox) == .question(reviews[1]))
        inbox.answer(reviews[1], choice: 1, at: now)
        inbox.continueReview()
        #expect(snapshot.reviewDisplay(inbox) == .done(remaining: 1))
    }

    @Test("Série vue plus tard : intacte le lendemain d'un jour actif, perdue ensuite ; triées remises à zéro")
    func staleStreak() {
        let active = WidgetSnapshot(generatedAt: now, day: day.day(of: now), isPremium: false, cards: [], cardsByFamily: [:], reviews: [],
                                    dueReviewCount: 0, streak: 6, isActiveToday: true, sortedToday: 3, dailyGoal: 5)
        #expect(active.streak(at: TestClock.date(hour: 22), day: day) == 6)
        #expect(active.streak(at: TestClock.date(days: 1), day: day) == 6)
        #expect(active.streak(at: TestClock.date(days: 2), day: day) == 0)
        #expect(active.sortedToday(at: TestClock.date(days: 1), day: day) == 0)
        let idle = WidgetSnapshot(generatedAt: now, day: day.day(of: now), isPremium: false, cards: [], cardsByFamily: [:], reviews: [],
                                  dueReviewCount: 0, streak: 6, isActiveToday: false, sortedToday: 0, dailyGoal: 5)
        #expect(idle.streak(at: TestClock.date(days: 1), day: day) == 0)
    }

    @Test("Frise : une fois par jour au nouveau lot (défaut), deux fois, toutes les heures")
    func schedule() {
        let daily = WidgetSchedule.entryDates(.daily, from: now, day: day)
        #expect(daily == [now, day.nextBatch(after: now)])
        let twice = WidgetSchedule.entryDates(.twiceDaily, from: now, day: day)
        #expect(twice.count == 3 && twice.last == day.nextBatch(after: now))
        let hourly = WidgetSchedule.entryDates(.hourly, from: now, day: day)
        #expect(hourly.count == Rules.widgetHourlyEntries && zip(hourly, hourly.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test("Suivante et À retenir : décalage par widget, actions pour l'app, une seule fois par fiche")
    func cardActions() {
        var inbox = WidgetInbox()
        inbox.nextCard(key: WidgetInbox.allKey, at: now)
        inbox.nextCard(key: WidgetInbox.allKey, at: now)
        inbox.saveToLearn("f1", at: now)
        inbox.saveToLearn("f1", at: now)
        #expect(inbox.cardOffsets[WidgetInbox.allKey] == 2)
        #expect(inbox.savedIDs == ["f1"])
        #expect(inbox.actions.count == 3)
    }

    @Test("Fichiers partagés : snapshot relu à l'identique, boîte d'envoi vidée par l'app")
    func store() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetStore(directory: directory)
        #expect(store.readSnapshot() == nil)
        let snapshot = build(try pack())
        store.write(snapshot)
        #expect(store.readSnapshot() == snapshot)
        store.updateInbox { $0.saveToLearn("f1", at: now) }
        #expect(store.readInbox().savedIDs == ["f1"])
        #expect(store.drainInbox().savedIDs == ["f1"])
        #expect(store.readInbox() == WidgetInbox())
    }
}

@Suite("Liens des widgets")
struct WidgetLinkTests {
    @Test("Aller-retour URL", arguments: [WidgetLink.fiche("fr.éminent"), .fiche("fr.au-jour-d-aujourd-hui"), .revision, .serie])
    func roundTrip(link: WidgetLink) {
        #expect(WidgetLink(url: link.url) == link)
    }

    @Test("Liens étrangers ou incomplets ignorés")
    func invalid() {
        #expect(WidgetLink(url: URL(string: "https://fiche/x")!) == nil)
        #expect(WidgetLink(url: URL(string: "sagace://fiche")!) == nil)
        #expect(WidgetLink(url: URL(string: "sagace://inconnu")!) == nil)
    }
}
