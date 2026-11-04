import SwiftUI

// Boutons capsule et ronds de `02_DESIGN_SYSTEM.md` section 4.
// Chaque bouton joue un retour haptique (par défaut `.light`) avant son action.

/// Style capsule pleine largeur, 56 pt, avec échelle 0,97 au toucher.
public struct CapsuleButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// Bleu, texte blanc : action principale et premium.
        case primary
        /// `surfaceRaised`, texte principal.
        case secondary
        /// `inverseSurface` : confirmation ("Oui, recommencer").
        case confirm
    }

    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontStyle(.button)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: SagaceMetrics.buttonHeight)
            .padding(.horizontal, 20)
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed), in: .capsule)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? SagaceMetrics.pressedScale : 1)
            .animation(SagaceMotion.press, value: configuration.isPressed)
            .contentShape(.capsule)
    }

    private var foreground: Color {
        switch kind {
        case .primary: .vOnAccent
        case .secondary: .vTextPrimary
        case .confirm: .vOnInverse
        }
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary: pressed ? .vBluePressed : .vBlue
        case .secondary: .vSurfaceRaised
        case .confirm: .vInverse
        }
    }
}

/// Bouton principal : capsule bleue pleine largeur.
public struct PrimaryButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let haptic: HapticEvent?
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    public init(_ title: LocalizedStringKey, systemImage: String? = nil, haptic: HapticEvent? = .light, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.haptic = haptic; self.action = action
    }

    public var body: some View {
        Button { haptic.map(haptics.play); action() } label: { CapsuleLabel(title: title, systemImage: systemImage) }
            .buttonStyle(CapsuleButtonStyle(.primary))
    }
}

/// Bouton secondaire : même forme, `surfaceRaised`.
public struct SecondaryButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let haptic: HapticEvent?
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    public init(_ title: LocalizedStringKey, systemImage: String? = nil, haptic: HapticEvent? = .light, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.haptic = haptic; self.action = action
    }

    public var body: some View {
        Button { haptic.map(haptics.play); action() } label: { CapsuleLabel(title: title, systemImage: systemImage) }
            .buttonStyle(CapsuleButtonStyle(.secondary))
    }
}

/// Bouton de confirmation : capsule `inverseSurface` avec check, à côté d'un `CircleButton` retour.
public struct ConfirmButton: View {
    let title: LocalizedStringKey
    let haptic: HapticEvent?
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    public init(_ title: LocalizedStringKey, haptic: HapticEvent? = .light, action: @escaping () -> Void) {
        self.title = title; self.haptic = haptic; self.action = action
    }

    public var body: some View {
        Button { haptic.map(haptics.play); action() } label: { CapsuleLabel(title: title, systemImage: "checkmark") }
            .buttonStyle(CapsuleButtonStyle(.confirm))
    }
}

private struct CapsuleLabel: View {
    let title: LocalizedStringKey
    let systemImage: String?

    var body: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

/// Bouton rond 44 à 52 pt à icône SF remplie.
public struct CircleButton: View {
    public enum Kind: Sendable {
        /// `surfaceRaised` : actions du feed, retour, fermer.
        case raised
        /// Bleu : couronne premium.
        case accent
    }

    let systemImage: String
    let accessibilityLabel: Text
    let kind: Kind
    let size: CGFloat
    let isActive: Bool
    let haptic: HapticEvent?
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    /// - Parameter isActive: le symbole passe en version remplie (`bookmark` → `bookmark.fill`).
    public init(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey,
        kind: Kind = .raised,
        size: CGFloat = SagaceMetrics.circleButtonSmall,
        isActive: Bool = false,
        haptic: HapticEvent? = .light,
        action: @escaping () -> Void
    ) {
        self.init(systemImage: systemImage, accessibilityText: Text(accessibilityLabel), kind: kind, size: size, isActive: isActive, haptic: haptic, action: action)
    }

    /// Pour les libellés du catalogue de `SagaceUI` lui-même.
    init(
        systemImage: String,
        accessibilityText: Text,
        kind: Kind = .raised,
        size: CGFloat = SagaceMetrics.circleButtonSmall,
        isActive: Bool = false,
        haptic: HapticEvent? = .light,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage; self.accessibilityLabel = accessibilityText; self.kind = kind
        self.size = size; self.isActive = isActive; self.haptic = haptic; self.action = action
    }

    public var body: some View {
        Button { haptic.map(haptics.play); action() } label: {
            Image(systemName: systemImage)
                .symbolVariant(isActive ? .fill : .none)
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(kind == .accent ? Color.vOnAccent : .vTextPrimary)
                .frame(width: size, height: size)
                .background(kind == .accent ? Color.vBlue : .vSurfaceRaised, in: .circle)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Échelle 0,97 au toucher, retour en ressort.
public struct PressScaleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? SagaceMetrics.pressedScale : 1)
            .animation(SagaceMotion.press, value: configuration.isPressed)
    }
}
