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
