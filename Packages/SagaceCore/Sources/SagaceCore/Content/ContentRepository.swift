import Foundation

/// Pack de fiches chargé en mémoire et indexé. Immuable : toutes les requêtes sont pures.
public struct ContentRepository: Sendable {

    public enum Visibility: Sendable {
        /// Seules les fiches `autoChecked` et `humanChecked`.
        case production
        /// Toutes les fiches, brouillons compris (données de développement).
        case development
    }

    public enum LoadError: Error, Sendable {
        case unreadable(URL, underlying: String)
        case undecodable(underlying: String)
    }

    /// Fiches visibles, dans l'ordre du pack.
    public let fiches: [Fiche]
    /// Problèmes de conformité relevés au chargement. Les fiches concernées sont écartées.
    public let issues: [FicheIssue]

    private let byID: [String: Fiche]
    private let byFamily: [Family: [Fiche]]
    private let byTheme: [String: [Fiche]]
    private let byLevel: [Int: [Fiche]]

    public init(fiches all: [Fiche], visibility: Visibility = .production) {
        let issues = FicheValidator.validate(all)
        let rejected = Set(issues.map(\.ficheID))
        let visible = all.filter { fiche in
            !rejected.contains(fiche.id) && (visibility == .development || fiche.isPublishable)
        }
        self.fiches = visible
        self.issues = issues
        self.byID = Dictionary(visible.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.byFamily = Dictionary(grouping: visible, by: \.family)
        self.byLevel = Dictionary(grouping: visible, by: \.level)
        var byTheme: [String: [Fiche]] = [:]
        for fiche in visible {
            for theme in fiche.themes { byTheme[theme, default: []].append(fiche) }
        }
        self.byTheme = byTheme
    }

    /// Décode un pack JSON (tableau de fiches).
    public init(data: Data, visibility: Visibility = .production) throws(LoadError) {
        do {
            let fiches = try JSONDecoder().decode([Fiche].self, from: data)
            self.init(fiches: fiches, visibility: visibility)
        } catch {
            throw .undecodable(underlying: String(describing: error))
        }
    }

    /// Charge un pack depuis le disque, hors du thread principal.
    public static func load(contentsOf url: URL, visibility: Visibility = .production) async throws(LoadError) -> ContentRepository {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw .unreadable(url, underlying: String(describing: error))
        }
        return try ContentRepository(data: data, visibility: visibility)
    }

    // MARK: Requêtes

    public var isEmpty: Bool { fiches.isEmpty }

    public func fiche(id: String) -> Fiche? { byID[id] }

    public func fiches(in family: Family) -> [Fiche] { byFamily[family] ?? [] }

    public func fiches(theme: String) -> [Fiche] { byTheme[theme] ?? [] }

    public func fiches(level: Level) -> [Fiche] { byLevel[level.rawValue] ?? [] }
}
