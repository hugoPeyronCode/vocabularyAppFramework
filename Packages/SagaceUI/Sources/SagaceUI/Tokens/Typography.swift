import SwiftUI
import UIKit

/// Styles de texte de `02_DESIGN_SYSTEM.md` section 3, tous en SF Pro.
/// Les tailles sont celles d'un écran de 393 pt et suivent Dynamic Type via le style de référence.
public enum SagaceTextStyle: CaseIterable, Sendable {
    case hero, heroGhost, title, sheetTitle, rowTitle, body, definition, meta, metricValue, metricLabel, button, tab, keypad

    var size: CGFloat {
        switch self {
        case .hero: 40
        case .heroGhost: 36
        case .title: 26
        case .sheetTitle: 20
        case .rowTitle: 19
        case .body: 15
        case .definition: 17
        case .meta: 15
        case .metricValue: 28
        case .metricLabel: 12
        case .button: 20
        case .tab: 17
        case .keypad: 30
        }
    }

    var weight: Font.Weight {
        switch self {
        case .hero, .heroGhost: .heavy
        case .title, .sheetTitle, .metricValue: .bold
        case .rowTitle, .metricLabel, .button, .tab: .semibold
        case .meta: .medium
        case .body, .definition, .keypad: .regular
        }
    }

    var monospacedDigits: Bool { self == .meta || self == .metricValue }

    /// Style système dont la courbe Dynamic Type est appliquée.
    var relativeTo: UIFont.TextStyle {
        switch self {
        case .hero, .heroGhost: .largeTitle
        case .title, .metricValue, .keypad: .title1
        case .sheetTitle, .button: .title3
        case .rowTitle, .definition, .tab: .body
        case .body, .meta: .subheadline
        case .metricLabel: .caption1
        }
    }

    /// Couleur par défaut du style.
    var defaultColor: Color {
        switch self {
        case .heroGhost: .vTextGhost
        case .body, .meta, .metricLabel: .vTextSecondary
        default: .vTextPrimary
        }
    }

    func font(for dynamicTypeSize: DynamicTypeSize) -> Font {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let scaled = UIFontMetrics(forTextStyle: relativeTo).scaledValue(for: size, compatibleWith: traits)
        let font = Font.system(size: scaled, weight: weight)
        return monospacedDigits ? font.monospacedDigit() : font
    }
}

private struct SagaceTextModifier: ViewModifier {
    let style: SagaceTextStyle
    let colored: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if colored {
            content.font(style.font(for: dynamicTypeSize)).foregroundStyle(style.defaultColor)
        } else {
            content.font(style.font(for: dynamicTypeSize))
        }
    }
}

public extension View {
    /// Applique un style de texte Sagace avec sa couleur par défaut.
    func textStyle(_ style: SagaceTextStyle) -> some View {
        modifier(SagaceTextModifier(style: style, colored: true))
    }

    /// Applique seulement la police d'un style, la couleur venant du contexte.
    func fontStyle(_ style: SagaceTextStyle) -> some View {
        modifier(SagaceTextModifier(style: style, colored: false))
    }
}

private extension UIContentSizeCategory {
    init(_ size: DynamicTypeSize) {
        self = switch size {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}
