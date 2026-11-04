import Foundation
import Testing
@testable import SagaceCore

extension Fiche {
    /// Fiche de test complète pour la génération de questions.
    static func word(
        _ headword: String, family: Family = .nuance, pos: PartOfSpeech = .verbe, gender: Gender? = nil, level: Int = 3,
        example: String? = nil, confusions: [String] = [], synonyms: [String] = [], usage: UsageNote? = nil, quiz: [QuizItem] = [],
        meaning: String? = nil
    ) -> Fiche {
        Fiche(
            id: "fr.\(headword)", language: .fr, headword: headword, family: family, themes: [], partOfSpeech: pos,
            gender: gender, register: .courant, phonetic: "/x/", shortDefinition: meaning ?? "Définition de \(headword)",
            definition: meaning ?? "Sens complet de \(headword).",
            confusions: confusions.map { Confusion(word: $0, meaning: "Sens de \($0)", example: "Exemple.") },
            usage: usage, nuance: nil,
            examples: [example ?? "On emploie **\(headword)** ici.", "Encore **\(headword)**."],
            authorQuote: nil, synonyms: synonyms, etymology: nil, level: level, frequencyRank: nil, quiz: quiz,
            sources: [SourceRef(name: "Wiktionnaire", url: "https://fr.wiktionary.org/")], reviewStatus: .autoChecked
        )
    }
}

@Suite("Fabrique de questions")
struct QuestionFactoryTests {

    private func wrongChoices(_ question: Question) -> [String] {
        guard case .choice(let index) = question.correct else { return [] }
        return question.choices.enumerated().filter { $0.offset != index }.map(\.element)
    }

