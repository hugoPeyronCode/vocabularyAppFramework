import SwiftUI

/// Formes, espacements et mouvements de `02_DESIGN_SYSTEM.md` sections 4 et 7.
public enum SagaceMetrics {
    // Espacements
    public static let pageMargin: CGFloat = 24
    public static let sheetInset: CGFloat = 12
    public static let gutter: CGFloat = 16
    public static let rowSpacing: CGFloat = 10

    // Rayons
    public static let cardRadius: CGFloat = 36
    public static let sheetRadius: CGFloat = 44
    public static let rowRadius: CGFloat = 18
    public static let metricCardRadius: CGFloat = 24

    // Hauteurs
    public static let buttonHeight: CGFloat = 56
    public static let rowHeight: CGFloat = 56
    public static let rowExpandedHeight: CGFloat = 96
    public static let chipHeight: CGFloat = 36
    public static let circleButtonSmall: CGFloat = 44
    public static let circleButtonLarge: CGFloat = 52
    public static let grabberSize = CGSize(width: 36, height: 5)

    /// Hauteur de la carte du jour, en part de l'écran.
    public static let cardHeightRatio: CGFloat = 0.62
    /// Échelle d'un bouton pressé.
    public static let pressedScale: CGFloat = 0.97
}

public enum SagaceMotion {
    /// Carte suivante dans le feed.
    public static let page = Animation.spring(duration: 0.35)
    /// Ligne d'option qui se déplie et prend sa couleur.
    public static let select = Animation.spring(duration: 0.3, bounce: 0.2)
    /// Retour en ressort d'un bouton pressé.
    public static let press = Animation.spring(duration: 0.25, bounce: 0.3)
}

private struct CardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(color: colorScheme == .light ? .vCardShadow : .clear, radius: 15, y: 10)
    }
}

public extension View {
    /// Ombre douce de la carte du jour en clair, aucune en sombre.
    func cardShadow() -> some View {
        modifier(CardShadowModifier())
    }
}
