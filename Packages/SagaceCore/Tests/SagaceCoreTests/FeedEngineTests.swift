import Foundation
import Testing
@testable import SagaceCore

extension Fiche {
    static func feed(_ id: String, family: Family = .nuance, level: Int = 3, themes: [String] = [], register: Register = .courant) -> Fiche {
        let base = Fiche.sample(id: "fr.\(id)", level: level)
        return Fiche(
            id: base.id, language: .fr, headword: id, family: family, themes: themes, partOfSpeech: base.partOfSpeech,
            gender: base.gender, register: register, phonetic: base.phonetic, shortDefinition: base.shortDefinition,
            definition: base.definition, confusions: [], usage: nil, nuance: nil, examples: base.examples,
            authorQuote: nil, synonyms: [], etymology: nil, level: level, frequencyRank: nil, quiz: base.quiz,
            sources: base.sources, reviewStatus: .autoChecked
        )
    }
}

@Suite("Sélection du feed")
struct FeedEngineTests {
    let engine = FeedEngine(day: TestClock.day)
    let now = TestClock.date()

    @Test("Écarte les fiches triées, masquées et familières selon le réglage")
    func eligibility() {
        let fiches = [
            Fiche.feed("libre"), .feed("triee"), .feed("masquee"), .feed("familiere", register: .familier),
        ]
        let progress = ["fr.triee": FicheProgress(ficheID: "fr.triee", sorting: .known)]
        let profile = FeedProfile(showFamiliar: false, mutedTerms: ["MASQUEE"])
        #expect(engine.eligible(fiches, progress: progress, profile: profile, at: now).map(\.headword) == ["libre"])
    }

    @Test("Une fiche glissée sans tri revient après 7 jours")
    func unsortedComesBack() {
        let fiches = [Fiche.feed("vue")]
        let seen = { (days: Int) in ["fr.vue": FicheProgress(ficheID: "fr.vue", lastSeenAt: TestClock.date(days: -days))] }
        #expect(engine.eligible(fiches, progress: seen(6), profile: FeedProfile(), at: now).isEmpty)
        #expect(engine.eligible(fiches, progress: seen(7), profile: FeedProfile(), at: now).count == 1)
    }

    @Test("Familles et thèmes suivis : tout si aucun, sinon famille ou thème suivi")
    func follows() {
        let fiches = [Fiche.feed("paro", family: .paronyme), .feed("travail", themes: ["travail"]), .feed("autre")]
        #expect(engine.eligible(fiches, progress: [:], profile: FeedProfile(), at: now).count == 3)
        let profile = FeedProfile(followedFamilies: [.paronyme], followedThemes: ["travail"])
        #expect(engine.eligible(fiches, progress: [:], profile: profile, at: now).map(\.headword) == ["paro", "travail"])
    }

    @Test("Le lot reste dans la fenêtre de niveau ±1 et ne la quitte que si elle est épuisée")
    func levelWindow() {
        let fiches = (1...5).map { Fiche.feed("n\($0)", family: Family.allCases[$0], level: $0) }
        let profile = FeedProfile(level: .intermediaire)
        let three = engine.pickNew(3, from: fiches, profile: profile, seed: 1)
        #expect(Set(three.map(\.level)) == [2, 3, 4])
        let four = engine.pickNew(4, from: fiches, profile: profile, seed: 1)
        #expect(four.count == 4)
        #expect(Set(four.map(\.level)).isSuperset(of: [2, 3, 4]))
    }

    @Test("Même graine, même lot ; jamais deux fiches de la même famille d'affilée quand c'est possible")
    func deterministicAndMixed() {
        let fiches = (0..<12).map { Fiche.feed("f\($0)", family: $0 < 6 ? .paronyme : .nuance) }
        let a = engine.pickNew(12, from: fiches, profile: FeedProfile(), seed: 42)
        let b = engine.pickNew(12, from: fiches, profile: FeedProfile(), seed: 42)
        #expect(a == b)
        #expect(a != engine.pickNew(12, from: fiches, profile: FeedProfile(), seed: 43))
        for (first, second) in zip(a, a.dropFirst()) {
            #expect(first.family != second.family)
        }
    }

    @Test func mixKeepsAllFiches() {
        let fiches = [Fiche.feed("a", family: .paronyme), .feed("b", family: .paronyme), .feed("c", family: .nuance)]
        let mixed = FeedEngine.mix(fiches)
        #expect(mixed.map(\.headword) == ["a", "c", "b"])
    }

    @Test("Les objectifs pondèrent les thèmes, familles et niveaux")
    func weights() {
        let travail = Fiche.feed("t", themes: ["travail"])
        #expect(engine.weight(of: travail, goals: []) == 1)
        #expect(engine.weight(of: travail, goals: [.ecrireTravail]) == 1.5)
        #expect(engine.weight(of: .feed("e", family: .impropriete), goals: [.examen]) == 1.5)
        #expect(engine.weight(of: .feed("r", themes: ["relations"]), goals: [.parlerAssurance]) == 1.5)
        #expect(engine.weight(of: .feed("k", level: 2), goals: [.enfants]) == 1.3)
        #expect(engine.weight(of: .feed("k", level: 3), goals: [.enfants]) == 1)
        #expect(engine.weight(of: travail, goals: [.curiosite]) == 1)
    }

