import Foundation
import Testing
@testable import SagaceCore

/// Le pack de développement est lu directement dans `content/fr` du dépôt (source unique).
enum SeedContent {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // SagaceCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // SagaceCore
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent()
    static let fichesURL = repoRoot.appending(path: "content/fr/seed_fiches.json")
    static let topicsURL = repoRoot.appending(path: "content/fr/topics.json")
    /// Pack embarqué dans l'app (sortie de l'étape build du pipeline) et pack anglais historique.
    static let packURL = repoRoot.appending(path: "content/fr/fiches.json")
    static let englishPackURL = repoRoot.appending(path: "content/en/fiches.json")
}

@Suite("Chargement du pack de fiches")
struct ContentRepositoryTests {

    @Test("Les 25 fiches modèles se chargent et passent la validation")
    func seedLoadsAndValidates() async throws {
        let repository = try await ContentRepository.load(contentsOf: SeedContent.fichesURL, visibility: .development)
        #expect(repository.issues.isEmpty, "\(repository.issues)")
        #expect(repository.fiches.count == 25)
    }

    @Test("En production, les brouillons sont masqués")
    func productionHidesDrafts() async throws {
        let repository = try await ContentRepository.load(contentsOf: SeedContent.fichesURL, visibility: .production)
        #expect(repository.isEmpty)
        #expect(repository.issues.isEmpty)
    }

    @Test("Les index par id, famille, thème et niveau sont cohérents")
    func indexes() async throws {
        let repository = try await ContentRepository.load(contentsOf: SeedContent.fichesURL, visibility: .development)
        let eminent = try #require(repository.fiche(id: "fr.eminent"))
        #expect(eminent.headword == "éminent")
        #expect(eminent.family == .paronyme)
        #expect(eminent.confusions.first?.word == "imminent")
        #expect(repository.fiches(in: .paronyme).contains(eminent))
        #expect(repository.fiches(theme: "travail").contains(eminent))
        #expect(repository.fiches(level: .elementaire).contains(eminent))

        let familyTotal = Family.allCases.map { repository.fiches(in: $0).count }.reduce(0, +)
        #expect(familyTotal == repository.fiches.count)
        let levelTotal = Level.allCases.map { repository.fiches(level: $0).count }.reduce(0, +)
        #expect(levelTotal == repository.fiches.count)
    }

    @Test("Chaque thème cité par une fiche existe dans topics.json")
    func themesAreKnown() async throws {
        let repository = try await ContentRepository.load(contentsOf: SeedContent.fichesURL, visibility: .development)
        let topics = try JSONDecoder().decode(Topics.self, from: Data(contentsOf: SeedContent.topicsURL))
        let known = Set(topics.themes.map(\.id))
        let used = Set(repository.fiches.flatMap(\.themes))
        #expect(used.isSubset(of: known), "Thèmes inconnus : \(used.subtracting(known))")
        #expect(Set(topics.families.map(\.id)) == Set(Family.allCases))
    }

    @Test("Un fichier illisible lève une erreur explicite")
    func unreadableFile() async {
        await #expect(throws: ContentRepository.LoadError.self) {
            _ = try await ContentRepository.load(contentsOf: URL(fileURLWithPath: "/nope/fiches.json"))
        }
    }

    @Test("Un JSON hors schéma lève une erreur de décodage")
    func undecodable() {
        #expect(throws: ContentRepository.LoadError.self) {
            _ = try ContentRepository(data: Data(#"[{"id": "fr.x"}]"#.utf8))
        }
    }

    @Test("Une fiche non conforme est écartée et signalée")
    func invalidFicheIsRejected() throws {
        let good = Fiche.sample()
        let bad = Fiche.sample(id: "fr.bad", shortDefinition: "Se termine par un point.")
        let repository = ContentRepository(fiches: [good, bad], visibility: .development)
        #expect(repository.fiches.map(\.id) == [good.id])
        #expect(Set(repository.issues.map(\.ficheID)) == ["fr.bad"])
    }
}

@Suite("Packs embarqués")
struct PackTests {
    @Test("Le pack français embarqué est conforme, sans fiche écartée")
    func frenchPack() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.packURL), visibility: .development)
        #expect(repository.issues.isEmpty, "\(repository.issues.prefix(5))")
        #expect(repository.fiches.allSatisfy { $0.language == .fr && $0.partOfSpeech != .inconnu })
    }

    @Test("Le pack anglais historique (v3) est conforme et visible en production")
    func englishPack() throws {
        let repository = try ContentRepository(data: Data(contentsOf: SeedContent.englishPackURL))
        #expect(repository.issues.isEmpty, "\(repository.issues.prefix(5))")
        #expect(repository.fiches.count > 24_000)
        #expect(repository.fiches.allSatisfy { $0.language == .en && $0.family == .motMalCompris })
        #expect(repository.fiche(headword: "otiose") != nil)
    }

    @Test("Langue du pack : français, sauf appareil dans une autre langue avec le pack anglais présent")
    func language() {
        #expect(ContentLanguage.preferred(["fr-FR", "en-US"], englishPackAvailable: true) == .fr)
        #expect(ContentLanguage.preferred(["fr-CA"], englishPackAvailable: true) == .fr)
        #expect(ContentLanguage.preferred(["en-GB", "fr-FR"], englishPackAvailable: true) == .en)
        #expect(ContentLanguage.preferred(["de-DE"], englishPackAvailable: false) == .fr)
        #expect(ContentLanguage.preferred([], englishPackAvailable: true) == .fr)
    }

    @Test("Nature et prononciation : obligatoires pour une fiche française seulement")
    func legacyRules() throws {
        let english = try #require(try ContentRepository(data: Data(contentsOf: SeedContent.englishPackURL)).fiches.first)
        #expect(FicheValidator.validate(english).isEmpty)
        let french = try #require(try ContentRepository(data: Data(contentsOf: SeedContent.fichesURL), visibility: .development).fiches.first)
        let unknown = Fiche(
            id: french.id, language: .fr, headword: french.headword, family: french.family, themes: french.themes,
            partOfSpeech: .inconnu, gender: nil, register: french.register, phonetic: "", shortDefinition: french.shortDefinition,
            definition: french.definition, confusions: french.confusions, usage: french.usage, nuance: french.nuance,
            examples: Array(french.examples.prefix(1)), authorQuote: french.authorQuote, synonyms: french.synonyms,
            etymology: french.etymology, level: french.level, frequencyRank: french.frequencyRank, quiz: french.quiz,
            sources: [SourceRef(name: "Words (v3)", url: "")], reviewStatus: french.reviewStatus
        )
        #expect(Set(FicheValidator.validate(unknown).map(\.field)) == ["phonetic", "partOfSpeech", "examples", "sources"])
    }
}

