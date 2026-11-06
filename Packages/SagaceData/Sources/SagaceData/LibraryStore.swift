import Foundation
import SagaceCore
import SwiftData

public enum LibraryError: Error, Equatable, Sendable {
    /// "Au moins un caractère."
    case emptyText
}

/// Bibliothèque de l'utilisateur : collections (LIB-03), mots perso (LIB-04), signalements (DET-02, EXP-03).
@MainActor
public protocol LibraryStoring: AnyObject {
    func collections() -> [UserCollection]
    @discardableResult func createCollection(named name: String) throws(LibraryError) -> UserCollection
    func rename(_ collection: UserCollection, to name: String) throws(LibraryError)
    func delete(_ collection: UserCollection)
    /// Ajoute la fiche à la collection, ou l'en retire si elle y est déjà.
    func toggle(_ ficheID: String, in collection: UserCollection)
    func setFollowed(_ collection: UserCollection, _ isFollowed: Bool)
    /// Fiches des collections suivies dans le feed.
    func followedFicheIDs() -> Set<String>

    func ownWords() -> [OwnWord]
    @discardableResult func addOwnWord(headword: String, definition: String, partOfSpeech: PartOfSpeech, gender: Gender?) throws(LibraryError) -> OwnWord
    func delete(_ word: OwnWord)

    func reports() -> [ErrorReport]
    func report(ficheID: String, reason: ReportReason, comment: String?)
    /// Bêta : fiches jugées justes par le testeur (`ReportReason.confirmed`).
    func confirmedFicheIDs() -> Set<String>
    /// Bêta : « Juste », une seule fois par fiche.
    func confirm(ficheID: String)
}

@MainActor
public final class LibraryStore: LibraryStoring {
    private let context: ModelContext
    private let now: () -> Date

    public init(context: ModelContext, now: @escaping () -> Date = { .now }) {
        self.context = context
        self.now = now
    }

    private static func cleaned(_ text: String) throws(LibraryError) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Rules.ownWordMinLength else { throw .emptyText }
        return trimmed
    }

    // MARK: Collections

    public func collections() -> [UserCollection] {
        (try? context.fetch(FetchDescriptor<UserCollection>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
    }

    @discardableResult
    public func createCollection(named name: String) throws(LibraryError) -> UserCollection {
        let collection = UserCollection(name: try Self.cleaned(name), createdAt: now())
        context.insert(collection)
        save()
        return collection
    }

    public func rename(_ collection: UserCollection, to name: String) throws(LibraryError) {
        collection.name = try Self.cleaned(name)
        save()
    }

    public func delete(_ collection: UserCollection) {
        context.delete(collection)
        save()
    }

    public func toggle(_ ficheID: String, in collection: UserCollection) {
        if let index = collection.ficheIDs.firstIndex(of: ficheID) {
            collection.ficheIDs.remove(at: index)
        } else {
            collection.ficheIDs.append(ficheID)
        }
        save()
    }

    public func setFollowed(_ collection: UserCollection, _ isFollowed: Bool) {
        collection.isFollowed = isFollowed
        save()
    }

    public func followedFicheIDs() -> Set<String> {
        Set(collections().filter(\.isFollowed).flatMap(\.ficheIDs))
    }

    // MARK: Mes mots

    public func ownWords() -> [OwnWord] {
        (try? context.fetch(FetchDescriptor<OwnWord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
    }

    @discardableResult
    public func addOwnWord(headword: String, definition: String, partOfSpeech: PartOfSpeech, gender: Gender?) throws(LibraryError) -> OwnWord {
        let word = OwnWord(
            headword: try Self.cleaned(headword),
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
            partOfSpeech: partOfSpeech,
            gender: partOfSpeech == .nom ? gender : nil,
            createdAt: now()
        )
        context.insert(word)
        save()
        return word
    }

    public func delete(_ word: OwnWord) {
        context.delete(word)
        save()
    }

    // MARK: Signalements

    public func reports() -> [ErrorReport] {
        (try? context.fetch(FetchDescriptor<ErrorReport>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
    }

    /// File locale : l'envoi vers un serveur viendra quand l'endpoint existera (`OPEN_QUESTIONS.md` n° 8).
    public func report(ficheID: String, reason: ReportReason, comment: String?) {
        let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(ErrorReport(ficheID: ficheID, reason: reason.rawValue, comment: trimmed?.isEmpty == false ? trimmed : nil, createdAt: now()))
        save()
    }

    public func confirmedFicheIDs() -> Set<String> {
        let confirmed = ReportReason.confirmed.rawValue
        let reports = (try? context.fetch(FetchDescriptor<ErrorReport>(predicate: #Predicate { $0.reason == confirmed }))) ?? []
        return Set(reports.map(\.ficheID))
    }

    public func confirm(ficheID: String) {
        guard !confirmedFicheIDs().contains(ficheID) else { return }
        report(ficheID: ficheID, reason: .confirmed, comment: nil)
    }

    private func save() {
        try? context.save()
    }
}
