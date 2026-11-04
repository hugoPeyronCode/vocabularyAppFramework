import SwiftUI

/// Anneau de progression de l'objectif du jour (frise des jours). Plein quand l'objectif est atteint.
public struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat

    public init(progress: Double, lineWidth: CGFloat = 3) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.vSeparator, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.vTextPrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.vTextPrimary)
                    .transition(.scale)
            }
        }
        .animation(SagaceMotion.select, value: progress)
        .accessibilityHidden(true)
    }
}
