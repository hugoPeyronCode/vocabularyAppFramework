import SwiftUI
import TipKit

// Coachmarks du feed (FEED-05), une seule fois chacun.

struct SwipeTip: Tip {
    var title: Text { Text("Glissez vers le haut pour la fiche suivante.") }
    var image: Image? { Image(systemName: "hand.draw") }
}

struct SortTip: Tip {
    @Parameter static var hasSwiped: Bool = false

    var title: Text { Text("Triez : je savais, ou à retenir.") }
    var image: Image? { Image(systemName: "checkmark.circle") }
    var rules: [Rule] { #Rule(Self.$hasSwiped) { $0 } }
}

struct InfoTip: Tip {
    @Parameter static var hasSorted: Bool = false

    var title: Text { Text("Touchez i pour les nuances et les sources") }
    var image: Image? { Image(systemName: "info.circle") }
    var rules: [Rule] { #Rule(Self.$hasSorted) { $0 } }
}

/// Au 3e jour d'utilisation.
struct WidgetTip: Tip {
    @Parameter static var daysSinceInstall: Int = 0

    var title: Text { Text("Une fiche sur votre écran d'accueil.") }
    var message: Text? { Text("Touchez longuement l'écran d'accueil, puis Modifier, puis Ajouter un widget, et cherchez Sagace.") }
    var image: Image? { Image(systemName: "square.text.square") }
    var rules: [Rule] { #Rule(Self.$daysSinceInstall) { $0 >= 2 } }
}
