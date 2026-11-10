import SagaceCore

/// La préparation coûteuse reste hors du thread d'affichage. L'index des distracteurs est réutilisé par pack.
protocol QuestionPreparing: Sendable {
    func session(_ kind: PracticeSessionViewModel.Kind, seed: UInt64) async -> [Question]
    func challenge(_ kind: ChallengeState.Kind, seed: UInt64, excluding: Set<String>) async -> [Question]
}

actor QuestionPreparation: QuestionPreparing {
    private let content: ContentRepository
    private var cachedFactory: QuestionFactory?

    init(content: ContentRepository) { self.content = content }

    private func factory() -> QuestionFactory {
        if let cachedFactory { return cachedFactory }
        let factory = QuestionFactory(fiches: content.fiches)
        cachedFactory = factory
        return factory
    }

    func session(_ kind: PracticeSessionViewModel.Kind, seed: UInt64) -> [Question] {
        let factory = factory()
        switch kind {
        case .levelTest:
            return factory.levelTest(seed: seed)
        case .session(.game(let game)):
            return factory.questions(for: game, from: content.fiches, count: Rules.sessionLength, seed: seed)
        case .session(.family(let family)):
            let games = [GameType.preferred(for: family)] + GameType.allCases.filter { $0 != .preferred(for: family) }
            return factory.mixed(from: content.fiches(in: family), count: Rules.sessionLength, games: games, seed: seed)
        case .session(.fiches(let ids)):
            return factory.mixed(from: ids.compactMap(content.fiche(id:)), count: Rules.sessionLength, seed: seed)
        case .session(.review(let ids)):
            return factory.review(ids.compactMap(content.fiche(id:)), count: Rules.sessionLength, seed: seed)
        }
    }

    func challenge(_ kind: ChallengeState.Kind, seed: UInt64, excluding: Set<String> = []) -> [Question] {
        // Une petite réserve suffit ; ne jamais préparer les 24 909 questions anglaises à l'ouverture.
        let factory = factory()
        let pool = content.fiches.filter { !excluding.contains($0.id) }
        let questions = factory.mixed(from: pool, count: Rules.sessionLength, games: kind.games, seed: seed)
        // Recommencer un tour seulement après épuisement des fiches utilisables dans ce défi.
        if questions.isEmpty, !excluding.isEmpty {
            return factory.mixed(from: content.fiches, count: Rules.sessionLength, games: kind.games, seed: seed)
        }
        return questions
    }
}
