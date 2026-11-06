/// Une question de jeu, de défi, de test ou de révision.
public struct Question: Identifiable, Hashable, Sendable {
    /// Réponse attendue ou donnée.
    public enum Answer: Hashable, Sendable {
        /// Index dans `choices`.
        case choice(Int)
        /// "Juste ou fautif" : `true` = la phrase est juste.
        case trueFalse(Bool)
    }

    public let id: String
    public let ficheID: String
    public let game: GameType
    public let prompt: String
    /// Choix proposés (vide pour "Juste ou fautif").
    public let choices: [String]
    public let correct: Answer
    /// Règle rappelée après la réponse.
    public let explanation: String
    /// "Juste ou fautif" : la tournure juste, montrée si l'utilisateur se trompe.
    public let correction: String?

    public init(id: String, ficheID: String, game: GameType, prompt: String, choices: [String], correct: Answer,
                explanation: String, correction: String? = nil) {
        self.id = id; self.ficheID = ficheID; self.game = game; self.prompt = prompt; self.choices = choices
        self.correct = correct; self.explanation = explanation; self.correction = correction
    }

    public var skill: Skill { game.skill }

    public func isCorrect(_ answer: Answer) -> Bool { answer == correct }

    /// Texte de la bonne réponse ("Pas tout à fait : la bonne réponse est…").
    public var correctChoice: String? {
        if case .choice(let index) = correct, choices.indices.contains(index) { return choices[index] }
        return correction
    }

    /// Contrôles structurels : une seule bonne réponse, choix uniques, nombre de choix selon le jeu.
    public var isWellFormed: Bool {
        switch correct {
        case .trueFalse:
            return game == .justeOuFautif && choices.isEmpty
        case .choice(let index):
            guard choices.indices.contains(index), Set(choices.map(SearchIndex.normalize)).count == choices.count else { return false }
            return game == .paronymes ? (2...3).contains(choices.count) : choices.count == Rules.defaultChoiceCount
        }
    }
}

public extension GameType {
    /// Compétence mesurée (`03_ARCHITECTURE.md` section 7) : Sens · Usage · Choix du mot.
    var skill: Skill {
        switch self {
        case .sens, .devine: .sens
        case .justeOuFautif, .paronymes: .usage
        case .motJuste, .passePartout: .choixDuMot
        }
    }

    /// Jeu adapté à une famille, pour les révisions et les sessions "par famille".
    static func preferred(for family: Family) -> GameType {
        switch family {
        case .paronyme: .paronymes
        case .impropriete, .pleonasme, .anglicisme: .justeOuFautif
        case .passePartout: .passePartout
        case .nuance: .motJuste
        case .motMalCompris, .expression: .sens
        }
    }
}

public extension Skill {
    /// Jeux qui mesurent la compétence, le premier étant suggéré.
    var games: [GameType] {
        switch self {
        case .sens: [.sens, .devine]
        case .usage: [.justeOuFautif, .paronymes]
        case .choixDuMot: [.motJuste, .passePartout]
        }
    }
}
