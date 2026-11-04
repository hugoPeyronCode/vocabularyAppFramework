import SwiftUI

/// Bandeau violet "réservé aux membres PRO" avec bouton Débloquer (verrou de toute section premium).
public struct ProBanner: View {
    let title: Text
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    public init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = Text(title)
        self.action = action
    }

    /// Libellé par défaut du catalogue de `SagaceUI`.
    public init(action: @escaping () -> Void) {
        self.title = Text("Réservé aux membres PRO", bundle: .module)
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 12) {
            title
                .fontStyle(.rowTitle)
                .foregroundStyle(.vOnAccent)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                haptics.play(.light)
                action()
            } label: {
                Text("Débloquer", bundle: .module)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.vOnAccent)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 40)
                    .background(.vPurpleSoft, in: .capsule)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.vPurple, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }
}