    @Test("Sur les fiches modèles, chaque question de chaque jeu a une seule bonne réponse et aucun synonyme parmi les mauvaises", arguments: GameType.allCases)
    func seedQuestionsAreSound(game: GameType) throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        let factory = QuestionFactory(fiches: repository.fiches)
        var rng = SeededGenerator(seed: 7)
        var produced = 0
        for fiche in repository.fiches {
            guard let question = factory.question(for: fiche, game: game, rng: &rng) else { continue }
            produced += 1
            #expect(question.isWellFormed, "\(question.id)")
            #expect(question.game == game)
            let synonyms = Set(fiche.synonyms.map(SearchIndex.normalize))
            for wrong in wrongChoices(question) {
                #expect(!synonyms.contains(SearchIndex.normalize(wrong)), "\(question.id) propose le synonyme \(wrong)")
            }
        }
        #expect(produced > 0, "Aucune question \(game) sur les fiches modèles")
    }

    @Test("Les quiz écrits dans la fiche passent en premier")
    func quizFirst() {
        let quiz = QuizItem(game: .sens, prompt: "éminent", choices: ["Remarquable", "Proche", "Lointain"], answerIndex: 0, explanation: "…")
        let fiche = Fiche.word("éminent", pos: .adjectif, quiz: [quiz])
        var rng = SeededGenerator(seed: 1)
        let question = QuestionFactory(fiches: [fiche]).question(for: fiche, game: .sens, rng: &rng)
        #expect(question?.id.hasSuffix("#quiz") == true)
        #expect(question?.correctChoice == "Remarquable")
    }

    @Test("Juste ou fautif écrit : premier choix = phrase juste")
    func trueFalseFromQuiz() {
        let juste = QuizItem(game: .justeOuFautif, prompt: "« A »", choices: ["Juste", "Fautif"], answerIndex: 0, explanation: "")
        let fautif = QuizItem(game: .justeOuFautif, prompt: "« B »", choices: ["Juste", "Fautif"], answerIndex: 1, explanation: "")
        var rng = SeededGenerator(seed: 1)
        let factory = QuestionFactory(fiches: [])
        #expect(factory.question(for: .word("a", quiz: [juste]), game: .justeOuFautif, rng: &rng)?.correct == .trueFalse(true))
        #expect(factory.question(for: .word("b", quiz: [fautif]), game: .justeOuFautif, rng: &rng)?.correct == .trueFalse(false))
    }

    @Test("Devine le mot : mauvaises réponses de même nature et même genre")
    func natureAndGender() {
        let target = Fiche.word("alternative", pos: .nom, gender: .feminin)
        let pool = [
            target,
            .word("conjoncture", pos: .nom, gender: .feminin), .word("effraction", pos: .nom, gender: .feminin),
            .word("problème", pos: .nom, gender: .masculin), .word("acronyme", pos: .nom, gender: .masculin),
            .word("pallier", pos: .verbe), .word("éminent", pos: .adjectif),
        ]
        let factory = QuestionFactory(fiches: pool)
        for seed in 0..<20 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = factory.question(for: target, game: .devine, rng: &rng)
            #expect(Set(question?.choices ?? []) == ["alternative", "conjoncture", "effraction"])
        }
    }

    @Test("Un synonyme n'est jamais proposé comme mauvaise réponse")
    func neverSynonym() {
        let target = Fiche.word("empêcher", synonyms: ["entraver"])
        let pool = [target, .word("entraver"), .word("éviter"), .word("interdire"), .word("bloquer", synonyms: ["empêcher"]), .word("gêner")]
        let factory = QuestionFactory(fiches: pool)
        for seed in 0..<30 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let choices = factory.question(for: target, game: .devine, rng: &rng)?.choices ?? []
            #expect(!choices.contains("entraver"))
            #expect(!choices.contains("bloquer"))
        }
    }

    @Test("Pas assez de mauvaises réponses : pas de question")
    func notEnoughDistractors() {
        let target = Fiche.word("alternative", pos: .nom, gender: .feminin)
        var rng = SeededGenerator(seed: 1)
        #expect(QuestionFactory(fiches: [target, .word("pallier")]).question(for: target, game: .devine, rng: &rng) == nil)
    }

    @Test("Mot en blanc : seulement si la forme en gras est le mot lui-même")
    func blankNeedsExactForm() {
        let inflected = Fiche.word("éminent", pos: .adjectif, example: "Des **éminents** spécialistes.", confusions: ["imminent"])
        let exact = Fiche.word("imminent", pos: .adjectif, example: "Le départ est **imminent**.", confusions: ["éminent"])
        let factory = QuestionFactory(fiches: [inflected, exact])
        var rng = SeededGenerator(seed: 1)
        let base = Fiche.word("x")
        let noExample = Fiche(id: inflected.id, language: .fr, headword: inflected.headword, family: .paronyme, themes: [],
                              partOfSpeech: .adjectif, gender: nil, register: .courant, phonetic: "/x/", shortDefinition: "Def",
                              definition: "Def.", confusions: inflected.confusions, usage: nil, nuance: nil,
                              examples: ["Des **éminents** spécialistes.", "Les **éminentes** juristes."], authorQuote: nil,
                              synonyms: [], etymology: nil, level: 3, frequencyRank: nil, quiz: [], sources: base.sources,
                              reviewStatus: .autoChecked)
        #expect(factory.question(for: noExample, game: .paronymes, rng: &rng) == nil)
        let question = factory.question(for: exact, game: .paronymes, rng: &rng)
        #expect(question?.prompt == "Le départ est ___.")
        #expect(Set(question?.choices ?? []) == ["imminent", "éminent"])
        #expect(question?.correctChoice == "imminent")
    }

    @Test("Juste ou fautif généré : tournure juste ou à éviter, correction toujours la tournure juste")
    func generatedTrueFalse() {
        let usage = UsageNote(correct: "pallier un manque", avoid: "pallier à un manque", verdict: .critique, explanation: "Transitif direct.")
        let fiche = Fiche.word("pallier", usage: usage)
        var seen: Set<Question.Answer> = []
        for seed in 0..<20 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let question = QuestionFactory(fiches: [fiche]).question(for: fiche, game: .justeOuFautif, rng: &rng)
            #expect(question?.correction == "pallier un manque")
            if let question {
                seen.insert(question.correct)
                #expect(question.prompt == (question.correct == .trueFalse(true) ? "« pallier un manque »" : "« pallier à un manque »"))
            }
        }
        #expect(seen == [.trueFalse(true), .trueFalse(false)])
    }

    @Test("Session : une fiche par question, au plus le nombre demandé, même graine même session")
    func session() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        let factory = QuestionFactory(fiches: repository.fiches)
        for game in GameType.allCases {
            let questions = factory.questions(for: game, from: repository.fiches, count: Rules.sessionLength, seed: 3)
            #expect(questions.count <= Rules.sessionLength)
            #expect(Set(questions.map(\.ficheID)).count == questions.count)
            #expect(questions == factory.questions(for: game, from: repository.fiches, count: Rules.sessionLength, seed: 3))
            #expect(questions.allSatisfy { $0.game == game && $0.isWellFormed })
        }
        #expect(factory.questions(for: .motJuste, from: repository.fiches, count: 10, seed: 3).count == 10)
    }

    @Test("Test de précision : 30 questions, 6 par niveau, toutes bien formées")
    func levelTest() {
        let pool = (1...5).flatMap { level in
            (0..<8).map { Fiche.word("n\(level)x\($0)", family: Family.allCases[$0], pos: .adjectif, level: level,
                                     quiz: [QuizItem(game: .sens, prompt: "n\(level)x\($0)", choices: ["a\($0)", "b", "c"], answerIndex: 0, explanation: "")]) }
        }
        let questions = QuestionFactory(fiches: pool).levelTest(seed: 9)
        #expect(questions.count == Rules.levelTestLength)
        #expect(Set(questions.map(\.ficheID)).count == 30)
        let levels = questions.compactMap { question in pool.first { $0.id == question.ficheID }?.level }
        for level in 1...5 {
            #expect(levels.filter { $0 == level }.count == Rules.levelTestQuestionsPerLevel)
        }
    }

    @Test("Test de précision sur les fiches modèles (pas de niveau 5) : complété par les niveaux voisins")
    func levelTestOnSeed() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        let questions = QuestionFactory(fiches: repository.fiches).levelTest(seed: 9)
        #expect(questions.count >= 20)
        #expect(Set(questions.map(\.ficheID)).count == questions.count)
    }
}

