import Foundation

/// Fabrique les questions (`03_ARCHITECTURE.md` section 7, Questions). Priorité aux quiz écrits dans la fiche,
/// sinon génération à partir des champs de la fiche. Les mauvaises réponses ont la même nature (et le même genre
/// pour un nom) que la bonne, et ne sont jamais un synonyme listé. Déterministe à graine égale.
public struct QuestionFactory: Sendable {
    private let fiches: [Fiche]

    /// - Parameter fiches: tout le pack visible, réservoir des mauvaises réponses.
    public init(fiches: [Fiche]) {
        self.fiches = fiches
    }

    // MARK: Sessions

    /// Une session d'un jeu : jusqu'à `count` questions, une par fiche, quiz écrits d'abord.
    public func questions(for game: GameType, from pool: [Fiche], count: Int, seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        let shuffled = pool.shuffled(using: &rng)
        let withQuiz = shuffled.filter { $0.quiz.contains { $0.game == game } }
        let others = shuffled.filter { fiche in !withQuiz.contains { $0.id == fiche.id } }
        var result: [Question] = []
        for fiche in withQuiz + others where result.count < count {
            if let question = question(for: fiche, game: game, rng: &rng) { result.append(question) }
        }
        return result
    }

    /// Session mêlant plusieurs jeux (défis Sprint et Perfection, test) : le jeu change à chaque question.
    public func mixed(from pool: [Fiche], count: Int, games: [GameType] = GameType.allCases, seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        var result: [Question] = []
        var gameIndex = Int(rng.next() % UInt64(games.count))
        for fiche in pool.shuffled(using: &rng) where result.count < count {
            for offset in 0..<games.count {
                let game = games[(gameIndex + offset) % games.count]
                if let question = question(for: fiche, game: game, rng: &rng) {
                    result.append(question)
                    gameIndex += 1
                    break
                }
            }
        }
        return result
    }

    /// Révision de fiches données (LIB-01 "Réviser maintenant"), dans le jeu adapté à chaque famille.
    public func review(_ pool: [Fiche], count: Int, seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        return pool.shuffled(using: &rng).prefix(count).compactMap { fiche in
            let games = [GameType.preferred(for: fiche.family)] + GameType.allCases
            for game in games {
                if let question = question(for: fiche, game: game, rng: &rng) { return question }
            }
            return nil
        }
    }

    /// Test de précision : 6 questions par niveau (1 à 5), toutes familles. Un niveau sans assez de fiches
    /// est complété par les niveaux voisins les plus proches.
    public func levelTest(seed: UInt64) -> [Question] {
        var used = Set<String>()
        var result: [Question] = []
        for level in Level.allCases {
            let byDistance = fiches
                .filter { !used.contains($0.id) }
                .sorted { abs($0.level - level.rawValue) < abs($1.level - level.rawValue) }
            let nearest = byDistance.prefix { abs($0.level - level.rawValue) <= abs((byDistance.first?.level ?? 0) - level.rawValue) }
            var pool = Array(nearest)
            if pool.count < Rules.levelTestQuestionsPerLevel { pool = byDistance }
            let questions = mixed(from: pool, count: Rules.levelTestQuestionsPerLevel, seed: seed &+ UInt64(level.rawValue))
            used.formUnion(questions.map(\.ficheID))
            result += questions
        }
        return result
    }

    // MARK: Une question

    public func question(for fiche: Fiche, game: GameType, rng: inout SeededGenerator) -> Question? {
        if let quiz = fiche.quiz.first(where: { $0.game == game }), let question = fromQuiz(quiz, fiche: fiche, rng: &rng) {
            return question
        }
        let generated: Question? = switch game {
        case .motJuste: blank(fiche, game: .motJuste, rng: &rng)
        case .paronymes: blank(fiche, game: .paronymes, rng: &rng)
        case .justeOuFautif: trueOrFalse(fiche, rng: &rng)
        case .passePartout: preciseVerb(fiche, rng: &rng)
        case .sens: meaning(fiche, rng: &rng)
        case .devine: guessWord(fiche, rng: &rng)
        }
        return generated?.isWellFormed == true ? generated : nil
    }

    private func id(_ fiche: Fiche, _ game: GameType, _ suffix: String) -> String { "\(fiche.id)#\(game.rawValue)#\(suffix)" }

    private func fromQuiz(_ quiz: QuizItem, fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        if quiz.game == .justeOuFautif {
            return Question(
                id: id(fiche, .justeOuFautif, "quiz"), ficheID: fiche.id, game: .justeOuFautif, prompt: quiz.prompt,
                choices: [], correct: .trueFalse(quiz.answerIndex == 0), explanation: quiz.explanation,
                correction: fiche.usage?.correct
            )
        }
        let correctText = quiz.choices[quiz.answerIndex]
        let choices = quiz.choices.shuffled(using: &rng)
        guard let index = choices.firstIndex(of: correctText) else { return nil }
        let question = Question(
            id: id(fiche, quiz.game, "quiz"), ficheID: fiche.id, game: quiz.game, prompt: quiz.prompt,
            choices: choices, correct: .choice(index), explanation: quiz.explanation
        )
        return question.isWellFormed ? question : nil
    }

