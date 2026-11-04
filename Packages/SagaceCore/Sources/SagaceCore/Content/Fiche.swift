import Foundation

/// Une fiche du pack de contenu, en lecture seule.
/// Format de référence : `content/schema/fiche.schema.json`.
public struct Fiche: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let language: Language
    public let headword: String
    public let family: Family
    public let themes: [String]
    public let partOfSpeech: PartOfSpeech
    public let gender: Gender?
    public let register: Register
    public let phonetic: String
    public let shortDefinition: String
    public let definition: String
    public let confusions: [Confusion]
    public let usage: UsageNote?
    public let nuance: String?
    public let examples: [String]
    public let authorQuote: AuthorQuote?
    public let synonyms: [String]
    public let etymology: String?
    public let level: Int
    public let frequencyRank: Int?
    public let quiz: [QuizItem]
    public let sources: [SourceRef]
    public let reviewStatus: ReviewStatus

    public init(
        id: String, language: Language, headword: String, family: Family, themes: [String],
        partOfSpeech: PartOfSpeech, gender: Gender?, register: Register, phonetic: String,
        shortDefinition: String, definition: String, confusions: [Confusion], usage: UsageNote?,
        nuance: String?, examples: [String], authorQuote: AuthorQuote?, synonyms: [String],
        etymology: String?, level: Int, frequencyRank: Int?, quiz: [QuizItem], sources: [SourceRef],
        reviewStatus: ReviewStatus
    ) {
        self.id = id; self.language = language; self.headword = headword; self.family = family
        self.themes = themes; self.partOfSpeech = partOfSpeech; self.gender = gender
        self.register = register; self.phonetic = phonetic; self.shortDefinition = shortDefinition
        self.definition = definition; self.confusions = confusions; self.usage = usage
        self.nuance = nuance; self.examples = examples; self.authorQuote = authorQuote
        self.synonyms = synonyms; self.etymology = etymology; self.level = level
        self.frequencyRank = frequencyRank; self.quiz = quiz; self.sources = sources
        self.reviewStatus = reviewStatus
    }

    /// Niveau typé (1 à 5). `nil` si la valeur du pack est hors bornes (la validation le signale).
    public var difficulty: Level? { Level(rawValue: level) }

    /// Visible en production : seules les fiches contrôlées sont montrées.
    public var isPublishable: Bool { reviewStatus != .draft }
}

public enum Language: String, Codable, Sendable, CaseIterable {
    case fr, en
}

public enum Family: String, Codable, Sendable, CaseIterable {
    case paronyme, impropriete, passePartout, nuance, pleonasme, anglicisme, motMalCompris, expression
}

public enum PartOfSpeech: String, Codable, Sendable, CaseIterable {
    case nom, verbe, adjectif, adverbe, locution, preposition
}

public enum Gender: String, Codable, Sendable, CaseIterable {
    case masculin, feminin, epicene
}

public enum Register: String, Codable, Sendable, CaseIterable {
    case courant, soutenu, familier, litteraire
}

public enum ReviewStatus: String, Codable, Sendable, CaseIterable {
    case draft, autoChecked, humanChecked
}

public struct Confusion: Codable, Hashable, Sendable {
    public let word: String
    public let meaning: String
    public let example: String

    public init(word: String, meaning: String, example: String) {
        self.word = word; self.meaning = meaning; self.example = example
    }
}

public struct UsageNote: Codable, Hashable, Sendable {
    public enum Verdict: String, Codable, Sendable, CaseIterable {
        case fautif, critique, tolere
    }

    public let correct: String
    public let avoid: String
    public let verdict: Verdict
    public let explanation: String

    public init(correct: String, avoid: String, verdict: Verdict, explanation: String) {
        self.correct = correct; self.avoid = avoid; self.verdict = verdict; self.explanation = explanation
    }
}

public struct AuthorQuote: Codable, Hashable, Sendable {
    public let text: String
    public let author: String
    public let work: String
    public let year: Int
    public let url: String

    public init(text: String, author: String, work: String, year: Int, url: String) {
        self.text = text; self.author = author; self.work = work; self.year = year; self.url = url
    }
}

public enum GameType: String, Codable, Sendable, CaseIterable {
    case motJuste, paronymes, justeOuFautif, passePartout, sens, devine
}

public struct QuizItem: Codable, Hashable, Sendable {
    public let game: GameType
    public let prompt: String
    public let choices: [String]
    public let answerIndex: Int
    public let explanation: String

    public init(game: GameType, prompt: String, choices: [String], answerIndex: Int, explanation: String) {
        self.game = game; self.prompt = prompt; self.choices = choices
        self.answerIndex = answerIndex; self.explanation = explanation
    }
}

public struct SourceRef: Codable, Hashable, Sendable {
    public let name: String
    public let url: String

    public init(name: String, url: String) {
        self.name = name; self.url = url
    }
}
