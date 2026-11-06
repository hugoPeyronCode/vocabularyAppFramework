import Foundation
import SagaceCore
import SwiftData
import Testing
@testable import SagaceData

@MainActor
@Suite("Bibliothèque")
struct LibraryStoreTests {
    let container: ModelContainer
    let store: LibraryStore

    init() throws {
        container = try SagaceStore.makeContainer(inMemory: true)
        store = LibraryStore(context: container.mainContext, now: { TestEnv.date() })
    }

    @Test("Créer, renommer, supprimer une collection")
    func collectionLifecycle() throws {
        let collection = try store.createCollection(named: "  Réunions ")
        #expect(collection.name == "Réunions")
        try store.rename(collection, to: "Pièges des mails")
        #expect(store.collections().map(\.name) == ["Pièges des mails"])
        store.delete(collection)
        #expect(store.collections().isEmpty)
    }

    @Test("Un nom vide est refusé")
    func emptyName() throws {
        #expect(throws: LibraryError.emptyText) { try store.createCollection(named: "   ") }
        let collection = try store.createCollection(named: "Bac")
        #expect(throws: LibraryError.emptyText) { try store.rename(collection, to: "") }
        #expect(collection.name == "Bac")
    }

    @Test("Ajouter puis retirer une fiche ; seules les collections suivies alimentent le feed")
    func toggleAndFollow() throws {
        let travail = try store.createCollection(named: "Travail")
        let examen = try store.createCollection(named: "Examen")
        store.toggle("fr.a", in: travail)
        store.toggle("fr.b", in: travail)
        store.toggle("fr.c", in: examen)
        store.toggle("fr.b", in: travail)
        #expect(travail.ficheIDs == ["fr.a"])
        #expect(store.followedFicheIDs().isEmpty)
        store.setFollowed(travail, true)
        #expect(store.followedFicheIDs() == ["fr.a"])
    }

    @Test("Mes mots : au moins un caractère, genre gardé seulement pour un nom")
    func ownWords() throws {
        #expect(throws: LibraryError.emptyText) {
            try store.addOwnWord(headword: " ", definition: "x", partOfSpeech: .nom, gender: .feminin)
        }
        try store.addOwnWord(headword: "sérendipité", definition: " Découverte heureuse ", partOfSpeech: .nom, gender: .feminin)
        try store.addOwnWord(headword: "procrastiner", definition: "Remettre à plus tard", partOfSpeech: .verbe, gender: .masculin)
        let words = store.ownWords()
        #expect(words.count == 2)
        #expect(words.first { $0.headword == "sérendipité" }?.gender == .feminin)
        #expect(words.first { $0.headword == "sérendipité" }?.definition == "Découverte heureuse")
        #expect(words.first { $0.headword == "procrastiner" }?.gender == nil)
    }

    @Test("Signalements en file locale, commentaire vide ignoré")
    func reports() {
        store.report(ficheID: "fr.eminent", reason: .definition, comment: "  ")
        store.report(ficheID: "", reason: .suggestion, comment: "sérendipité")
        let reports = store.reports()
        #expect(reports.count == 2)
        #expect(reports.first { $0.ficheID == "fr.eminent" }?.comment == nil)
        #expect(reports.first { $0.reason == ReportReason.suggestion.rawValue }?.comment == "sérendipité")
        #expect(reports.allSatisfy { !$0.sent })
    }

    @Test("Bêta : « Juste » enregistré une seule fois par fiche")
    func confirm() {
        store.confirm(ficheID: "fr.eminent")
        store.confirm(ficheID: "fr.eminent")
        store.report(ficheID: "fr.pallier", reason: .definition, comment: nil)
        #expect(store.confirmedFicheIDs() == ["fr.eminent"])
        #expect(store.reports().count == 2)
    }
}
