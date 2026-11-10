import Foundation

/// Fabrique les questions (`03_ARCHITECTURE.md` section 7, Questions). Priorité aux quiz écrits dans la fiche,
/// sinon génération à partir des champs de la fiche. Les mauvaises réponses ont la même nature (et le même genre
/// pour un nom) que la bonne, ne sont jamais un synonyme listé, et sont choisies parmi les plus proches de la bonne
/// réponse par la forme ou par le sens (`Proximity`) : jamais triviales, sans être aussi fines qu'un Juste ou fautif.
/// Déterministe à graine égale.
public struct QuestionFactory: Sendable {
    /// Une mauvaise réponse possible : le mot d'une fiche, ou un paronyme listé dans une fiche.
    struct Decoy: Sendable {
        let word: String
        let normalizedWord: String
        let core: [Character]
        let definition: String
        let keywords: Set<String>
        let ownerID: String
        let isConfusion: Bool
        let partOfSpeech: PartOfSpeech
        let gender: Gender?
        let themes: Set<String>
    }

    private let fiches: [Fiche]
    private let decoys: [Decoy]
    private let closeWordsByOwner: [String: Set<String>]

    /// - Parameter fiches: tout le pack visible, réservoir des mauvaises réponses.
    public init(fiches: [Fiche]) {
        self.fiches = fiches
        self.closeWordsByOwner = Dictionary(uniqueKeysWithValues: fiches.map { fiche in
            let close = fiche.synonyms + fiche.confusions.filter { !Self.isParonym($0.word, of: fiche) }.map(\.word)
            return (fiche.id, Set(close.map(SearchIndex.normalize)))
        })
        self.decoys = fiches.flatMap { fiche in
            let own = Decoy(
                word: fiche.headword, normalizedWord: SearchIndex.normalize(fiche.headword), core: Array(Proximity.core(fiche.headword)), definition: fiche.shortDefinition,
                keywords: Self.keywords(of: fiche), ownerID: fiche.id, isConfusion: false,
                partOfSpeech: fiche.partOfSpeech, gender: fiche.gender, themes: Set(fiche.themes)
            )
            // Un paronyme (forme proche, sens bien distinct) fait une bonne mauvaise réponse. Son genre n'est pas
            // connu : pas de paronyme d'un nom, pour ne pas trahir la réponse par l'article.
            let paronyms = fiche.partOfSpeech == .nom ? [] : fiche.confusions.filter { Self.isParonym($0.word, of: fiche) }.map { confusion in
                Decoy(
                    word: confusion.word, normalizedWord: SearchIndex.normalize(confusion.word), core: Array(Proximity.core(confusion.word)), definition: Self.capitalized(confusion.meaning), keywords: Proximity.keywords(confusion.meaning),
                    ownerID: fiche.id, isConfusion: true, partOfSpeech: fiche.partOfSpeech, gender: nil, themes: Set(fiche.themes)
                )
            }
            return [own] + paronyms
        }
    }

    static func keywords(of fiche: Fiche) -> Set<String> {
        Proximity.keywords(([fiche.shortDefinition, fiche.definition] + fiche.synonyms).joined(separator: " "))
    }

    /// Confusion de forme (paronyme) et non de sens : "imminent" pour "éminent", pas "se souvenir" pour "se rappeler".
    static func isParonym(_ word: String, of fiche: Fiche) -> Bool {
        Proximity.form(word, fiche.headword) >= Rules.paronymFormThreshold
    }

