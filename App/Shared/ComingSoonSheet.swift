import SagaceUI
import SwiftUI

/// Sheet d'attente pour les écrans des jalons suivants (Explorer M2, Practice M3, Paywall M4, Profil et Stats M5).
struct ComingSoonSheet: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        SheetContainer(title, systemImage: systemImage) {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(.vTextSecondary)
                    .symbolVariant(.fill)
                    .accessibilityHidden(true)
                Text("Bientôt disponible.")
                    .textStyle(.body)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
