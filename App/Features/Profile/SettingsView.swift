import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import StoreKit
import SwiftUI
import UIKit

/// Réglages (SET-01) et apparence (APP-01). Écrit directement dans `Preferences`, effets appliqués aussitôt.
@MainActor @Observable
final class SettingsViewModel {
    enum Tab: Hashable { case content, effects, notifications, account }

    var tab: Tab = .content
    private(set) var restoreMessage: LocalizedStringKey?

    private let store: any ProgressStoring
    private let entitlements: EntitlementService
    private let haptics: HapticsService
    private let reminders: ReminderScheduler

    init(store: any ProgressStoring, entitlements: EntitlementService, haptics: HapticsService, reminders: ReminderScheduler) {
        self.store = store; self.entitlements = entitlements; self.haptics = haptics; self.reminders = reminders
    }

    private var preferences: Preferences { store.preferences }
    var isPremium: Bool { entitlements.isPremium }

    // MARK: Contenu

    var dailyGoal: Int { preferences.dailyGoal }

    /// Le rythme de 10 fiches est réservé au premium. Renvoie `false` s'il faut le paywall.
    func setDailyGoal(_ goal: Int) -> Bool {
        guard goal != Rules.premiumDailyGoal || isPremium else { return false }
        preferences.dailyGoal = goal
        store.save()
        haptics.play(.soft)
        return true
    }

    var level: Level { Level(rawValue: store.profile.level) ?? Rules.defaultLevel }

    var showFamiliar: Bool {
        get { preferences.showFamiliar }
        set { preferences.showFamiliar = newValue; store.save(); haptics.play(.selection) }
    }

    var mutedTerms: [String] { preferences.mutedTerms }

    func unmute(_ term: String) {
        preferences.mutedTerms.removeAll { $0 == term }
        store.save()
        haptics.play(.light)
    }

    // MARK: Effets

    var soundMode: SoundMode {
        get { preferences.soundMode }
        set { preferences.soundMode = newValue; store.save(); haptics.play(.selection) }
    }

    var hapticsEnabled: Bool {
        get { preferences.hapticsEnabled }
        set {
            preferences.hapticsEnabled = newValue
            store.save()
            haptics.isEnabled = newValue
            haptics.play(.selection)
        }
    }

    var animationsEnabled: Bool {
        get { preferences.animationsEnabled }
        set { preferences.animationsEnabled = newValue; store.save(); haptics.play(.selection) }
    }

    // MARK: Notifications

    var eveningReminder: Bool {
        get { preferences.eveningStreakReminder }
        set {
            preferences.eveningStreakReminder = newValue
            store.save()
            haptics.play(.selection)
            Task { await reminders.reschedule() }
        }
    }

    // MARK: Compte

    var userID: String { store.profile.userID }

    func copyUserID() {
        UIPasteboard.general.string = userID
        haptics.play(.success)
    }

    func restore() async {
        do {
            try await entitlements.restore()
            restoreMessage = entitlements.isPremium ? "Achats restaurés." : "Aucun achat à restaurer."
        } catch {
            restoreMessage = "L'achat n'a pas abouti. Aucun montant n'a été débité."
        }
    }

    // MARK: Apparence