    private static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }

    /// Tout le pack connu de la fabrique.
    public var allFiches: [Fiche] { fiches }

    // MARK: Sessions

    /// Une session d'un jeu : jusqu'à `count` questions, une par fiche, quiz écrits d'abord.
    public func questions(for game: GameType, from pool: [Fiche], count: Int, seed: UInt64) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        let shuffled = pool.shuffled(using: &rng)
        let withQuiz = shuffled.filter { $0.quiz.contains { $0.game == game } }
        let quizIDs = Set(withQuiz.map(\.id))
        let others = shuffled.filter { !quizIDs.contains($0.id) }
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
    /// - Parameter excluding: jeux à écarter (le widget de révision n'affiche que des questions à choix).
    public func review(_ pool: [Fiche], count: Int, seed: UInt64, excluding: Set<GameType> = []) -> [Question] {
        var rng = SeededGenerator(seed: seed)
        return pool.shuffled(using: &rng).prefix(count).compactMap { fiche in
            let games = ([GameType.preferred(for: fiche.family)] + GameType.allCases).filter { !excluding.contains($0) }
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

    /// Mauvaises réponses possibles, les plus proches d'abord : les paronymes de la fiche, puis un tirage parmi
    /// les plus proches par la forme ou le sens. Même nature, même genre si nom, aucun lien de synonymie, et jamais
    /// une confusion de sens de la fiche (trop proche : c'est le terrain du Juste ou fautif).
    func rankedDecoys(for fiche: Fiche, rng: inout SeededGenerator) -> [Decoy] {
        let headword = SearchIndex.normalize(fiche.headword)
        let synonyms = Set(fiche.synonyms.map(SearchIndex.normalize))
        let closeMeanings = Set(fiche.confusions.filter { !Self.isParonym($0.word, of: fiche) }.map { SearchIndex.normalize($0.word) })
        let targetCore = Array(Proximity.core(fiche.headword))
        let keywords = Self.keywords(of: fiche)
        let themes = Set(fiche.themes)
        let candidates = decoys.filter { decoy in
            let word = decoy.normalizedWord
            // La fiche d'origine ne doit pas tenir ce mot pour un synonyme ni pour une confusion de sens.
            let ownerIsClose = closeWordsByOwner[decoy.ownerID]?.contains(headword) == true
            return word != headword
                && !ownerIsClose
                && (decoy.ownerID != fiche.id || decoy.isConfusion)
                && decoy.partOfSpeech == fiche.partOfSpeech
                && (fiche.partOfSpeech != .nom || decoy.gender == fiche.gender)
                && !synonyms.contains(word)
                && !closeMeanings.contains(word)
        }
        let scored = candidates.map { decoy in
            // Forme au carré : sur des mots courts, deux lettres communes suffisent à une ressemblance de hasard.
            let shape = Proximity.form(decoy.core, targetCore)
            let closeness = max(shape * shape, Proximity.meaning(decoy.keywords, keywords))
            return (decoy, closeness + (decoy.themes.isDisjoint(with: themes) ? 0 : Rules.proximityThemeBonus))
        }
        .sorted { ($1.1, $0.0.word) < ($0.1, $1.0.word) }
        .map(\.0)
        let own = scored.filter { $0.ownerID == fiche.id }
        let others = scored.filter { $0.ownerID != fiche.id }
        let shortlist = others.prefix(Rules.decoyShortlist).shuffled(using: &rng)
        return own + shortlist + Array(others.dropFirst(Rules.decoyShortlist))
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
            wrong = confusions + rankedDecoys(for: fiche, rng: &rng).map(\.word)
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
        let wrong = rankedDecoys(for: fiche, rng: &rng).map(\.word)
        guard let (choices, index) = makeChoices(correct: fiche.headword, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .passePartout, "verb"), ficheID: fiche.id, game: .passePartout, prompt: usage.avoid,
                        choices: choices, correct: .choice(index), explanation: "\(usage.correct). \(usage.explanation)")
    }

    /// Sens : le mot, trois définitions courtes.
    private func meaning(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        let wrong = rankedDecoys(for: fiche, rng: &rng).map(\.definition)
        guard let (choices, index) = makeChoices(correct: fiche.shortDefinition, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .sens, "def"), ficheID: fiche.id, game: .sens, prompt: fiche.headword,
                        choices: choices, correct: .choice(index), explanation: fiche.definition)
    }

    /// Devine le mot : la définition courte, trois mots.
    private func guessWord(_ fiche: Fiche, rng: inout SeededGenerator) -> Question? {
        let wrong = rankedDecoys(for: fiche, rng: &rng).map(\.word)
        guard let (choices, index) = makeChoices(correct: fiche.headword, wrong: wrong, count: Rules.defaultChoiceCount, rng: &rng) else { return nil }
        return Question(id: id(fiche, .devine, "word"), ficheID: fiche.id, game: .devine, prompt: fiche.shortDefinition,
                        choices: choices, correct: .choice(index), explanation: fiche.definition)
    }

    private func boldWord(in example: String) -> String? {
        guard let match = example.firstMatch(of: /\*\*(.+?)\*\*/) else { return nil }
        return String(match.1)
    }
}
