import Foundation

/// État d'un défi (PRA-04 à 06) : Rush, Sprint, Perfection. Pur : l'horloge est fournie par `tick`.
public struct ChallengeState: Equatable, Sendable {
    public enum Kind: Sendable, CaseIterable {
        /// 5 s par question, 3 vies ; erreur ou temps écoulé = une vie.
        case rush
        /// 60 s au total, pas de vies ; score = bonnes réponses.
        case sprint
        /// Sans limite de temps, fin à la première erreur ; score = série.
        case perfection
    }

    public enum EndReason: Equatable, Sendable { case noLivesLeft, timeUp, firstMistake }

    /// Ce qui vient de se passer, pour l'haptique et l'affichage.
    public enum Event: Equatable, Sendable { case correct, wrong, lostLife, timedOut, ended(EndReason) }

    public let kind: Kind
    public private(set) var lives: Int
    public private(set) var answered = 0
    public private(set) var correct = 0
    /// Rush : temps restant sur la question. Sprint : temps restant au total. Perfection : sans objet.
    public private(set) var remaining: TimeInterval
    public private(set) var endReason: EndReason?

    public init(kind: Kind) {
        self.kind = kind
        self.lives = kind == .rush ? Rules.rushLives : 0
        self.remaining = switch kind {
        case .rush: Rules.rushSecondsPerQuestion
        case .sprint: Rules.sprintDuration
        case .perfection: .infinity
        }
    }

    public var isOver: Bool { endReason != nil }

    /// Score affiché : bonnes réponses (Rush, Sprint) ou série (Perfection, égale aux bonnes réponses).
    public var score: Int { correct }

    /// Part du temps restant, pour la barre de temps.
    public var timeFraction: Double {
        switch kind {
        case .rush: max(0, remaining / Rules.rushSecondsPerQuestion)
        case .sprint: max(0, remaining / Rules.sprintDuration)
        case .perfection: 1
        }
    }

    public mutating func answer(correct isCorrect: Bool) -> [Event] {
        guard !isOver else { return [] }
        answered += 1
        if isCorrect {
            correct += 1
            if kind == .rush { remaining = Rules.rushSecondsPerQuestion }
            return [.correct]
        }
        switch kind {
        case .rush:
            return [.wrong] + loseLife()
        case .sprint:
            return [.wrong]
        case .perfection:
            endReason = .firstMistake
            return [.wrong, .ended(.firstMistake)]
        }
    }

    /// Fait avancer l'horloge. Rush : une question sans réponse au bout de 5 s coûte une vie.
    public mutating func tick(_ elapsed: TimeInterval) -> [Event] {
        guard !isOver, kind != .perfection else { return [] }
        remaining -= elapsed
        guard remaining <= 0 else { return [] }
        switch kind {
        case .rush:
            answered += 1
            return [.timedOut] + loseLife()
        case .sprint:
            remaining = 0
            endReason = .timeUp
            return [.ended(.timeUp)]
        case .perfection:
            return []
        }
    }

    private mutating func loseLife() -> [Event] {
        lives -= 1
        if lives <= 0 {
            endReason = .noLivesLeft
            return [.lostLife, .ended(.noLivesLeft)]
        }
        remaining = Rules.rushSecondsPerQuestion
        return [.lostLife]
    }
}

public extension ChallengeState.Kind {
    var mode: PracticeMode {
        switch self {
        case .rush: .rush
        case .sprint: .sprint
        case .perfection: .perfection
        }
    }

    /// Rush : Le mot juste ou Paronymes. Sprint et Perfection : tous les jeux.
    var games: [GameType] {
        switch self {
        case .rush: [.motJuste, .paronymes]
        case .sprint, .perfection: GameType.allCases
        }
    }
}
