import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import StoreKit
import SwiftUI
import UIKit

/// Profil (PRO-01) : carte de soutien, carte premium, liste des réglages.
@MainActor @Observable
final class ProfileViewModel {
    private let entitlements: EntitlementService

    init(entitlements: EntitlementService) {
        self.entitlements = entitlements
    }

    var isPremium: Bool { entitlements.isPremium }
    var renewalDate: Date? { entitlements.expirationDate }
}

struct ProfileView: View {
    @State var viewModel: ProfileViewModel
    @State private var path: [AppRoute] = []
    @Environment(ScreenFactory.self) private var factory
    @Environment(AppRouter.self) private var router
    @Environment(\.requestReview) private var requestReview
    @Environment(\.haptics) private var haptics

    var body: some View {
        NavigationStack(path: $path) {
            SheetContainer("Profil", systemImage: "person.crop.circle") {
                ScrollView {
                    VStack(spacing: 16) {
                        supportCard
                        premiumCard
                        VStack(spacing: SagaceMetrics.rowSpacing) {
                            row("Rappels", symbol: "bell", route: .reminders)
                            row("Widgets", symbol: "square.text.square", route: .widgets)
                            row("Voix", symbol: "waveform", route: .voices)
                            row("Apparence", symbol: "circle.lefthalf.filled", route: .appearance)
                            row("Icône de l'app", symbol: "app.badge", route: .appIcon)
                            row("Réglages", symbol: "gearshape", route: .settings)
                            if let feedback = AppLinks.feedback {
                                Link(destination: feedback) { rowLabel("Envoyer un avis", symbol: "envelope") }
                            }
                            row("À propos", symbol: "info.circle", route: .about)
                        }
                    }
                    .padding(.horizontal, SagaceMetrics.pageMargin)
                    .padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { factory.destination($0) }
        }
        .stackedPaywall(router)
    }

    /// Carte violette "Soutenez une app indépendante".
    private var supportCard: some View {
        VStack(spacing: 12) {
            Text("Soutenez une app indépendante").textStyle(.title).foregroundStyle(.vOnAccent).multilineTextAlignment(.center)
            Text("Sagace est faite à Paris, sans pub. Une note ou un partage nous aide beaucoup.")
                .fontStyle(.body).foregroundStyle(.vOnAccent.opacity(0.9)).multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button {
                    haptics.play(.light)
                    requestReview()
                } label: { purpleButton("Noter", symbol: "star.fill") }
                ShareLink(item: String(localized: "Sagace : le mot juste, chaque jour.")) { purpleButton("Partager", symbol: "square.and.arrow.up") }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.vPurple, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
    }

    private func purpleButton(_ title: LocalizedStringKey, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.vOnAccent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.vPurpleSoft, in: .capsule)
    }

    @ViewBuilder
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isPremium {
                Label("Membre Premium", systemImage: "crown.fill").fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                if let date = viewModel.renewalDate {
                    Text("Renouvellement le \(Text(date, format: .dateTime.day().month(.wide).year()))").textStyle(.body)
                }
            } else {
                Text("Sagace Premium : jeux illimités, toutes les familles, stats, widgets.")
                    .fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                PrimaryButton("Passer à Premium", systemImage: "crown.fill") { router.stackedPaywall = .proBanner }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
    }

    private func row(_ title: LocalizedStringKey, symbol: String, route: AppRoute) -> some View {
        NavigationLink(value: route) { rowLabel(title, symbol: symbol) }
            .buttonStyle(PressScaleButtonStyle())
    }

    private func rowLabel(_ title: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).symbolVariant(.fill).font(.system(size: 18, weight: .semibold)).frame(width: 26)
            Text(title).fontStyle(.rowTitle)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
        }
        .foregroundStyle(.vTextPrimary)
        .padding(.horizontal, 18)
        .frame(minHeight: SagaceMetrics.rowHeight)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
        .contentShape(.rect)
    }
}

// MARK: - APP-01 Apparence

