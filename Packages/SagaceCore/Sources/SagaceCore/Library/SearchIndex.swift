import Foundation

/// Recherche instantanée parmi les fiches (EXP-03) : mot, confusions, synonymes.
/// Casse et accents ignorés ("eminent" trouve "éminent"). Index construit une fois, requêtes en mémoire.
public struct SearchIndex: Sendable {
    private struct Entry: Sendable {
        let fiche: Fiche
        let headword: String
        let related: [String]
    }

    private let entries: [Entry]

    public init(fiches: [Fiche]) {
        entries = fiches.map { fiche in
            Entry(
                fiche: fiche,
                headword: Self.normalize(fiche.headword),
                related: (fiche.confusions.map(\.word) + fiche.synonyms).map(Self.normalize)
            )
        }
    }

    /// Résultats classés : mot exact, mot qui commence par la requête, mot qui la contient,
    /// puis confusion ou synonyme. Ordre alphabétique à rang égal.
    public func search(_ query: String, limit: Int = Rules.searchMaxResults) -> [Fiche] {
        let needle = Self.normalize(query)
        guard !needle.isEmpty else { return [] }
        var ranked: [(rank: Int, entry: Entry)] = []
        for entry in entries {
            let rank: Int? = if entry.headword == needle { 0 }
                else if entry.headword.hasPrefix(needle) { 1 }
                else if entry.headword.contains(needle) { 2 }
                else if entry.related.contains(where: { $0.hasPrefix(needle) }) { 3 }
                else { nil }
            if let rank { ranked.append((rank, entry)) }
        }
        return ranked
            .sorted { ($0.rank, $0.entry.headword) < ($1.rank, $1.entry.headword) }
            .prefix(limit)
            .map(\.entry.fiche)
    }

    public static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "fr"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
