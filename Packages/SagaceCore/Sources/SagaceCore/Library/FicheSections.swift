/// Sections de la fiche détaillée (DET-01), dans l'ordre d'affichage.
/// Une section n'apparaît que si la fiche a de quoi la remplir.
public enum FicheSection: String, CaseIterable, Sendable {
    case sens, confusions, usage, nuance, examples, authorQuote, synonyms, etymology, sources

    public static func visible(for fiche: Fiche) -> [FicheSection] {
        allCases.filter { $0.isVisible(for: fiche) }
    }

    public func isVisible(for fiche: Fiche) -> Bool {
        switch self {
        case .sens: !fiche.definition.isBlank
        case .confusions: !fiche.confusions.isEmpty
        case .usage: fiche.usage != nil
        case .nuance: !(fiche.nuance ?? "").isBlank
        case .examples: !fiche.examples.isEmpty
        case .authorQuote: fiche.authorQuote != nil
        case .synonyms: !fiche.synonyms.isEmpty
        case .etymology: !(fiche.etymology ?? "").isBlank
        case .sources: !fiche.sources.isEmpty
        }
    }
}

extension String {
    var isBlank: Bool { allSatisfy(\.isWhitespace) }
}
