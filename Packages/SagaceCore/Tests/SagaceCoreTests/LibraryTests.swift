import Foundation
import Testing
@testable import SagaceCore

@Suite("Fiche détaillée : sections visibles")
struct FicheSectionsTests {

    @Test("Une fiche complète montre toutes ses sections, dans l'ordre")
    func allSections() {
        let base = Fiche.sample()
        let full = Fiche(
            id: base.id, language: .fr, headword: "pallier", family: .impropriete, themes: [], partOfSpeech: .verbe,
            gender: nil, register: .courant, phonetic: base.phonetic, shortDefinition: base.shortDefinition,
            definition: "Atténuer un manque.", confusions: [Confusion(word: "palier", meaning: "plateau", example: "Un palier.")],
            usage: UsageNote(correct: "pallier un manque", avoid: "pallier à un manque", verdict: .critique, explanation: "Transitif direct."),
            nuance: "Nuance.", examples: base.examples,
            authorQuote: AuthorQuote(text: "…", author: "Hugo", work: "Les Misérables", year: 1862, url: "https://fr.wikisource.org/x"),
            synonyms: ["remédier"], etymology: "Du latin.", level: 3, frequencyRank: nil, quiz: base.quiz,
            sources: base.sources, reviewStatus: .autoChecked
        )
        #expect(FicheSection.visible(for: full) == FicheSection.allCases)
    }

    @Test("Les sections vides disparaissent")
    func sparseFiche() {
        let fiche = Fiche.sample()
        #expect(FicheSection.visible(for: fiche) == [.sens, .examples, .sources])
    }

    @Test("Une nuance ou une étymologie blanche ne crée pas de section")
    func blankStrings() {
        let base = Fiche.sample()
        let blank = Fiche(
            id: base.id, language: .fr, headword: base.headword, family: base.family, themes: [], partOfSpeech: .adjectif,
            gender: nil, register: .courant, phonetic: base.phonetic, shortDefinition: base.shortDefinition,
            definition: base.definition, confusions: [], usage: nil, nuance: "  ", examples: base.examples,
            authorQuote: nil, synonyms: [], etymology: "", level: 2, frequencyRank: nil, quiz: base.quiz,
            sources: base.sources, reviewStatus: .autoChecked
        )
        #expect(!FicheSection.nuance.isVisible(for: blank))
        #expect(!FicheSection.etymology.isVisible(for: blank))
    }

    @Test("Sur les 25 fiches modèles, chaque section visible a du contenu")
    func seed() async throws {
        let repository = try await ContentRepository.load(contentsOf: SeedContent.fichesURL, visibility: .development)
        let eminent = try #require(repository.fiche(id: "fr.eminent"))
        #expect(FicheSection.visible(for: eminent) == [.sens, .confusions, .examples, .synonyms, .etymology, .sources])
        for fiche in repository.fiches {
            #expect(FicheSection.visible(for: fiche).contains(.sens))
            #expect(FicheSection.visible(for: fiche).contains(.sources))
        }
    }
}

@Suite("Recherche")
struct SearchIndexTests {
    let index = SearchIndex(fiches: [
        Fiche.feed("éminent"), .feed("imminent"), .feed("émincer"), .feed("pallier"), .feed("palier"),
    ])

    @Test("Casse et accents ignorés")
    func folding() {
        #expect(index.search("EMINENT").map(\.headword) == ["éminent"])
        #expect(index.search("emin").map(\.headword) == ["émincer", "éminent"])
    }

    @Test("Mot exact, puis début de mot, puis contenu")
    func ranking() {
        #expect(index.search("palier").map(\.headword) == ["palier"])
        #expect(index.search("pal").map(\.headword) == ["palier", "pallier"])
        #expect(index.search("minent").map(\.headword) == ["éminent", "imminent"])
    }

