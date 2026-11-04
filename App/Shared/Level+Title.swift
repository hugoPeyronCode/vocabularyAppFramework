import SagaceCore
import SwiftUI

extension Level {
    var title: LocalizedStringKey {
        switch self {
        case .debutant: "Débutant"
        case .elementaire: "Élémentaire"
        case .intermediaire: "Intermédiaire"
        case .avance: "Avancé"
        case .expert: "Expert"
        }
    }
}
