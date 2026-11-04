import SwiftUI

/// Ligne d'option du sélecteur de difficulté : 56 pt, rayon 18, `surfaceRaised`.
/// Sélectionnée, elle se déplie avec sa description et un check, et prend sa couleur.
public struct OptionRow: View {
    public enum SelectionStyle: Sendable {
        /// Fond coloré (niveaux, réponses) : la ligne prend la couleur et le texte passe en `foreground`.
        case fill(background: Color, foreground: Color)
        /// Contour bleu (plans du paywall, rythme).
        case outline(Color)
    }

    let title: Text
    let description: LocalizedStringKey?
    let detail: LocalizedStringKey?
    let systemImage: String?
    let iconTint: Color?
    let selectionStyle: SelectionStyle
    let isSelected: Bool
    let boldOnSelection: Bool
    let haptic: HapticEvent?
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    /// - Parameters:
    ///   - description: affichée seulement quand la ligne est sélectionnée.
    ///   - detail: texte court à droite (prix, badge).
    ///   - iconTint: couleur de l'icône au repos (point de niveau).
    ///   - boldOnSelection: texte en gras sur un fond peu contrasté (bronze).
    public init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        detail: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        iconTint: Color? = nil,
        selectionStyle: SelectionStyle = .outline(.vBlue),
        isSelected: Bool,
        boldOnSelection: Bool = false,
        haptic: HapticEvent? = .soft,
        action: @escaping () -> Void
    ) {
        self.title = Text(title); self.description = description; self.detail = detail
        self.systemImage = systemImage; self.iconTint = iconTint; self.selectionStyle = selectionStyle
        self.isSelected = isSelected; self.boldOnSelection = boldOnSelection; self.haptic = haptic
        self.action = action
    }

    /// Ligne dont le titre vient de l'utilisateur ou du contenu (nom de collection, mot) et n'est pas localisé.
    public init(
        verbatim title: String,
        detail: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        selectionStyle: SelectionStyle = .outline(.vBlue),
        isSelected: Bool,
        haptic: HapticEvent? = .soft,
        action: @escaping () -> Void
    ) {
        self.title = Text(verbatim: title); self.description = nil; self.detail = detail
        self.systemImage = systemImage; self.iconTint = nil; self.selectionStyle = selectionStyle
        self.isSelected = isSelected; self.boldOnSelection = false; self.haptic = haptic
        self.action = action
    }

    public var body: some View {
        Button { haptic.map(haptics.play); action() } label: { content }
            .buttonStyle(PressScaleButtonStyle())
            .animation(SagaceMotion.select, value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isFilled ? foreground : (iconTint ?? .vTextSecondary))
                }
                title
                    .fontStyle(.rowTitle)
                    .foregroundStyle(foreground)
                Spacer(minLength: 8)
                if let detail {
                    Text(detail)
                        .textStyle(.meta)
                        .foregroundStyle(isFilled ? foreground : .vTextSecondary)
                }
                if isSelected, isFilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(foreground)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            if isSelected, let description {
                Text(description)
                    .fontStyle(.body)
                    .fontWeight(boldOnSelection ? .semibold : .regular)
                    .foregroundStyle(isFilled ? foreground.opacity(0.9) : .vTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .fontWeight(isSelected && boldOnSelection ? .bold : nil)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: isSelected && description != nil ? SagaceMetrics.rowExpandedHeight : SagaceMetrics.rowHeight, alignment: .leading)
        .background(background, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .overlay {
            if case .outline(let color) = selectionStyle, isSelected {
                RoundedRectangle(cornerRadius: SagaceMetrics.rowRadius, style: .continuous)
                    .strokeBorder(color, lineWidth: 3)
            }
        }
        .contentShape(.rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }

    private var isFilled: Bool {
        if case .fill = selectionStyle { return isSelected }
        return false
    }

    private var foreground: Color {
        if case .fill(_, let foreground) = selectionStyle, isSelected { return foreground }
        return .vTextPrimary
    }

    private var background: Color {
        if case .fill(let background, _) = selectionStyle, isSelected { return background }
        return .vSurfaceRaised
    }
}
