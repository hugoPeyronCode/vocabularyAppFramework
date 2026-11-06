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

    // iPad (`09_IPAD.md`)
    /// Largeur maximale d'une colonne de lecture (feed, fiche, listes).
    public static let readableWidth: CGFloat = 640
    /// Largeur maximale d'un écran de concentration : onboarding, question de jeu.
    public static let focusWidth: CGFloat = 560
    /// Hauteur maximale de l'onboarding, centré dans l'écran.
    public static let focusHeight: CGFloat = 860
    /// Taille maximale d'une sheet flottante sur iPad.
    public static let sheetMaxSize = CGSize(width: 700, height: 880)
    /// Largeur d'une sheet en deux colonnes (Explorer).
    public static let wideSheetWidth: CGFloat = 900
    /// Marge minimale entre une sheet iPad et les bords de la fenêtre, pour qu'elle reste flottante.
    public static let sheetWindowMargin: CGFloat = 40
    /// Colonne de gauche d'une sheet en deux colonnes.
    public static let sidebarWidth: CGFloat = 340
    /// Colonne de la carte quand le feed est en deux colonnes.
    public static let feedCardColumnWidth: CGFloat = 520
    /// Largeur à partir de laquelle la mise en page s'élargit (`LayoutWidth.regular`).
    public static let regularLayoutMinWidth: CGFloat = 600
    /// Largeur à partir de laquelle le feed passe en deux colonnes (`LayoutWidth.wide`).
    public static let wideLayoutMinWidth: CGFloat = 1000

    /// Largeur d'une sheet iPad : `maximum`, réduite pour garder une marge dans une fenêtre plus étroite
    /// (fenêtre pas encore mesurée : `maximum`).
    public static func sheetWidth(_ maximum: CGFloat, inWindow window: CGFloat) -> CGFloat {
        guard window > 0 else { return maximum }
        return min(maximum, max(window - 2 * sheetWindowMargin, 0))
    }
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
    /// Ombre douce de la carte du jour en clair, aucune en sombre. À poser sur une forme, pas sur un conteneur de texte.
    func cardShadow() -> some View {
        modifier(CardShadowModifier())
    }

    /// Fond de carte du jour : `surface`, rayon 36, ombre douce en clair portée par la forme seule.
    func cardBackground() -> some View {
        background {
            RoundedRectangle(cornerRadius: SagaceMetrics.cardRadius, style: .continuous)
                .fill(.vSurface)
                .cardShadow()
        }
    }
}
