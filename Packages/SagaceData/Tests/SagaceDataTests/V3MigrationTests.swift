import Foundation
import SagaceCore
import SwiftData
import Testing
@testable import SagaceData

/// Extrait d'un `savedWords.json` écrit par Words v3 (`UserDataStorage.saveWords`).
private let v3SavedWords = """
[
  {"Rank": "102", "List": "GRE", "Headword": "veracious", "Definition": "Always telling the truth",
   "Context sentence": "He is known for being veracious.", "Synonyms": "honest, truthful", "Antonyms": "", "Topic": "Personality", "isLiked": true},
  {"Rank": "455", "List": "SAT", "Headword": "Indelible", "Definition": "Impossible to erase or forget",
   "Context sentence": "Her smile left an indelible mark.", "Synonyms": "", "Antonyms": "", "Topic": "Other", "isLiked": true},
  {"Rank": "455", "List": "SAT", "Headword": "indelible", "Definition": "Impossible to erase or forget",
   "Context sentence": "Duplicate entry.", "Synonyms": "", "Antonyms": "", "Topic": "Other", "isLiked": true}
]
"""

@MainActor
@Suite("Migration depuis Words v3", .serialized)
struct V3MigrationTests {
    let defaults: UserDefaults
    let documents: URL

    init() throws {
        let suite = "sagace.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        documents = FileManager.default.temporaryDirectory.appending(path: suite)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    private func installV3(savedWords: String? = v3SavedWords, icon: String? = "AppIcon7", premium: Bool = false) throws {
        defaults.set(false, forKey: V3Migration.Key.isShowingOnboarding)
        defaults.set(3, forKey: V3Migration.Key.quizApparitionValue)
        if let icon { defaults.set(icon, forKey: V3Migration.Key.activeIcon) }
        defaults.set(premium, forKey: V3Migration.Key.premiumAccess)
        if let savedWords {
            try Data(savedWords.utf8).write(to: documents.appending(path: V3Migration.savedWordsFilename))
        }
    }

    private func englishFiche(_ headword: String) -> Fiche {
        Fiche(
            id: "en.\(headword)", language: .en, headword: headword, family: .motMalCompris, themes: [],
            partOfSpeech: .adjectif, gender: nil, register: .courant, phonetic: "/x/", shortDefinition: "A definition",
            definition: "A definition.", confusions: [], usage: nil, nuance: nil,
            examples: ["A **\(headword)** one.", "Another **\(headword)**."], authorQuote: nil, synonyms: [],
            etymology: nil, level: 3, frequencyRank: nil,
            quiz: [QuizItem(game: .sens, prompt: headword, choices: ["a", "b"], answerIndex: 0, explanation: "")],
            sources: [SourceRef(name: "Words v3", url: "https://example.com")], reviewStatus: .draft
        )
    }

    private func migration(_ store: ProgressStore, fiches: [Fiche] = []) -> V3Migration {
        V3Migration(defaults: defaults, documentsURL: documents, store: store, content: ContentRepository(fiches: fiches, visibility: .development))
    }

    @Test("Détection : une installation neuve n'a rien à migrer")
    func freshInstall() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        #expect(!migration(store).isNeeded)
    }

    @Test("Détection : clé v3 ou fichier de mots aimés, une seule fois")
    func detection() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3(savedWords: nil)
        #expect(migration(store).isNeeded)
        _ = migration(store).run(at: TestEnv.date())
        #expect(!migration(store).isNeeded)
    }

    @Test("Étape 1 : les mots aimés présents dans le pack anglais entrent en À retenir, les autres sont gardés")
    func importLikedWords() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3()
        let report = migration(store, fiches: [englishFiche("veracious")]).run(at: TestEnv.date())
        #expect(report.likedCount == 2)
        #expect(report.importedCount == 1)
        let state = try #require(store.allProgress()["en.veracious"])
        #expect(state.sorting == .toLearn)
        #expect(state.review.box == 1)
        #expect(store.profile.pendingV3Headwords == ["Indelible"])
        #expect(store.activity().isEmpty, "L'import ne compte pas comme activité du jour")
    }

    @Test("Étape 1 : un fichier illisible n'empêche pas la migration")
    func corruptedSavedWords() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3(savedWords: "{ pas du json")
        let report = migration(store).run(at: TestEnv.date())
        #expect(report.likedCount == 0)
        #expect(store.profile.migratedFromV3)
    }

    @Test("Étape 2 : l'icône alternative v3 est signalée pour être remise par défaut")
    func alternateIcon() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3(icon: "AppIcon12")
        #expect(migration(store).run(at: TestEnv.date()).hadAlternateIcon)
    }

    @Test("Étape 2 : l'icône par défaut ne demande rien")
    func defaultIcon() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3(icon: "AppIcon")
        #expect(!migration(store).run(at: TestEnv.date()).hadAlternateIcon)
    }

    @Test("Étape 4 : la clé premium v3 est relevée avant d'être supprimée")
    func legacyPremium() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3(premium: true)
        let report = migration(store).run(at: TestEnv.date())
        #expect(report.legacyPremiumFlag)
        #expect(store.profile.legacyPremiumFlag)
    }

    @Test("Étape 5 : profil marqué, clés v3 supprimées, savedWords.json renommé en sauvegarde")
    func cleanup() throws {
        let (store, _container) = try TestEnv.makeStore()
        _ = _container
        try installV3()
        _ = migration(store).run(at: TestEnv.date())
        #expect(store.profile.migratedFromV3)
        #expect(store.profile.hasCompletedOnboarding)
        for key in V3Migration.Key.all {
            #expect(defaults.object(forKey: key) == nil, "\(key) devrait être supprimée")
        }
        #expect(!FileManager.default.fileExists(atPath: documents.appending(path: V3Migration.savedWordsFilename).path))
        let backup = try Data(contentsOf: documents.appending(path: V3Migration.backupFilename))
        #expect(String(decoding: backup, as: UTF8.self) == v3SavedWords)
    }
}
