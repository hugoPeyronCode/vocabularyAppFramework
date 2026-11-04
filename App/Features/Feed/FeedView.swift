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
            pager
            FeedActionBar(
                sorting: viewModel.currentSortableFicheID.flatMap { viewModel.sortings[$0] },
                canSort: viewModel.currentSortableFicheID != nil,
                hasFiche: viewModel.currentPage?.ficheID != nil,
                sortTip: sortTip,
                infoTip: infoTip,
                onInfo: {
                    infoTip.invalidate(reason: .actionPerformed)
                    if let id = viewModel.currentPage?.ficheID { router.open(.fiche(id)) }
                },
                onShare: { if let id = viewModel.currentPage?.ficheID { router.open(.share(id)) } },
                onSort: { sorting in
                    sortTip.invalidate(reason: .actionPerformed)
                    InfoTip.hasSorted = true
                    viewModel.sort(sorting)
                }
            )
            DayStrip(week: viewModel.week, hoursToNextBatch: viewModel.hoursToNextBatch) { router.open(.day($0)) }
        }
        .background(.vBackground)
        .toast(viewModel.goalToast) { toast in
            Toast(Text("Objectif atteint · \(toast.goal) fiches · Série : \(toast.streak) jours"), systemImage: "checkmark.seal")
        }
        .floatingSheet(item: $viewModel.mastered, detents: [.medium]) { mastered in
            MasteredSheet(mastered: mastered)
        }
        .floatingSheet(isPresented: $viewModel.isShowingGameSuggestion, detents: [.medium]) {
            GameSuggestionSheet { router.open(.practice) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.sceneDidBecomeActive() }
        }
    }

    private var pager: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.pages) { page in
                    pageView(page)
                        .padding(.horizontal, SagaceMetrics.pageMargin)
                        .padding(.vertical, 10)
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
                FicheCard(fiche: fiche, familyName: viewModel.familyName(of: fiche)) { router.open(.practice) }
            }
        case .review(let id):
            if let card = viewModel.reviews[id] {
                ReviewCardView(card: card, answerState: { viewModel.answerState(for: id, choice: $0) }) {
                    viewModel.answerReview(id, choice: $0)
                }
            }
        case .end:
            EndCardView(hoursToNextBatch: viewModel.hoursToNextBatch, isPremium: viewModel.isPremium) {
                router.open(.paywall(.endOfFreeBatch))
            }
        }
    }
}

/// Mot maîtrisé (FEED-03).
struct MasteredSheet: View {
    let mastered: FeedViewModel.Mastered
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer(showsCloseButton: false) {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.vCorrect)
                    .accessibilityHidden(true)
                Text("Maîtrisé : \(mastered.headword)")
                    .textStyle(.title)
                    .multilineTextAlignment(.center)
                Text("Vous avez maîtrisé \(mastered.count) mots.")
                    .textStyle(.body)
                Spacer(minLength: 8)
                PrimaryButton("Continuer") { dismiss() }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
            .padding(.top, 8)
        }
    }
}

/// Proposition d'un jeu une fois l'objectif atteint (FEED-04), une fois par jour.
struct GameSuggestionSheet: View {
    let onPlay: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetContainer("Un jeu de 2 minutes ?", systemImage: "gamecontroller") {
            VStack(spacing: SagaceMetrics.rowSpacing) {
                OptionRow("Le mot juste", systemImage: "text.badge.checkmark", isSelected: false) { play() }
                OptionRow("Paronymes", systemImage: "arrow.left.arrow.right", isSelected: false) { play() }
                OptionRow("Juste ou fautif", systemImage: "checkmark.circle", isSelected: false) { play() }
                Spacer(minLength: 8)
                SecondaryButton("Plus tard") { dismiss() }
            }
            .padding(.horizontal, SagaceMetrics.pageMargin)
        }
    }

    private func play() {
        dismiss()
        onPlay()
    }
}
