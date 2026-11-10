import SagaceCore
import SagaceUI
import SwiftUI
import TipKit

/// Racine permanente de l'app (FEED-01).
struct FeedView: View {
    @Bindable var viewModel: FeedViewModel
    let profileInitial: String?
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    private let swipeTip = SwipeTip()
    private let sortTip = SortTip()
    private let infoTip = InfoTip()
    private let widgetTip = WidgetTip()
    @Environment(ScreenFactory.self) private var factory
    /// iPad (`09_IPAD.md`) : colonne centrée, puis deux colonnes en paysage.
    @State private var layout = LayoutWidth.compact

    var body: some View {
        VStack(spacing: 0) {
            FeedTopBar(
                streak: viewModel.streak,
                isPremium: viewModel.isPremium,
                initial: profileInitial,
                onCrown: { router.open(.paywall(.crown)) },
                onStreak: { router.open(.stats) },
                onExplore: { router.open(.explore) },
                onProfile: { router.open(.profile) }
            )
            TipView(widgetTip)
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .readableColumn()
            if layout == .wide {
                HStack(spacing: 0) {
                    cardColumn
                        .frame(width: SagaceMetrics.feedCardColumnWidth)
                    detailPanel
                }
                .padding(.trailing, SagaceMetrics.pageMargin)
                .frame(maxWidth: SagaceMetrics.feedCardColumnWidth + SagaceMetrics.readableWidth + SagaceMetrics.pageMargin)
                .frame(maxWidth: .infinity)
            } else {
                cardColumn
            }
        }
        .readsLayoutWidth($layout)
        .environment(\.layoutWidth, layout)
        .background(.vBackground)
        .background { keyboardShortcuts }
        .toast(viewModel.goalToast) { toast in
            Toast(Text("Objectif atteint · \(toast.goal) fiches · Série : \(toast.streak) jours"), systemImage: "checkmark.seal")
        }
        .floatingSheet(isPresented: $viewModel.isShowingGameSuggestion, detents: [.medium]) {
            GameSuggestionSheet(games: viewModel.suggestedGames) { router.open(.session(.game($0))) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.sceneDidBecomeActive() }
        }
    }

    /// Carte, barre d'actions et frise : tout l'écran sur iPhone, une colonne de lecture sur iPad.
    private var cardColumn: some View {
        VStack(spacing: 0) {
            pager
            Group {
                FeedActionBar(
                    sorting: viewModel.currentSortableFicheID.flatMap { viewModel.sortings[$0] },
                    canSort: viewModel.currentSortableFicheID != nil,
                    hasFiche: viewModel.currentPage?.ficheID != nil,
                    dueReviews: viewModel.dueReviewCount,
                    showsInfo: layout != .wide,
                    sortTip: sortTip,
                    infoTip: infoTip,
                    onInfo: {
                        infoTip.invalidate(reason: .actionPerformed)
                        if let id = viewModel.currentPage?.ficheID { router.open(.fiche(id)) }
                    },
                    onShare: { if let id = viewModel.currentPage?.ficheID { router.open(.share(id)) } },
                    onGames: { router.open(.practice) },
                    onSort: { sorting in
                        sortTip.invalidate(reason: .actionPerformed)
                        InfoTip.hasSorted = true
                        viewModel.sort(sorting)
                    }
                )
                DayStrip(week: viewModel.week, hoursToNextBatch: viewModel.hoursToNextBatch) { router.open(.day($0)) }
            }
            .readableColumn()
        }
    }

    /// iPad paysage : la fiche détaillée de la carte affichée, qui suit la pagination.
    private var detailPanel: some View {
        Group {
            if let id = viewModel.currentPage?.ficheID {
                NavigationStack {
                    factory.ficheDetail(id, origin: nil, isEmbedded: true)
                        .padding(.top, 20)
                        .background(.vSurface)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: AppRoute.self) { factory.destination($0) }
                }
                .id(id)
                .transition(.opacity)
            } else {
                Color.vSurface
            }
        }
        .clipShape(.rect(cornerRadius: SagaceMetrics.cardRadius, style: .continuous))
        .cardBackground()
        .padding(.vertical, 10)
        .frame(maxWidth: SagaceMetrics.readableWidth)
        .animation(SagaceMotion.page, value: viewModel.currentPage?.ficheID)
    }

    /// Clavier matériel de l'iPad : ↑ et ↓ changent de fiche.
    private var keyboardShortcuts: some View {
        ZStack {
            Button("Fiche précédente") { viewModel.showPage(offset: -1) }
                .keyboardShortcut(.upArrow, modifiers: [])
            Button("Fiche suivante") { viewModel.showPage(offset: 1) }
                .keyboardShortcut(.downArrow, modifiers: [])
        }
        // Une sheet ouverte garde les flèches pour elle.
        .disabled(router.sheet != nil)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private var pager: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.pages) { page in
                    pageView(page)
                        .padding(.horizontal, SagaceMetrics.pageMargin)
                        .padding(.vertical, 10)
                        .readableColumn()
                        .containerRelativeFrame(.vertical)
                        .id(page.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $viewModel.currentPageID)
        .overlay(alignment: .bottom) {
            TipView(swipeTip, arrowEdge: .bottom)
                .padding(.horizontal, SagaceMetrics.pageMargin + 16)
                .padding(.bottom, 80)
        }
        .onChange(of: viewModel.currentPageID) { old, new in
            viewModel.pageDidAppear(new)
            if old != nil {
                viewModel.pageDidChange()
                swipeTip.invalidate(reason: .actionPerformed)
                SortTip.hasSwiped = true
            }
        }
        .onAppear { viewModel.pageDidAppear(viewModel.currentPageID) }
    }

    @ViewBuilder
    private func pageView(_ page: FeedViewModel.Page) -> some View {
        switch page.item {
        case .fiche(let id):
            if let fiche = viewModel.fiche(id) {
                FicheCard(
                    fiche: fiche, isWordOfTheDay: viewModel.wordOfTheDayID == id, details: viewModel.details(of: fiche),
                    revealed: viewModel.revealed[page.id, default: 0], revealsDetails: layout != .wide,
                    onSpeak: { viewModel.speak(id) }
                ) { viewModel.reveal(page.id) }
            }
        case .end:
            EndCardView(hoursToNextBatch: viewModel.hoursToNextBatch, isPremium: viewModel.isPremium) {
                router.open(.paywall(.endOfFreeBatch))
            }
        }
    }
}

/// Proposition d'un jeu une fois l'objectif atteint (FEED-04), une fois par jour.
struct GameSuggestionSheet: View {
    let games: [GameType]
    let onPlay: (GameType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer("Un jeu de 2 minutes ?", systemImage: "gamecontroller") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                ForEach(games, id: \.self) { game in
                    OptionRow(verbatim: AppLocalization.string(game.title), systemImage: game.symbol, isSelected: false) { play(game) }
                }
                Spacer(minLength: 8)
                SecondaryButton("Plus tard") { dismiss() }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
    }

    private func play(_ game: GameType) {
        dismiss()
        onPlay(game)
    }
}
