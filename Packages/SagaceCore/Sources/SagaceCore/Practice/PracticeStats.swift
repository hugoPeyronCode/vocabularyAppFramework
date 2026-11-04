import Foundation

/// Une réponse enregistrée, pour les statistiques.
public struct AnswerRecord: Equatable, Sendable {
    public let game: GameType
    public let isCorrect: Bool
    public let answeredAt: Date

    public init(game: GameType, isCorrect: Bool, answeredAt: Date) {
        self.game = game; self.isCorrect = isCorrect; self.answeredAt = answeredAt
    }
}

public struct SkillAccuracy: Equatable, Sendable {
    public let skill: Skill
    public let correct: Int
    public let total: Int

    /// Précision en pourcentage, `nil` tant qu'il y a moins de 10 réponses.
    public var percent: Double? {
        total >= Rules.statsMinAnswers ? Double(correct) / Double(total) * 100 : nil
    }
}

/// Précision par compétence sur 14 jours et compétence suggérée (`03_ARCHITECTURE.md` section 7, Stats).
public struct PracticeStats: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    public func accuracy(_ answers: [AnswerRecord], at now: Date) -> [Skill: SkillAccuracy] {
        let since = day.adding(days: -(Rules.statsWindowDays - 1), to: day.day(of: now))
        let recent = answers.filter { day.day(of: $0.answeredAt) >= since }
        return Dictionary(uniqueKeysWithValues: Skill.allCases.map { skill in
            let forSkill = recent.filter { $0.game.skill == skill }
            return (skill, SkillAccuracy(skill: skill, correct: forSkill.filter(\.isCorrect).count, total: forSkill.count))
        })
    }

    /// La compétence la plus faible, si elle a plus de 10 points de retard sur la moyenne des deux autres.
    public func suggestedSkill(_ accuracy: [Skill: SkillAccuracy]) -> Skill? {
        let percents = Skill.allCases.compactMap { skill in accuracy[skill]?.percent.map { (skill, $0) } }
        guard percents.count == Skill.allCases.count, let weakest = percents.min(by: { $0.1 < $1.1 }) else { return nil }
        let others = percents.filter { $0.0 != weakest.0 }.map(\.1)
        let average = others.reduce(0, +) / Double(others.count)
        return average - weakest.1 > Rules.weakSkillGap ? weakest.0 : nil
    }

    /// Gratuit : une session de jeu par jour, défis compris.
    public static func canStartGame(isPremium: Bool, gameSessionsToday: Int) -> Bool {
        isPremium || gameSessionsToday < Rules.freeSessionsPerDay
    }
}

public extension PracticeMode {
    /// Session de jeu ou défi, soumise à la limite gratuite (le test et les révisions ne le sont pas).
    var countsAsGameSession: Bool { self != .levelTest && self != .review }

    var game: GameType? { GameType(rawValue: rawValue) }
}
