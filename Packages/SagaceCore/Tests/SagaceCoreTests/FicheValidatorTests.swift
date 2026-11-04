import Testing
@testable import SagaceCore

extension Fiche {
    static func sample(
        id: String = "fr.sample",
        partOfSpeech: PartOfSpeech = .adjectif,
        gender: Gender? = nil,
        phonetic: String = "/sɑ̃.pl/",
        shortDefinition: String = "Une définition courte",
        examples: [String] = ["Un **exemple** ici.", "Un autre **exemple**."],
        synonyms: [String] = [],
        level: Int = 2,
        quiz: [QuizItem] = [QuizItem(game: .sens, prompt: "?", choices: ["a", "b", "c"], answerIndex: 0, explanation: "a")],
        sources: [SourceRef] = [SourceRef(name: "Wiktionnaire", url: "https://fr.wiktionary.org/")],
        authorQuote: AuthorQuote? = nil,
        reviewStatus: ReviewStatus = .autoChecked
    ) -> Fiche {
        Fiche(
            id: id, language: .fr, headword: String(id.dropFirst(3)), family: .nuance, themes: ["travail"],
            partOfSpeech: partOfSpeech, gender: gender, register: .courant, phonetic: phonetic,
            shortDefinition: shortDefinition, definition: "Une définition complète.", confusions: [],
            usage: nil, nuance: nil, examples: examples, authorQuote: authorQuote, synonyms: synonyms,
            etymology: nil, level: level, frequencyRank: nil, quiz: quiz, sources: sources,
            reviewStatus: reviewStatus
        )
    }
}

@Suite("Validation des fiches")
struct FicheValidatorTests {

    private func fields(_ fiche: Fiche) -> Set<String> {
        Set(FicheValidator.validate(fiche).map(\.field))
    }

    @Test func validFicheHasNoIssue() {
        #expect(FicheValidator.validate(Fiche.sample()).isEmpty)
    }

    @Test func idFormat() {
        #expect(fields(.sample(id: "eminent")).contains("id"))
        #expect(fields(.sample(id: "fr.Éminent")).contains("id"))
    }

    @Test func nounRequiresGender() {
        #expect(fields(.sample(partOfSpeech: .nom)).contains("gender"))
        #expect(fields(.sample(partOfSpeech: .nom, gender: .feminin)).isEmpty)
    }

    @Test func phonetic() {
        #expect(fields(.sample(phonetic: "e.mi.nɑ̃")).contains("phonetic"))
    }

    @Test(arguments: ["Fin.", "abc", String(repeating: "a", count: 91)])
    func shortDefinition(_ text: String) {
        #expect(fields(.sample(shortDefinition: text)).contains("shortDefinition"))
    }

    @Test func shortDefinitionAtLimitIsValid() {
        #expect(fields(.sample(shortDefinition: String(repeating: "a", count: 90))).isEmpty)
    }

    @Test func examples() {
        #expect(fields(.sample(examples: ["Un seul **exemple**."])).contains("examples"))
        #expect(fields(.sample(examples: ["Sans mot marqué.", "Un **exemple**."])).contains("examples"))
    }

    @Test func level() {
        #expect(fields(.sample(level: 0)).contains("level"))
        #expect(fields(.sample(level: 6)).contains("level"))
    }

    @Test func quizAnswerIndexOutOfRange() {
        let item = QuizItem(game: .sens, prompt: "?", choices: ["a", "b"], answerIndex: 2, explanation: "")
        #expect(fields(.sample(quiz: [item])).contains("quiz[0]"))
    }

    @Test func quizNeverOffersSynonymAsWrongAnswer() {
        let item = QuizItem(game: .sens, prompt: "?", choices: ["juste", "proche"], answerIndex: 0, explanation: "")
        #expect(fields(.sample(synonyms: ["proche"], quiz: [item])).contains("quiz[0]"))
    }

    @Test func sourcesNeedURL() {
        #expect(fields(.sample(sources: [])).contains("sources"))
        #expect(fields(.sample(sources: [SourceRef(name: "Littré", url: "")])).contains("sources"))
    }

    @Test func authorQuoteMustComeFromWikisource() {
        let quote = AuthorQuote(text: "…", author: "Hugo", work: "Les Misérables", year: 1862, url: "https://example.com")
        #expect(fields(.sample(authorQuote: quote)).contains("authorQuote.url"))
    }

    @Test func duplicatesInPack() {
        let issues = FicheValidator.validate([Fiche.sample(), Fiche.sample()])
        #expect(issues.contains { $0.field == "id" })
        #expect(issues.contains { $0.field == "headword" })
    }
}
