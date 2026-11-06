import SwiftUI

/// Mise en page selon la largeur disponible (`09_IPAD.md`), et non selon l'appareil :
/// un iPad en Split View étroit ou en Slide Over retrouve la mise en page iPhone.
public enum LayoutWidth: Comparable, Sendable {
    /// iPhone, Split View un tiers, Slide Over : mise en page d'origine.
    case compact
    /// iPad portrait, Split View moitié, sheets iPad : colonnes centrées, grilles plus larges.
    case regular
    /// iPad paysage : le feed passe en deux colonnes.
    case wide

    public init(width: CGFloat) {
        self = switch width {
        case SagaceMetrics.wideLayoutMinWidth...: .wide
        case SagaceMetrics.regularLayoutMinWidth...: .regular
        default: .compact
        }
    }

    public var isRegular: Bool { self != .compact }
}

public extension EnvironmentValues {
    /// Largeur du conteneur le plus proche qui la mesure (feed, sheet).
    @Entry var layoutWidth: LayoutWidth = .compact
}

public extension View {
    /// Suit la largeur de la vue dans `width`.
    func readsLayoutWidth(_ width: Binding<LayoutWidth>) -> some View {
        onGeometryChange(for: LayoutWidth.self) { LayoutWidth(width: $0.size.width) } action: { width.wrappedValue = $0 }
    }

    /// Mesure la largeur de la vue et la publie dans `layoutWidth` pour son contenu.
    func measuresLayoutWidth() -> some View {
        modifier(LayoutWidthMeasure())
    }

    /// Centre la vue dans une colonne de `maxWidth` au plus. Sans effet sur iPhone, plus étroit.
    func readableColumn(_ maxWidth: CGFloat = SagaceMetrics.readableWidth) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}

private struct LayoutWidthMeasure: ViewModifier {
    @State private var width = LayoutWidth.compact

    func body(content: Content) -> some View {
        content
            .environment(\.layoutWidth, width)
            .readsLayoutWidth($width)
    }
}
