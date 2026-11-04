import SwiftUI

/// Tuile `surfaceRaised` rayon 24 : bibliothèque, familles, thèmes (EXP-01).
public struct Tile: View {
    public enum Badge: Sendable {
        case none
        /// Suivi : check.
        case followed
        /// Réservé PRO : cadenas.
        case locked
    }

    let title: Text
    let systemImage: String
    let detail: Text?
    let badge: Badge
    let action: () -> Void
    @Environment(\.haptics) private var haptics

    public init(_ title: Text, systemImage: String, detail: Text? = nil, badge: Badge = .none, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.detail = detail; self.badge = badge; self.action = action
    }

    public var body: some View {
        Button {
            haptics.play(.selection)
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: systemImage)
                        .symbolVariant(.fill)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.vTextPrimary)
                    Spacer()
                    badgeView
                }
                Spacer(minLength: 0)
                title
                    .fontStyle(.rowTitle)
                    .foregroundStyle(.vTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let detail {
                    detail.textStyle(.meta)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
            .contentShape(.rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(badge == .followed ? .isSelected : [])
    }

    @ViewBuilder
    private var badgeView: some View {
        switch badge {
        case .none: EmptyView()
        case .followed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.vTextPrimary)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.vOnAccent)
                .padding(6)
                .background(.vPurple, in: .circle)
                .accessibilityLabel(Text("Réservé aux membres PRO", bundle: .module))
        }
    }
}
