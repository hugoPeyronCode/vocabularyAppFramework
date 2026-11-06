import Testing
@testable import SagaceCore

@Suite("Règles chiffrées")
struct RulesTests {

    @Test(arguments: [
        (0, Level.debutant), (6, .debutant), (7, .elementaire), (12, .elementaire),
        (13, .intermediaire), (18, .intermediaire), (19, .avance), (24, .avance),
        (25, .expert), (30, .expert),
    ])
    func levelTestThresholds(score: Int, expected: Level) {
        #expect(Rules.level(forLevelTestScore: score) == expected)
    }

    @Test func pointsToNextLevel() {
        #expect(Rules.pointsToNextLevel(forLevelTestScore: 16) == 3)
        #expect(Rules.pointsToNextLevel(forLevelTestScore: 0) == 7)
        #expect(Rules.pointsToNextLevel(forLevelTestScore: 24) == 1)
        #expect(Rules.pointsToNextLevel(forLevelTestScore: 25) == nil)
    }

    @Test(arguments: [(0, Level.debutant), (2, .debutant), (3, .intermediaire), (4, .avance), (5, .expert)])
    func miniTest(score: Int, expected: Level) {
        #expect(Rules.level(forMiniTestScore: score) == expected)
    }

    @Test func levelTestLength() {
        #expect(Rules.levelTestLength == 30)
    }

    @Test func leitnerIntervals() {
        #expect(Rules.reviewIntervalDays(forBox: 1) == 1)
        #expect(Rules.reviewIntervalDays(forBox: 2) == 3)
        #expect(Rules.reviewIntervalDays(forBox: 3) == 7)
        #expect(Rules.reviewIntervalDays(forBox: 4) == 21)
        #expect(Rules.reviewIntervalDays(forBox: 0) == nil)
        #expect(Rules.reviewIntervalDays(forBox: Rules.maxBox + 1) == nil)
    }

    @Test("Les achats de Words v3 restent premium")
    func legacyProductsArePremium() {
        #expect(Rules.premiumProductIDs.isSuperset(of: ["Yearly", "weekly", "lifetime"]))
    }

    @Test func dailyGoal() {
        #expect(Rules.dailyGoalOptions == [3, 5, 10])
        #expect(Rules.dailyGoalOptions.contains(Rules.defaultDailyGoal))
    }
}
