import SagaceData
import SagaceUI
import SwiftUI

/// Écran unique de mise à jour depuis Words v3 (MIG-01).
/// "Découvrir" mènera au mini test et au rythme quand l'onboarding existera (M4) ; en attendant, les deux boutons ouvrent le feed.
struct MigrationView: View {
    let report: V3MigrationReport
    let isPremium: Bool
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.vBlue)
                .accessibilityHidden(true)
            Text("Words devient Sagace.")
                .textStyle(.hero)
                .fixedSize(horizontal: false, vertical: true)
            Text("Nouveau nom, nouvelle app : des fiches pour employer le mot juste, des révisions pour les retenir, un nouveau design clair et sombre.")
                .textStyle(.definition)
                .fixedSize(horizontal: false, vertical: true)
            if report.likedCount > 0 {
                Label("Vos mots aimés ont été gardés (\(report.likedCount)).", systemImage: "heart.fill")
                    .textStyle(.body)
            }
            if isPremium {
                Label("Votre abonnement est conservé.", systemImage: "crown.fill")
                    .textStyle(.body)
            }
            Spacer()
            PrimaryButton("Découvrir", action: onFinish)
            Button(action: onFinish) {
                Text("Passer")
                    .fontStyle(.button)
                    .foregroundStyle(.vTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(SagaceMetrics.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.vBackground)
    }
}
