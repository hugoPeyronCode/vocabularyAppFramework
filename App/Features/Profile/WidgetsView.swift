import Foundation
import Observation
import SagaceCore
import SagaceUI
import SwiftUI

/// Widgets (WID-01) : comment les ajouter, aperçu de chacun, configuration (premium).
@MainActor @Observable
final class WidgetsViewModel {
    private(set) var card: WidgetSnapshot.Card?
    private(set) var streak = 0
    private(set) var dueReviews = 0
    private(set) var progress = 0.0

    private let bridge: WidgetBridge
    private let entitlements: any PremiumProviding
    private let day: SagaceDay
    private let now: () -> Date

    init(bridge: WidgetBridge, entitlements: any PremiumProviding, day: SagaceDay, now: @escaping () -> Date) {
        self.bridge = bridge; self.entitlements = entitlements; self.day = day; self.now = now
    }

    var isPremium: Bool { entitlements.isPremium }

    func load() {
        bridge.refresh()
        guard let snapshot = bridge.snapshot else { return }
        card = snapshot.cards.first
        streak = snapshot.streak(at: now(), day: day)
        dueReviews = snapshot.dueReviewCount
        progress = min(Double(snapshot.sortedToday(at: now(), day: day)) / Double(max(snapshot.dailyGoal, 1)), 1)
    }
}

struct WidgetsView: View {
    @State var viewModel: WidgetsViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetPage("Widgets") {
            ScrollView {
                VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                    sectionTitle("Ajouter un widget")
                    VStack(alignment: .leading, spacing: 12) {
                        step(1, "Touchez longuement un espace vide de l'écran d'accueil.")
                        step(2, "Touchez Modifier, puis Ajouter un widget.")
                        step(3, "Cherchez Sagace et choisissez un widget.")
                    }
                    .padding(16)
                    .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))

                    sectionTitle("Fiche du jour")
                    Text("Petit, moyen ou grand. Le grand ajoute la phrase d'auteur ; le moyen et le grand ont « Suivante » et « À retenir ».")
                        .textStyle(.body)
                    preview { ficheTile }
                    sectionTitle("Révision")
                    Text("Répondez à vos révisions sans ouvrir l'app. Chaque réponse est expliquée, puis « Continuer ».")
                        .textStyle(.body)
                    preview { reviewTile }
                    sectionTitle("Série et écran verrouillé")
                    HStack(spacing: 12) {
                        streakTile
                        lockTile
                    }

                    sectionTitle("Configurer")
                    Text("Touchez longuement le widget, puis Modifier le widget : famille de fiches, rafraîchissement (toutes les heures, 2 fois par jour, 1 fois par jour), phrase d'auteur.")
                        .textStyle(.body)
                    if !viewModel.isPremium {
                        ProBanner("Widgets configurables avec Premium") { router.stackedPaywall = .widgets }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 16)
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: Aperçus

    private func preview<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private var ficheTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mot du jour").textStyle(.metricLabel).textCase(.uppercase)
            Text(verbatim: viewModel.card?.headword ?? "éminent")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.vTextPrimary)
            Text(verbatim: viewModel.card?.shortDefinition ?? "")
                .textStyle(.body)
                .lineLimit(2)
            if let confusion = viewModel.card?.confusion {
                Label { Text(verbatim: confusion) } icon: { Image(systemName: "arrow.left.arrow.right") }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.vTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 155)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var reviewTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.dueReviews > 0 ? "Révisions dues : \(viewModel.dueReviews)" : "Aucune révision due")
                .textStyle(.metricLabel)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.vSurfaceSelected)
                        .frame(height: 36)
                }
            }
        }
        .padding(16)
        .frame(height: 120)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var streakTile: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(.vSurfaceSelected, lineWidth: 6)
                Circle().trim(from: 0, to: viewModel.progress).stroke(.vBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                Image(systemName: "laurel.leading").font(.system(size: 22, weight: .semibold)).foregroundStyle(.vTextPrimary)
            }
            .frame(width: 64, height: 64)
            Text("Série : \(viewModel.streak) jours").font(.headline).foregroundStyle(.vTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var lockTile: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: viewModel.card?.headword ?? "").font(.headline).foregroundStyle(.vTextPrimary)
            Text(verbatim: viewModel.card?.shortDefinition ?? "").font(.caption).foregroundStyle(.vTextSecondary).lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 150)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.vOnInverse)
                .frame(width: 28, height: 28)
                .background(.vInverse, in: .circle)
            Text(text).textStyle(.body).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title).textStyle(.metricLabel).textCase(.uppercase).padding(.top, 10)
    }
}