    @Test("Confusions et synonymes répondent aussi")
    func related() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        #expect(repository.searchIndex.search("imminent").map(\.id).contains("fr.eminent"))
        #expect(repository.searchIndex.search("illustre").map(\.id).contains("fr.eminent"))
    }

    @Test("Requête vide : aucun résultat")
    func empty() {
        #expect(index.search("  ").isEmpty)
    }

    @Test("Moins de 50 ms sur 1 000 fiches")
    func performance() {
        let fiches = (0..<1_000).map { Fiche.feed("mot\($0)", family: Family.allCases[$0 % 8]) }
        let index = SearchIndex(fiches: fiches)
        let clock = ContinuousClock()
        for query in ["mot", "mot5", "mot999", "zzz", "é"] {
            let elapsed = clock.measure { _ = index.search(query) }
            #expect(elapsed < .milliseconds(50), "« \(query) » : \(elapsed)")
        }
    }

    @Test("Fiche d'un mot depuis un synonyme")
    func byHeadword() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development)
        #expect(repository.fiche(headword: "EMINENT")?.id == "fr.eminent")
        #expect(repository.fiche(headword: "inconnu") == nil)
    }
}

@Suite("Bibliothèque")
struct LibraryTests {
    let library = Library(day: TestClock.day)
    let now = TestClock.date()

    @Test("À retenir : par prochaine révision, avec le nombre de jours")
    func toLearn() {
        let progress = [
            FicheProgress(ficheID: "loin", sorting: .toLearn, review: ReviewState(box: 3, nextReviewAt: TestClock.date(days: 6, hour: 4))),
            FicheProgress(ficheID: "demain", sorting: .toLearn, review: ReviewState(box: 1, nextReviewAt: TestClock.date(days: 1, hour: 4))),
            FicheProgress(ficheID: "retard", sorting: .toLearn, review: ReviewState(box: 2, nextReviewAt: TestClock.date(days: -2, hour: 4))),
            FicheProgress(ficheID: "connue", sorting: .known),
            FicheProgress(ficheID: "maitrisee", sorting: .toLearn, review: ReviewState(box: 0, masteredAt: now)),
        ]
        let items = library.toLearn(progress, at: now)
        #expect(items.map(\.ficheID) == ["retard", "demain", "loin"])
        #expect(items.map(\.daysUntilReview) == [0, 1, 6])
    }

    @Test("Maîtrisés : le plus récent d'abord")
    func mastered() {
        let progress = [
            FicheProgress(ficheID: "ancien", review: ReviewState(masteredAt: TestClock.date(days: -10))),
            FicheProgress(ficheID: "recent", review: ReviewState(masteredAt: TestClock.date(days: -1))),
            FicheProgress(ficheID: "non", review: ReviewState(box: 2)),
        ]
        #expect(library.mastered(progress).map(\.ficheID) == ["recent", "ancien"])
    }

    @Test("Historique : par journée, sur la fenêtre demandée")
    func history() {
        let progress = [
            FicheProgress(ficheID: "a", lastSeenAt: TestClock.date(hour: 9)),
            FicheProgress(ficheID: "b", lastSeenAt: TestClock.date(hour: 10), sorting: .known),
            FicheProgress(ficheID: "c", lastSeenAt: TestClock.date(days: -1)),
            FicheProgress(ficheID: "vieux", lastSeenAt: TestClock.date(days: -10)),
        ]
        let days = library.history(progress, at: now, days: 7)
        #expect(days.map { $0.fiches.map(\.ficheID) } == [["b", "a"], ["c"]])
        #expect(library.hasOlderHistory(progress, at: now, days: 7))
        #expect(!library.hasOlderHistory(progress, at: now, days: 14))
        #expect(library.history(progress, at: now, days: 14).count == 3)
    }

    @Test func status() {
        #expect(FicheStatus(progress: nil) == .new)
        #expect(FicheStatus(progress: FicheProgress(ficheID: "x")) == .new)
        #expect(FicheStatus(progress: FicheProgress(ficheID: "x", sorting: .toLearn, review: ReviewState(box: 2))) == .toLearn)
        #expect(FicheStatus(progress: FicheProgress(ficheID: "x", sorting: .toLearn, review: ReviewState(masteredAt: now))) == .mastered)
    }
}

@Suite("Feed : collections suivies")
struct FollowedCollectionTests {
    @Test("Une collection suivie fait entrer ses fiches, comme une famille ou un thème")
    func followedFiches() {
        let engine = FeedEngine(day: TestClock.day)
        let fiches = [Fiche.feed("dans"), .feed("hors"), .feed("paro", family: .paronyme)]
        let profile = FeedProfile(followedFamilies: [.paronyme], followedFicheIDs: ["fr.dans"])
        #expect(engine.eligible(fiches, progress: [:], profile: profile, at: TestClock.date()).map(\.headword) == ["dans", "paro"])
    }
}