@Suite("Mauvaises réponses proches")
struct DecoyTests {
    @Test("Proximité de forme : paronymes proches, confusions de sens lointaines")
    func form() {
        #expect(Proximity.form("éminent", "imminent") >= Rules.paronymFormThreshold)
        #expect(Proximity.form("déceler", "desceller") >= Rules.paronymFormThreshold)
        #expect(Proximity.form("prolongation", "prolongement") >= Rules.paronymFormThreshold)
        #expect(Proximity.form("se rappeler", "se souvenir") < Rules.paronymFormThreshold)
        #expect(Proximity.form("acronyme", "sigle") < Rules.paronymFormThreshold)
    }

    @Test("Proximité de sens : mots pleins partagés, à la racine près")
    func meaning() {
        let a = Proximity.keywords("Garder ou retrouver le souvenir de quelque chose")
        let b = Proximity.keywords("Perdre tout souvenir d'un événement")
        let c = Proximity.keywords("Porter un objet jusqu'à un lieu")
        #expect(Proximity.meaning(a, b) > 0)
        #expect(Proximity.meaning(a, c) == 0)
    }

    @Test("Devine le mot : le paronyme de la fiche est proposé, jamais sa confusion de sens", arguments: 0..<10)
    func paronymKept(seed: UInt64) throws {
        let target = Fiche.word("éminent", pos: .adjectif, confusions: ["imminent", "célèbre"], meaning: "Qui se distingue par son mérite")
        let pool = [target] + ["célèbre", "rapide", "joyeux", "fragile", "honnête"].map {
            Fiche.word($0, pos: .adjectif, meaning: "Adjectif \($0)")
        }
        var rng = SeededGenerator(seed: seed)
        let question = try #require(QuestionFactory(fiches: pool).question(for: target, game: .devine, rng: &rng))
        #expect(question.choices.contains("imminent"))
        #expect(!question.choices.contains("célèbre"))
    }

    @Test("Les mauvaises réponses viennent des mots les plus proches par la forme ou le sens", arguments: 0..<20)
    func closest(seed: UInt64) throws {
        let target = Fiche.word("pallier", meaning: "Atténuer un manque provisoirement")
        let close = [
            Fiche.word("palper", meaning: "Toucher avec la main"),
            Fiche.word("parier", meaning: "Miser de l'argent"),
            Fiche.word("combler", meaning: "Remplir entièrement un manque"),
            Fiche.word("compenser", meaning: "Équilibrer un manque par un avantage"),
        ]
        let far = ["dormir", "chanter", "nager", "bondir"].map { Fiche.word($0, meaning: "Action de \($0)") }
        var rng = SeededGenerator(seed: seed)
        let question = try #require(QuestionFactory(fiches: [target] + close + far).question(for: target, game: .devine, rng: &rng))
        #expect(Set(question.choices).isDisjoint(with: far.map(\.headword)))
    }
}

@Suite("Défis")
struct ChallengeTests {

    @Test("Rush : 3 vies, une erreur ou 5 s sans réponse coûtent une vie")
    func rush() {
        var state = ChallengeState(kind: .rush)
        #expect(state.answer(correct: true) == [.correct])
        #expect(state.answer(correct: false) == [.wrong, .lostLife])
        #expect(state.tick(4.9).isEmpty)
        #expect(state.tick(0.2) == [.timedOut, .lostLife])
        #expect(state.remaining == Rules.rushSecondsPerQuestion)
        #expect(state.lives == 1)
        #expect(state.answer(correct: false) == [.wrong, .lostLife, .ended(.noLivesLeft)])
        #expect(state.isOver)
        #expect(state.score == 1)
        #expect(state.answered == 4)
        #expect(state.answer(correct: true).isEmpty)
    }