struct AppearanceView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        SheetPage("Apparence") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                option(.automatic, title: "Automatique", symbol: "circle.lefthalf.filled")
                option(.light, title: "Clair", symbol: "sun.max.fill")
                option(.dark, title: "Sombre", symbol: "moon.fill")
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
    }

    private func option(_ appearance: Appearance, title: LocalizedStringKey, symbol: String) -> some View {
        Button { viewModel.appearance = appearance } label: {
            HStack(spacing: 14) {
                preview(appearance)
                Label(title, systemImage: symbol).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                Spacer()
                if viewModel.appearance == appearance {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(.vBlue)
                }
            }
            .padding(12)
            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
            .overlay {
                if viewModel.appearance == appearance {
                    RoundedRectangle(cornerRadius: SagaceMetrics.rowRadius, style: .continuous).strokeBorder(.vBlue, lineWidth: 3)
                }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(viewModel.appearance == appearance ? .isSelected : [])
    }

    /// Aperçu miniature : carte claire, sombre, ou les deux.
    private func preview(_ appearance: Appearance) -> some View {
        HStack(spacing: 0) {
            if appearance != .dark { miniCard(.light) }
            if appearance != .light { miniCard(.dark) }
        }
        .frame(width: 64, height: 44)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }

    private func miniCard(_ scheme: ColorScheme) -> some View {
        ZStack {
            Color.vBackground
            RoundedRectangle(cornerRadius: 4).fill(.vSurface).padding(6)
            Capsule().fill(.vTextPrimary).frame(width: 14, height: 3)
        }
        .environment(\.colorScheme, scheme)
    }
}

// MARK: - ICO-01 Icône de l'app

@MainActor @Observable
final class AppIconViewModel {
    /// Icônes alternatives provisoires, en attendant l'icône définitive (M9).
    static let icons = ["Bleu", "Violet", "Rouge", "Bronze", "Nuit", "Papier"]
    private(set) var current: String?
    private let haptics: any HapticPlaying

    init(haptics: any HapticPlaying) {
        self.haptics = haptics
        current = UIApplication.shared.alternateIconName
    }

    func select(_ name: String) async {
        let iconName = "AppIcon\(name)"
        guard current != iconName else { return }
        do {
            try await UIApplication.shared.setAlternateIconName(iconName)
            current = iconName
            haptics.play(.success)
        } catch {
            haptics.play(.error)
        }
    }
}

struct AppIconView: View {
    @State var viewModel: AppIconViewModel

    var body: some View {
        SheetPage("Icône de l'app") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: SagaceMetrics.gutter), count: 3), spacing: SagaceMetrics.gutter) {
                ForEach(AppIconViewModel.icons, id: \.self) { name in
                    Button { Task { await viewModel.select(name) } } label: {
                        Image("IconPreview\(name)")
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 22, style: .continuous))
                            .overlay(alignment: .bottomTrailing) {
                                if viewModel.current == "AppIcon\(name)" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.vOnAccent, .vBlue)
                                        .padding(6)
                                }
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityLabel(Text(verbatim: name))
                    .accessibilityAddTraits(viewModel.current == "AppIcon\(name)" ? .isSelected : [])
                }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
    }
}

// MARK: - VOI-01 Voix

@MainActor @Observable
final class VoicesViewModel {
    struct Voice: Identifiable, Hashable {
        let id: String
        let name: String
        let language: String
        let isEnhanced: Bool
    }

    let voices: [Voice]
    private(set) var selected: String?
    private let store: any ProgressStoring
    private let audio: AudioService
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying

    init(store: any ProgressStoring, audio: AudioService, entitlements: any PremiumProviding, haptics: any HapticPlaying) {
        self.store = store; self.audio = audio; self.entitlements = entitlements; self.haptics = haptics
        voices = AudioService.frenchVoices.map {
            Voice(id: $0.identifier, name: $0.name, language: $0.language, isEnhanced: $0.quality != .default)
        }
        selected = store.preferences.voiceIdentifier ?? voices.first?.id
    }

    var isPremium: Bool { entitlements.isPremium }

    /// Gratuit : la première voix seulement.
    func isLocked(_ voice: Voice) -> Bool { !isPremium && voice.id != voices.first?.id }

    func listen(_ voice: Voice) {
        audio.preview(String(localized: "Le départ est imminent, l'invité est éminent."), voiceIdentifier: voice.id)
    }

    func select(_ voice: Voice) {
        selected = voice.id
        store.preferences.voiceIdentifier = voice.id
        store.save()
        audio.voiceIdentifier = voice.id
        haptics.play(.light)
    }
}

struct VoicesView: View {
    @State var viewModel: VoicesViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetPage("Voix") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    if viewModel.voices.isEmpty {
                        EmptyState(systemImage: "waveform", text: "Aucune voix française sur cet appareil.")
                    }
                    ForEach(viewModel.voices) { voice in
                        HStack(spacing: 12) {
                            CircleButton(systemImage: "play", accessibilityLabel: "Écouter", size: 40, isActive: true) { viewModel.listen(voice) }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: voice.name).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                                Text(verbatim: voice.isEnhanced ? "\(voice.language) · \(String(localized: "Améliorée"))" : voice.language).textStyle(.meta)
                            }
                            Spacer()
                            if viewModel.isLocked(voice) {
                                Image(systemName: "lock.fill").foregroundStyle(.vPurple)
                            } else if viewModel.selected == voice.id {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(.vBlue)
                            }
                        }
                        .padding(12)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                        .contentShape(.rect)
                        .onTapGesture {
                            if viewModel.isLocked(voice) { router.stackedPaywall = .voices } else { viewModel.select(voice) }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                    }
                    if let settings = URL(string: UIApplication.openSettingsURLString) {
                        Link("Télécharger des voix de meilleure qualité dans Réglages iOS.", destination: settings)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.vBlue)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
    }
}

// MARK: - À propos

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    var body: some View {
        SheetPage("À propos") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(verbatim: "Sagace").textStyle(.hero)
                    Text("Version \(version)").textStyle(.meta)
                    Text("Fait à Paris, sans publicité.").textStyle(.definition)
                    NavigationLink(value: AppRoute.sources) {
                        HStack {
                            Label("Sources et licences", systemImage: "books.vertical").fontStyle(.rowTitle)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.vTextSecondary)
                        }
                        .foregroundStyle(.vTextPrimary)
                        .padding(16)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .padding(.top, 8)
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
    }
}
