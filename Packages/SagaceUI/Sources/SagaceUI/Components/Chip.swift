import SwiftUI

/// Capsule 36 pt : filtres de stats, chip série, confusions.
/// Active en `inverseSurface`, inactive en `surfaceRaised`.
public struct Chip: View {
    let title: Text
    let systemImage: String?
    let isActive: Bool
    let haptic: HapticEvent?
    let action: (() -> Void)?
    @Environment(\.haptics) private var haptics

    /// Sans `action`, la chip est un simple libellé (pas de bouton).
    public init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        isActive: Bool = false,
        haptic: HapticEvent? = .selection,
        action: (() -> Void)? = nil
    ) {
        self.title = Text(title); self.systemImage = systemImage; self.isActive = isActive
        self.haptic = haptic; self.action = action
    }

    /// Chip dont le texte vient du contenu (mot, synonyme) et n'est pas localisé.
    public init(
        verbatim title: String,
        systemImage: String? = nil,
        isActive: Bool = false,
        haptic: HapticEvent? = .selection,
        action: (() -> Void)? = nil
    ) {
        self.title = Text(verbatim: title); self.systemImage = systemImage; self.isActive = isActive
        self.haptic = haptic; self.action = action
    }

    public var body: some View {
        if let action {
            Button { haptic.map(haptics.play); action() } label: { label }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityAddTraits(isActive ? .isSelected : [])
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).symbolVariant(.fill)
            }
            title
        }
        .fontStyle(.meta)
        .fontWeight(.semibold)
        .lineLimit(1)
        .fixedSize()
        .foregroundStyle(isActive ? Color.vOnInverse : .vTextPrimary)
        .padding(.horizontal, 14)
        .frame(minHeight: SagaceMetrics.chipHeight)
        .background(isActive ? Color.vInverse : .vSurfaceRaised, in: .capsule)
        .animation(SagaceMotion.select, value: isActive)
    }
}
