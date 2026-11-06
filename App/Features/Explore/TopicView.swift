import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Famille ou thème (EXP-02). Gratuit : 3 fiches puis le bandeau PRO ; suivre est réservé au premium.
@MainActor @Observable
final class TopicViewModel {
    struct Row: Identifiable, Hashable {
        let fiche: Fiche
        let status: FicheStatus
        var id: String { fiche.id }
    }

    let kind: TopicKind
    let title: String
    let intro: String?
    let symbol: String
    private(set) var rows: [Row] = []
    private(set) var isFollowed = false

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying

    init(kind: TopicKind, content: ContentRepository, topics: Topics, store: any ProgressStoring,
         entitlements: any PremiumProviding, haptics: any HapticPlaying) {
        self.kind = kind; self.content = content; self.store = store; self.entitlements = entitlements; self.haptics = haptics
        switch kind {
        case .family(let family):
            let info = topics.families.first { $0.id == family }
            title = info?.name ?? ""
            intro = info?.intro
            symbol = family.symbol
        case .theme(let theme):
            title = topics.themes.first { $0.id == theme }?.name ?? ""
            intro = nil
            symbol = ThemeSymbol.symbol(for: theme)
        }
    }

    var isPremium: Bool { entitlements.isPremium }

    /// "S'entraîner sur cette famille" (EXP-02), ou sur les fiches du thème.
    var practiceRequest: PracticeRequest {
        switch kind {
        case .family(let family): .family(family)
        case .theme: .fiches(rows.map(\.fiche.id))
        }
    }

    /// Fiches visibles : toutes en premium, les 3 premières en gratuit.
    var visibleRows: [Row] { isPremium ? rows : Array(rows.prefix(Rules.freeFichesPerTopic)) }
    var isLocked: Bool { !isPremium && rows.count > Rules.freeFichesPerTopic }

    func load() {
        let progress = store.allProgress()
        let fiches = switch kind {
        case .family(let family): content.fiches(in: family)
        case .theme(let theme): content.fiches(theme: theme)
        }
        rows = fiches
            .sorted { $0.headword.localizedCompare($1.headword) == .orderedAscending }
            .map { Row(fiche: $0, status: FicheStatus(progress: progress[$0.id])) }
        let preferences = store.preferences
        isFollowed = switch kind {
        case .family(let family): preferences.followedFamilies.contains(family.rawValue)
        case .theme(let theme): preferences.followedThemes.contains(theme)
        }
    }

    /// Suivre filtre le feed sur cette famille ou ce thème (premium).
    func toggleFollow() {
        let preferences = store.preferences
        switch kind {
        case .family(let family):
            preferences.followedFamilies.toggleMembership(family.rawValue)
        case .theme(let theme):
            preferences.followedThemes.toggleMembership(theme)
        }
        store.save()
        haptics.play(.light)
        load()
    }
}

extension Array where Element: Equatable {
    mutating func toggleMembership(_ element: Element) {
        if let index = firstIndex(of: element) { remove(at: index) } else { append(element) }
    }
}

struct TopicView: View {
    @State var viewModel: TopicViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetPage(verbatim: viewModel.title) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: viewModel.symbol)
                            .symbolVariant(.fill)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.vTextPrimary)
                            .frame(width: 64, height: 64)
                            .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                            .accessibilityHidden(true)
                        if let intro = viewModel.intro {
                            Text(verbatim: intro).textStyle(.definition)
                        }
                    }
                    HStack(spacing: 10) {
                        if viewModel.isFollowed {
                            SecondaryButton("Suivi", systemImage: "checkmark", haptic: nil) { viewModel.toggleFollow() }
                        } else {
                            PrimaryButton("Suivre", systemImage: viewModel.isPremium ? "plus" : "lock.fill", haptic: nil) {
                                router.requirePremium(.proBanner, isPremium: viewModel.isPremium) { viewModel.toggleFollow() }
                            }
                        }
                        SecondaryButton("S'entraîner", systemImage: "play.fill") { router.open(.session(viewModel.practiceRequest)) }
                    }
                    VStack(spacing: SagaceMetrics.rowSpacing) {
                        if viewModel.visibleRows.isEmpty {
                            EmptyState(systemImage: "rectangle.stack", text: "Pas encore de fiche ici. De nouvelles arrivent chaque mois.")
                        }
                        ForEach(viewModel.visibleRows) { row in
                            NavigationLink(value: AppRoute.fiche(row.fiche.id)) {
                                FicheRow(fiche: row.fiche, status: row.status)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                        if viewModel.isLocked {
                            ProBanner { router.stackedPaywall = .lockedFiche }
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 24)
            }
        }
        .onAppear { viewModel.load() }
    }
}
