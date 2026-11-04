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