    // MARK: Génération

    /// Fiches qui peuvent fournir une mauvaise réponse : même nature, même genre si nom, aucun lien de synonymie.
    private func distractors(for fiche: Fiche, sameFamilyFirst: Bool = true) -> [Fiche] {
        let synonyms = Set(fiche.synonyms.map(SearchIndex.normalize))
        let headword = SearchIndex.normalize(fiche.headword)
        let candidates = fiches.filter { other in
            other.id != fiche.id
                && other.partOfSpeech == fiche.partOfSpeech
                && (fiche.partOfSpeech != .nom || other.gender == fiche.gender)
                && !synonyms.contains(SearchIndex.normalize(other.headword))
                && !other.synonyms.map(SearchIndex.normalize).contains(headword)
                && SearchIndex.normalize(other.headword) != headword
        }
        guard sameFamilyFirst else { return candidates }
        return candidates.filter { $0.family == fiche.family } + candidates.filter { $0.family != fiche.family }
    }

    private func makeChoices(correct: String, wrong: [String], count: Int, rng: inout SeededGenerator) -> (choices: [String], index: Int)? {
        var seen: Set<String> = [SearchIndex.normalize(correct)]
        var picked: [String] = []
        for candidate in wrong where picked.count < count - 1 {
            if seen.insert(SearchIndex.normalize(candidate)).inserted { picked.append(candidate) }
        }
        guard picked.count == count - 1 else { return nil }
        let choices = ([correct] + picked).shuffled(using: &rng)
        return (choices, choices.firstIndex(of: correct)!)
    }

    /// Le mot juste, Paronymes : une phrase d'exemple avec le mot en blanc. Seulement si la forme en gras
    /// est le mot lui-même (une forme fléchie trahirait la bonne réponse).
    private func blank(_ fiche: Fiche, game: GameType, rng: inout SeededGenerator) -> Question? {
        guard let example = fiche.examples.first(where: { boldWord(in: $0).map { SearchIndex.normalize($0) == SearchIndex.normalize(fiche.headword) } ?? false }),
              let bold = boldWord(in: example) else { return nil }
        let prompt = example.replacingOccurrences(of: "**\(bold)**", with: "___")
        let synonyms = Set(fiche.synonyms.map(SearchIndex.normalize))
        let confusions = fiche.confusions.map(\.word).filter { !synonyms.contains(SearchIndex.normalize($0)) }
        let wrong: [String]
        let count: Int
        if game == .paronymes {
            guard !confusions.isEmpty else { return nil }
            wrong = confusions
            count = min(confusions.count + 1, 3)
        } else {
            wrong = confusions + distractors(for: fiche).map(\.headword)
            count = Rules.defaultChoiceCount
        }
        guard let (choices, index) = makeChoices(correct: bold, wrong: wrong, count: count, rng: &rng) else { return nil }
        return Question(id: id(fiche, game, "blank"), ficheID: fiche.id, game: game, prompt: prompt,
                        choices: choices, correct: .choice(index), explanation: fiche.shortDefinition)
    }

    /// Juste ou fautif : la tournure juste ou la tournure à éviter, à pile ou face.
    private func trueOrFalse(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        guard let usage = fiche.usage else { return nil }
        let showsCorrect = Bool.random(using: &rng)
        return Question(
            id: id(fiche, .justeOuFautif, "usage"), ficheID: fiche.id, game: .justeOuFautif,
            prompt: "« \(showsCorrect ? usage.correct : usage.avoid) »", choices: [], correct: .trueFalse(showsCorrect),
            explanation: usage.explanation, correction: usage.correct
        )
    }

    /// Passe partout : la tournure vague, le verbe précis contre deux autres verbes.
    private func preciseVerb(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        guard fiche.family == .passePartout, fiche.partOfSpeech == .verbe, let usage = fiche.usage else { return nil }
        let wrong = distractors(for: fiche).map(\.headword)
        guard let (choices, index) = makeChoices(correct: fiche.headword, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .passePartout, "verb"), ficheID: fiche.id, game: .passePartout, prompt: usage.avoid,
                        choices: choices, correct: .choice(index), explanation: "\(usage.correct). \(usage.explanation)")
    }

    /// Sens : le mot, trois définitions courtes.
    private func meaning(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        let wrong = distractors(for: fiche, sameFamilyFirst: false).map(\.shortDefinition).shuffled(using: &rng)
        guard let (choices, index) = makeChoices(correct: fiche.shortDefinition, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .sens, "def"), ficheID: fiche.id, game: .sens, prompt: fiche.headword,
                        choices: choices, correct: .choice(index), explanation: fiche.definition)
    }

    /// Devine le mot : la définition courte, trois mots.
    private func guessWord(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        let wrong = distractors(for: fiche).map(\.headword)
        guard let (choices, index) = makeChoices(correct: fiche.headword, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .devine, "word"), ficheID: fiche.id, game: .devine, prompt: fiche.shortDefinition,
                        choices: choices, correct: .choice(index), explanation: fiche.definition)
    }

    private func boldWord(in example: String) -> String? {
        guard let match = example.firstMatch(of: /\*\*(.+?)\*\*/) else { return nil }
        return String(match.1)
    }
}