    var appearance: Appearance {
        get { preferences.appearance }
        set { preferences.appearance = newValue; store.save(); haptics.play(.selection) }
    }
}

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @State private var isManagingSubscription = false
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetPage("Réglages") {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                        switch viewModel.tab {
                        case .content: contentTab
                        case .effects: effectsTab
                        case .notifications: notificationsTab
                        case .account: accountTab
                        }
                    }
                    .padding(.horizontal, SagaceMetrics.pageMargin)
                    .padding(.bottom, 16)
                }
                BottomTabs([
                    .init(.content, title: "Contenu", systemImage: "text.book.closed"),
                    .init(.effects, title: "Effets", systemImage: "sparkles"),
                    .init(.notifications, title: "Notifications", systemImage: "bell"),
                    .init(.account, title: "Compte", systemImage: "person.crop.circle"),
                ], selection: $viewModel.tab)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
    }

    // MARK: Onglets

    @ViewBuilder
    private var contentTab: some View {
        sectionTitle("Rythme")
        ForEach([(3, "3 fiches"), (5, "5 fiches"), (10, "10 fiches")] as [(Int, LocalizedStringKey)], id: \.0) { goal, title in
            OptionRow(title, detail: goal == Rules.premiumDailyGoal && !viewModel.isPremium ? "PRO" : nil, isSelected: viewModel.dailyGoal == goal, haptic: nil) {
                if !viewModel.setDailyGoal(goal) { router.stackedPaywall = .proBanner }
            }
        }
        sectionTitle("Niveau")
        HStack {
            Label { Text(viewModel.level.title).fontStyle(.rowTitle) } icon: { Image(systemName: viewModel.level.symbol) }
                .foregroundStyle(viewModel.level.selectedForeground)
            Spacer()
            Button("Repasser le test") { router.open(.levelTest) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewModel.level.selectedForeground)
        }
        .padding(16)
        .background(viewModel.level.selectedBackground, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        NavigationLink(value: AppRoute.editFollows) {
            settingRow("Familles et thèmes suivis", symbol: "square.grid.2x2", trailing: Image(systemName: "chevron.right"))
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!viewModel.isPremium)
        .overlay {
            if !viewModel.isPremium {
                Color.clear.contentShape(.rect).onTapGesture { router.stackedPaywall = .proBanner }
            }
        }
        toggle("Afficher les expressions familières", symbol: "bubble.left", isOn: $viewModel.showFamiliar)
        sectionTitle("Mots masqués")
        if viewModel.mutedTerms.isEmpty {
            Text("Aucun mot masqué.").textStyle(.body)
        } else {
            ForEach(viewModel.mutedTerms, id: \.self) { term in
                HStack {
                    Text(verbatim: term).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                    Spacer()
                    Button("Afficher") { viewModel.unmute(term) }.font(.subheadline.weight(.semibold)).foregroundStyle(.vBlue)
                }
                .padding(16)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var effectsTab: some View {
        sectionTitle("Sons")
        HStack(spacing: 12) {
            soundButton(.muted, symbol: "speaker.slash.fill", label: "Muet")
            soundButton(.effects, symbol: "speaker.wave.2.fill", label: "Effets")
            soundButton(.effectsAndAmbience, symbol: "music.note", label: "Effets et ambiance")
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.vSurfaceRaised, in: .capsule)
        toggle("Retour haptique", symbol: "iphone.radiowaves.left.and.right", isOn: $viewModel.hapticsEnabled)
        toggle("Animations", symbol: "sparkles", isOn: $viewModel.animationsEnabled)
    }

    private func soundButton(_ mode: SoundMode, symbol: String, label: LocalizedStringKey) -> some View {
        Button { viewModel.soundMode = mode } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(viewModel.soundMode == mode ? Color.vOnInverse : .vTextSecondary)
                .frame(width: 56, height: 56)
                .background(viewModel.soundMode == mode ? Color.vInverse : .clear, in: .circle)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(viewModel.soundMode == mode ? .isSelected : [])
    }

    @ViewBuilder
    private var notificationsTab: some View {
        NavigationLink(value: AppRoute.reminders) {
            settingRow("Rappels", symbol: "bell", trailing: Image(systemName: "chevron.right"))
        }
        .buttonStyle(PressScaleButtonStyle())
        toggle("Rappel du soir si la série est en danger", symbol: "moon.stars", isOn: $viewModel.eveningReminder)
    }

    @ViewBuilder
    private var accountTab: some View {
        Button { isManagingSubscription = true } label: {
            settingRow("Gérer l'abonnement", symbol: "creditcard", trailing: Image(systemName: "chevron.right"))
        }
        .buttonStyle(PressScaleButtonStyle())
        Button { Task { await viewModel.restore() } } label: {
            settingRow("Restaurer les achats", symbol: "arrow.clockwise", trailing: Image(systemName: "chevron.right"))
        }
        .buttonStyle(PressScaleButtonStyle())
        if let message = viewModel.restoreMessage {
            Text(message).textStyle(.body)
        }
        Button { viewModel.copyUserID() } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("Identifiant utilisateur", systemImage: "number").fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                Text(verbatim: viewModel.userID).font(.footnote.monospaced()).foregroundStyle(.vTextSecondary)
                Text("Touchez pour copier").font(.caption).foregroundStyle(.vTextSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        if let privacy = AppLinks.privacy {
            ExternalLink(url: privacy) { settingRow("Confidentialité", symbol: "hand.raised", trailing: Image(systemName: "arrow.up.right")) }
        }
        if let terms = AppLinks.terms {
            ExternalLink(url: terms) { settingRow("Conditions", symbol: "doc.text", trailing: Image(systemName: "arrow.up.right")) }
        }
    }

    // MARK: Lignes

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title).textStyle(.metricLabel).textCase(.uppercase).padding(.top, 10)
    }

    private func toggle(_ title: LocalizedStringKey, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: symbol).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
        }
        .tint(.vTextPrimary)
        .padding(16)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
    }

    private func settingRow(_ title: LocalizedStringKey, symbol: String, trailing: Image) -> some View {
        HStack {
            Label(title, systemImage: symbol).fontStyle(.rowTitle)
            Spacer()
            trailing.font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
        }
        .foregroundStyle(.vTextPrimary)
        .padding(16)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .contentShape(.rect)
    }
}