    @Test("Rush : une bonne réponse remet le chrono de la question à 5 s")
    func rushTimerReset() {
        var state = ChallengeState(kind: .rush)
        _ = state.tick(3)
        _ = state.answer(correct: true)
        #expect(state.remaining == 5)
    }

    @Test("Sprint : 60 s au total, les erreurs ne coûtent rien, score = bonnes réponses")
    func sprint() {
        var state = ChallengeState(kind: .sprint)
        _ = state.answer(correct: true)
        _ = state.answer(correct: false)
        _ = state.answer(correct: true)
        #expect(state.tick(59).isEmpty)
        #expect(!state.isOver)
        #expect(state.tick(1) == [.ended(.timeUp)])
        #expect(state.score == 2)
        #expect(state.endReason == .timeUp)
    }

    @Test("Perfection : sans limite de temps, fin à la première erreur, score = série")
    func perfection() {
        var state = ChallengeState(kind: .perfection)
        for _ in 0..<9 { _ = state.answer(correct: true) }
        #expect(state.tick(1_000).isEmpty)
        #expect(state.answer(correct: false) == [.wrong, .ended(.firstMistake)])
        #expect(state.score == 9)
    }

    @Test("Rush ne pose que Le mot juste et Paronymes")
    func rushGames() {
        #expect(ChallengeState.Kind.rush.games == [.motJuste, .paronymes])
    }
}

@Suite("Statistiques de pratique")
struct PracticeStatsTests {
    let stats = PracticeStats(day: TestClock.day)

    private func answers(_ game: GameType, correct: Int, wrong: Int, daysAgo: Int = 0) -> [AnswerRecord] {
        Array(repeating: AnswerRecord(game: game, isCorrect: true, answeredAt: TestClock.date(days: -daysAgo)), count: correct)
            + Array(repeating: AnswerRecord(game: game, isCorrect: false, answeredAt: TestClock.date(days: -daysAgo)), count: wrong)
    }

    @Test("Précision par compétence sur 14 jours, affichée à partir de 10 réponses")
    func accuracy() {
        let records = answers(.sens, correct: 8, wrong: 2) + answers(.devine, correct: 0, wrong: 10, daysAgo: 14)
            + answers(.paronymes, correct: 5, wrong: 4)
        let result = stats.accuracy(records, at: TestClock.date())
        #expect(result[.sens]?.percent == 80)
        #expect(result[.usage]?.total == 9)
        #expect(result[.usage]?.percent == nil)
        #expect(result[.choixDuMot]?.total == 0)
    }

    @Test("Compétence suggérée : la plus faible avec plus de 10 points de retard")
    func suggestion() {
        let behind = answers(.sens, correct: 9, wrong: 1) + answers(.justeOuFautif, correct: 8, wrong: 2) + answers(.motJuste, correct: 6, wrong: 4)
        #expect(stats.suggestedSkill(stats.accuracy(behind, at: TestClock.date())) == .choixDuMot)
        let close = answers(.sens, correct: 8, wrong: 2) + answers(.justeOuFautif, correct: 8, wrong: 2) + answers(.motJuste, correct: 7, wrong: 3)
        #expect(stats.suggestedSkill(stats.accuracy(close, at: TestClock.date())) == nil)
        #expect(stats.suggestedSkill(stats.accuracy(answers(.sens, correct: 1, wrong: 9), at: TestClock.date())) == nil)
    }

    @Test("Gratuit : une session de jeu par jour, défis compris ; test et révisions libres")
    func freeLimit() {
        #expect(PracticeStats.canStartGame(isPremium: false, gameSessionsToday: 0))
        #expect(!PracticeStats.canStartGame(isPremium: false, gameSessionsToday: 1))
        #expect(PracticeStats.canStartGame(isPremium: true, gameSessionsToday: 5))
        #expect(PracticeMode.rush.countsAsGameSession)
        #expect(!PracticeMode.levelTest.countsAsGameSession)
        #expect(!PracticeMode.review.countsAsGameSession)
    }

    @Test("Chaque jeu mesure une compétence")
    func skills() {
        #expect(GameType.sens.skill == .sens && GameType.devine.skill == .sens)
        #expect(GameType.justeOuFautif.skill == .usage && GameType.paronymes.skill == .usage)
        #expect(GameType.motJuste.skill == .choixDuMot && GameType.passePartout.skill == .choixDuMot)
    }
}
