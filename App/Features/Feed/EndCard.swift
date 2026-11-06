import SagaceCore
import SagaceUI
import SwiftUI

/// Carte de fin du lot (FEED-04).
struct EndCardView: View {
    let hoursToNextBatch: Int?
    let isPremium: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.vTextPrimary)
                .accessibilityHidden(true)
            Text("C'est tout pour aujourd'hui.")
                .textStyle(.title)
                .multilineTextAlignment(.center)
            if let hours = hoursToNextBatch {
                Text("Prochain lot dans \(hours) h.")
                    .textStyle(.body)
            }
            Spacer()
            if !isPremium {
                PrimaryButton("Débloquer plus de fiches", systemImage: "crown.fill", action: onUnlock)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBackground()
    }
}
