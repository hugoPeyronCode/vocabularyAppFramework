import SagaceCore
import SwiftUI

extension GameType {
    var title: LocalizedStringKey {
        switch self {
        case .motJuste: "Le mot juste"
        case .paronymes: "Paronymes"
        case .justeOuFautif: "Juste ou fautif"
        case .passePartout: "Passe partout"
        case .sens: "Sens"
        case .devine: "Devine le mot"
        }
    }

    var symbol: String {
        switch self {
        case .motJuste: "text.badge.checkmark"
        case .paronymes: "arrow.left.arrow.right"
        case .justeOuFautif: "checkmark.circle"
        case .passePartout: "wand.and.stars"
        case .sens: "text.magnifyingglass"
        case .devine: "questionmark.circle"
        }
    }
}

extension ChallengeState.Kind {
    var title: LocalizedStringKey {
        switch self {
        case .rush: "Rush"
        case .sprint: "Sprint"
        case .perfection: "Perfection"
        }
    }

    var symbol: String {
        switch self {
        case .rush: "bolt"
        case .sprint: "timer"
        case .perfection: "scope"
        }
    }

    var rules: LocalizedStringKey {
        switch self {
        case .rush: "Répondez au plus vite. 5 secondes par question, 3 vies."
        case .sprint: "60 secondes pour un maximum de bonnes réponses. Les erreurs ne coûtent rien."
        case .perfection: "Sans limite de temps. La série s'arrête à la première erreur."
        }
    }
}

extension Skill {
    var title: LocalizedStringKey {
        switch self {
        case .sens: "Sens"
        case .usage: "Usage"
        case .choixDuMot: "Choix du mot"
        }
    }
}

extension Level {
    /// Description de la ligne dépliée (PRA-08). Textes à écrire (`OPEN_QUESTIONS.md` n° 12).
    var summary: LocalizedStringKey { "Niveau \(rawValue) sur 5" }
}
