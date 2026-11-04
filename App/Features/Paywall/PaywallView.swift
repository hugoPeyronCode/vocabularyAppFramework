import SagaceCore
import SagaceUI
import StoreKit
import SwiftUI

/// Paywall (PAY-01). Fermable dès l'arrivée.
struct PaywallView: View {
    @State var viewModel: PaywallViewModel
    /// Appelé à la fermeture ou après un achat réussi.
    var onFinish: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchase

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    CircleButton(systemImage: "xmark", accessibilityLabel: "Fermer", size: 36) { close() }
                }
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.vPurple)
                    .padding(.top, -8)
                    .accessibilityHidden(true)
                VStack(spacing: 10) {
                    Text("Fait à Paris, sans publicité")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.vBlue)
                    Text("Le mot juste, sans limite.")
                        .textStyle(.title)
                        .multilineTextAlignment(.center)
                    Text("Sagace est une petite app indépendante. Avec Premium, vous débloquez tous les jeux, toutes les familles de fiches, les stats et les widgets, et vous nous aidez à écrire de nouvelles fiches chaque mois.")
                        .textStyle(.body)
                        .multilineTextAlignment(.center)
                }
                benefits
                plans
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .background(.vSurface)
        .alert("L'achat n'a pas abouti. Aucun montant n'a été débité.", isPresented: $viewModel.showsPurchaseError) {
            Button("OK", role: .cancel) {}
        }
        .task { await viewModel.onAppear() }
        .onChange(of: viewModel.didUnlock) { _, unlocked in if unlocked { close() } }
    }

    private func close() {
        if let onFinish { onFinish() } else { dismiss() }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefit("Jeux et défis illimités", symbol: "gamecontroller.fill")
            benefit("Toutes les familles et thèmes", symbol: "square.grid.2x2.fill")
            benefit("Stats et mots maîtrisés", symbol: "chart.bar.fill")
            benefit("Widgets et rappels personnalisés", symbol: "bell.badge.fill")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
    }

    private func benefit(_ title: LocalizedStringKey, symbol: String) -> some View {
        Label { Text(title).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary) } icon: {
            Image(systemName: symbol).foregroundStyle(.vBlue)
        }
    }

    private var plans: some View {
        VStack(spacing: SagaceMetrics.rowSpacing) {
            OptionRow(
                "Hebdomadaire",
                description: viewModel.weeklyPrice.map { "\($0) par semaine, sans engagement" } ?? "Chargement des offres…",
                isSelected: viewModel.plan == .weekly,
                alwaysShowsDescription: true
            ) { viewModel.select(.weekly) }
            OptionRow(
                "À vie",
                description: viewModel.lifetimePrice.map { "\($0), une seule fois" } ?? "Chargement des offres…",
                detail: "Le plus avantageux",
                isSelected: viewModel.plan == .lifetime,
                alwaysShowsDescription: true
            ) { viewModel.select(.lifetime) }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            PrimaryButton(viewModel.plan == .lifetime ? "Acheter" : "S'abonner", haptic: .light) {
                Task { await viewModel.purchase { try await purchase($0) } }
            }
            .disabled(!viewModel.canPurchase)
            HStack(spacing: 14) {
                Button("Restaurer") { Task { await viewModel.restore() } }
                if let terms = AppLinks.terms { Link("Conditions", destination: terms) }
                if let privacy = AppLinks.privacy { Link("Confidentialité", destination: privacy) }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.vTextSecondary)
            Label("Partage familial inclus", systemImage: "person.2.fill")
                .font(.footnote)
                .foregroundStyle(.vTextSecondary)
        }
        .padding(.horizontal, SagaceMetrics.pageMargin)
        .padding(.vertical, 10)
        .background(.vSurface)
    }
}