    @Test("Le tirage pondéré favorise les fiches des objectifs")
    func weightingBiasesSelection() {
        let fiches = (0..<10).map { Fiche.feed("w\($0)", themes: $0 < 5 ? ["travail"] : []) }
        var travailCount = 0
        for seed in 0..<400 {
            let first = engine.pickNew(1, from: fiches, profile: FeedProfile(goals: [.ecrireTravail]), seed: UInt64(seed))
            if first.first?.themes == ["travail"] { travailCount += 1 }
        }
        // Attendu : 1,5 / 2,5 = 60 %.
        #expect((200...280).contains(travailCount))
    }

    @Test("Gratuit : 2 × objectif par jour ; premium : un lot de plus à chaque fois")
    func allowance() {
        #expect(engine.newFicheAllowance(dailyGoal: 5, isPremium: false, newSeenToday: 0) == 10)
        #expect(engine.newFicheAllowance(dailyGoal: 5, isPremium: false, newSeenToday: 7) == 3)
        #expect(engine.newFicheAllowance(dailyGoal: 5, isPremium: false, newSeenToday: 12) == 0)
        #expect(engine.newFicheAllowance(dailyGoal: 3, isPremium: true, newSeenToday: 40) == 6)
    }

    @Test("Objectif atteint quand les fiches triées du jour atteignent le rythme")
    func goal() {
        #expect(!FeedEngine.isGoalReached(sortedToday: 4, dailyGoal: 5))
        #expect(FeedEngine.isGoalReached(sortedToday: 5, dailyGoal: 5))
        #expect(FeedEngine.isGoalReached(sortedToday: 11, dailyGoal: 10))
    }

    @Test("Révisions dues : la plus ancienne d'abord, jamais les maîtrisées")
    func dueReviews() {
        let progress = [
            FicheProgress(ficheID: "recente", review: ReviewState(box: 1, nextReviewAt: TestClock.date(days: -1))),
            FicheProgress(ficheID: "ancienne", review: ReviewState(box: 2, nextReviewAt: TestClock.date(days: -5))),
            FicheProgress(ficheID: "future", review: ReviewState(box: 1, nextReviewAt: TestClock.date(days: 1))),
            FicheProgress(ficheID: "maitrisee", review: ReviewState(box: 0, masteredAt: TestClock.date(days: -9))),
        ]
        #expect(engine.dueReviews(progress, at: now) == ["ancienne", "recente"])
    }

}

@Suite("Série et objectif")
struct StreakCalculatorTests {
    let calculator = StreakCalculator(day: TestClock.day)

    private func activity(_ offsets: [Int], goal: Set<Int> = []) -> [DayActivity] {
        offsets.map { DayActivity(day: TestClock.day.day(of: TestClock.date(days: $0)), sorted: 1, goalReached: goal.contains($0)) }
    }

    @Test("Série jusqu'à aujourd'hui")
    func streakIncludingToday() {
        #expect(calculator.summary(of: activity([0, -1, -2, -4]), at: TestClock.date()).current == 3)
    }

    @Test("Aujourd'hui pas encore actif : la série court jusqu'à hier")
    func streakUntilYesterday() {
        #expect(calculator.summary(of: activity([-1, -2]), at: TestClock.date()).current == 2)
    }

    @Test("Un jour manqué casse la série")
    func brokenStreak() {
        #expect(calculator.summary(of: activity([-2, -3]), at: TestClock.date()).current == 0)
    }

    @Test("Record et jours parfaits")
    func longestAndPerfect() {
        let summary = calculator.summary(of: activity([0, -5, -6, -7, -8], goal: [-5, -6]), at: TestClock.date())
        #expect(summary.current == 1)
        #expect(summary.longest == 4)
        #expect(summary.perfectDays == 2)
    }

    @Test("Un jour sans tri, révision ni session n'est pas actif")
    func inactiveDay() {
        let empty = [DayActivity(day: TestClock.day.day(of: TestClock.date()))]
        #expect(calculator.summary(of: empty, at: TestClock.date()).current == 0)
        let review = [DayActivity(day: TestClock.day.day(of: TestClock.date()), reviewsDone: 1)]
        #expect(calculator.summary(of: review, at: TestClock.date()).current == 1)
    }

    @Test("Activité à 1 h du matin : compte pour la veille")
    func lateNightCountsForPreviousDay() {
        let late = [DayActivity(day: TestClock.day.day(of: TestClock.date(hour: 1)), sorted: 1)]
        #expect(calculator.summary(of: late, at: TestClock.date(days: -1, hour: 20)).current == 1)
    }

    @Test("Rappel du soir si rien aujourd'hui et série d'au moins 2 jours")
    func eveningReminder() {
        #expect(calculator.needsEveningReminder(activity([-1, -2]), at: TestClock.date(hour: 20)))
        #expect(!calculator.needsEveningReminder(activity([-1]), at: TestClock.date(hour: 20)))
        #expect(!calculator.needsEveningReminder(activity([0, -1, -2]), at: TestClock.date(hour: 20)))
    }
}
