import Foundation
import Testing
@testable import SagaceCore

@Suite("Révisions Leitner et maîtrise")
struct ReviewSchedulerTests {
    let scheduler = ReviewScheduler(day: TestClock.day)

    @Test("À retenir : boîte 1, révision due demain à 4 h")
    func startLearning() {
        let state = scheduler.startLearning(at: TestClock.date(hour: 22))
        #expect(state.box == 1)
        #expect(state.nextReviewAt == TestClock.date(days: 1, hour: 4))
        #expect(!state.isDue(at: TestClock.date(days: 1, hour: 3, minute: 59)))
        #expect(state.isDue(at: TestClock.date(days: 1, hour: 4)))
    }

    @Test("Une bonne réponse fait monter d'une boîte avec l'intervalle 3, 7 puis 21 jours")
    func promotion() {
        var state = scheduler.startLearning(at: TestClock.date())
        var outcomes: [ReviewOutcome] = []
        for _ in 0..<3 {
            let (next, outcome) = scheduler.answer(state, correct: true, at: TestClock.date(days: 1))
            state = next
            outcomes.append(outcome)
        }
        #expect(outcomes == [.promoted(box: 2, nextInDays: 3), .promoted(box: 3, nextInDays: 7), .promoted(box: 4, nextInDays: 21)])
        #expect(state.box == 4)
        #expect(state.nextReviewAt == TestClock.date(days: 22, hour: 4))
    }

    @Test("Une bonne réponse en boîte 4 rend le mot maîtrisé et le sort des révisions")
    func mastery() {
        let now = TestClock.date(days: 30)
        let (state, outcome) = scheduler.answer(ReviewState(box: 4, nextReviewAt: TestClock.date(days: 29)), correct: true, at: now)
        #expect(outcome == .mastered)
        #expect(state == ReviewState(box: 0, nextReviewAt: nil, masteredAt: now))
        #expect(!state.isInReview)
        #expect(!state.isDue(at: TestClock.date(days: 100)))
    }

    @Test("Une mauvaise réponse remet en boîte 1, quelle que soit la boîte", arguments: [1, 2, 3, 4])
    func reset(box: Int) {
        let (state, outcome) = scheduler.answer(ReviewState(box: box), correct: false, at: TestClock.date())
        #expect(outcome == .reset(nextInDays: 1))
        #expect(state.box == 1)
        #expect(state.nextReviewAt == TestClock.date(days: 1, hour: 4))
    }
}

@Suite("Journée Sagace")
struct SagaceDayTests {
    let day = TestClock.day

    @Test("Avant 4 h, on est encore la veille")
    func boundary() {
        #expect(day.day(of: TestClock.date(hour: 3, minute: 59)) == day.day(of: TestClock.date(days: -1, hour: 12)))
        #expect(day.day(of: TestClock.date(hour: 4)) == day.day(of: TestClock.date(hour: 23)))
    }

    @Test func nextBatch() {
        #expect(day.nextBatch(after: TestClock.date(hour: 22)) == TestClock.date(days: 1, hour: 4))
        #expect(day.nextBatch(after: TestClock.date(hour: 2)) == TestClock.date(hour: 4))
    }

    @Test("La semaine va du lundi au dimanche")
    func week() {
        let week = day.week(containing: TestClock.date())
        #expect(week.count == 7)
        #expect(week.first == day.day(of: TestClock.date(days: -2)))
        #expect(week.last == day.day(of: TestClock.date(days: 4)))
    }
}
