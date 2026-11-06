import SagaceCore
import SwiftUI

/// Les 5 niveaux reprennent les 5 couleurs de difficulté de Sudoku a Day.
public extension Level {
    /// Pastille ou point du niveau à l'état repos.
    var tint: Color {
        switch self {
        case .debutant: .vLevelDebutantDot
        case .elementaire: .vLevelElementaire
        case .intermediaire: .vLevelIntermediaire
        case .avance: .vLevelAvance
        case .expert: .vInverse
        }
    }

    /// Fond de la ligne sélectionnée.
    var selectedBackground: Color {
        switch self {
        case .debutant: .vLevelDebutantSelected
        case .elementaire, .intermediaire, .avance: tint
        case .expert: .vInverse
        }
    }

    /// Texte de la ligne sélectionnée.
    var selectedForeground: Color {
        self == .expert ? .vOnInverse : .vOnAccent
    }

    /// Le bronze est le contraste le plus juste avec du blanc : texte en gras dessus.
    var needsBoldText: Bool { self == .avance }

    /// Symbole SF du niveau, rempli comme dans le sélecteur de difficulté.
    var symbol: String {
        switch self {
        case .debutant, .elementaire, .intermediaire: "circle.fill"
        case .avance: "star.fill"
        case .expert: "crown.fill"
        }
    }
}
