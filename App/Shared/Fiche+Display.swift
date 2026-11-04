import SagaceCore
import SwiftUI

extension Fiche {
    /// Nature et genre abrégés : "adj.", "n. f.", "loc.".
    var grammarLabel: LocalizedStringKey {
        switch (partOfSpeech, gender) {
        case (.nom, .masculin): "n. m."
        case (.nom, .feminin): "n. f."
        case (.nom, _): "n."
        case (.verbe, _): "v."
        case (.adjectif, _): "adj."
        case (.adverbe, _): "adv."
        case (.locution, _): "loc."
        case (.preposition, _): "prép."
        }
    }
}

extension UsageNote.Verdict {
    var label: LocalizedStringKey {
        switch self {
        case .fautif: "fautif"
        case .critique: "critiqué"
        case .tolere: "toléré"
        }
    }
}

extension Register {
    var label: LocalizedStringKey {
        switch self {
        case .courant: "courant"
        case .soutenu: "soutenu"
        case .familier: "familier"
        case .litteraire: "littéraire"
        }
    }
}

extension Family {
    /// Icône de tuile en attendant les illustrations (`08_ILLUSTRATIONS.md`).
    var symbol: String {
        switch self {
        case .paronyme: "arrow.left.arrow.right"
        case .impropriete: "exclamationmark.bubble"
        case .passePartout: "wand.and.stars"
        case .nuance: "slider.horizontal.3"
        case .pleonasme: "repeat"
        case .anglicisme: "globe.europe.africa"
        case .motMalCompris: "questionmark.bubble"
        case .expression: "quote.bubble"
        }
    }
}

enum ThemeSymbol {
    static func symbol(for themeID: String) -> String {
        switch themeID {
        case "travail": "briefcase"
        case "emotions": "heart"
        case "relations": "person.2"
        case "societe": "building.columns"
        case "argent": "eurosign.circle"
        case "sante": "cross.case"
        case "droit": "scalemass"
        case "sciences": "atom"
        case "culture": "theatermasks"
        case "cuisine": "fork.knife"
        case "voyage": "airplane"
        case "nature": "leaf"
        default: "tag"
        }
    }
}

extension FicheStatus {
    var label: LocalizedStringKey {
        switch self {
        case .new: "nouveau"
        case .known: "je savais"
        case .toLearn: "à retenir"
        case .mastered: "maîtrisé"
        }
    }
}

extension Text {
    /// Texte du contenu où le mot est marqué `**ainsi**` : rendu en gras.
    init(marked content: String) {
        let attributed = (try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(content)
        self.init(attributed)
    }
}
