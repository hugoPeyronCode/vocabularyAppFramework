import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftData
import SwiftUI

/// Fabrique les écrans des sheets avec leur view model et les seuls services utiles.
@MainActor @Observable
final class ScreenFactory {
    let dependencies: AppDependencies
    let content: ContentRepository
    let topics: Topics

    init(dependencies: AppDependencies, content: ContentRepository, topics: Topics) {
        self.dependencies = dependencies; self.content = content; self.topics = topics
    }

    var isPremium: Bool { dependencies.entitlements.isPremium }

    func familyName(_ family: Family) -> String {
        topics.families.first { $0.id == family }?.name ?? ""
    }

    // MARK: Fiche

    /// - Parameter origin: provenance à journaliser, `nil` si déjà comptée par le feed.
    func ficheDetail(_ ficheID: String, origin: AnalyticsEvent.FicheOrigin?) -> some View {
        Group {
            if let fiche = content.fiche(id: ficheID) {
                FicheDetailView(viewModel: FicheDetailViewModel(
                    fiche: fiche, familyName: familyName(fiche.family), content: content, store: dependencies.store,
                    audio: dependencies.audio, haptics: dependencies.haptics, analytics: dependencies.analytics,
                    origin: origin, now: dependencies.now
                ))
            }
        }
    }

    func share(_ ficheID: String) -> some View {
        Group {
            if let fiche = content.fiche(id: ficheID) {
                ShareView(viewModel: ShareViewModel(fiche: fiche, familyName: familyName(fiche.family), haptics: dependencies.haptics))
            }
        }
    }

    func report(_ ficheID: String) -> some View {
        ReportView(viewModel: ReportViewModel(
            ficheID: ficheID, library: dependencies.library, haptics: dependencies.haptics, analytics: dependencies.analytics
        ))
    }

    func addToCollection(_ ficheID: String) -> some View {
        AddToCollectionView(viewModel: AddToCollectionViewModel(ficheID: ficheID, library: dependencies.library, haptics: dependencies.haptics))
    }

    // MARK: Onboarding

    func onboarding(_ flow: OnboardingFlow, onFinish: @escaping () -> Void) -> some View {
        OnboardingView(viewModel: OnboardingViewModel(
            flow: flow, content: content, store: dependencies.store, entitlements: dependencies.entitlements,
            haptics: dependencies.haptics, analytics: dependencies.analytics, now: dependencies.now
        ), onFinish: onFinish)
    }

    // MARK: Paywall

    func paywall(_ source: PaywallSource, onFinish: (() -> Void)? = nil) -> some View {
        PaywallView(viewModel: PaywallViewModel(
            source: source, entitlements: dependencies.entitlements, haptics: dependencies.haptics, analytics: dependencies.analytics
        ), onFinish: onFinish)
    }

    // MARK: Practice

    func practiceHub() -> some View {
        PracticeHubView(viewModel: PracticeHubViewModel(
            topics: topics, progress: dependencies.store, recorder: dependencies.practice,
            entitlements: dependencies.entitlements, day: dependencies.day, now: dependencies.now
        ))
    }

    func session(_ kind: PracticeSessionViewModel.Kind) -> some View {
        PracticeSessionView(viewModel: PracticeSessionViewModel(
            kind: kind, content: content, recorder: dependencies.practice, progress: dependencies.store,
            entitlements: dependencies.entitlements, haptics: dependencies.haptics, analytics: dependencies.analytics,
            now: dependencies.now
        ))
    }

    func challenge(_ kind: ChallengeState.Kind) -> some View {
        ChallengeView(viewModel: ChallengeViewModel(
            kind: kind, content: content, recorder: dependencies.practice, entitlements: dependencies.entitlements,
            haptics: dependencies.haptics, analytics: dependencies.analytics, now: dependencies.now
        ))
    }

    // MARK: Explorer et bibliothèque

    func explore() -> some View {
        ExploreView(viewModel: ExploreViewModel(
            content: content, topics: topics, store: dependencies.store, library: dependencies.library,
            entitlements: dependencies.entitlements, haptics: dependencies.haptics, now: dependencies.now
        ))
    }

    private var libraryViewModel: LibraryViewModel {
        LibraryViewModel(content: content, store: dependencies.store, library: dependencies.library, day: dependencies.day, now: dependencies.now)
    }

    @ViewBuilder
    func destination(_ route: AppRoute) -> some View {
        switch route {
        case .fiche(let id):
            ficheDetail(id, origin: .explore)
        case .topic(let kind):
            TopicView(viewModel: TopicViewModel(
                kind: kind, content: content, topics: topics, store: dependencies.store,
                entitlements: dependencies.entitlements, haptics: dependencies.haptics
            ))
        case .toLearn:
            ToLearnView(viewModel: libraryViewModel)
        case .mastered:
            MasteredView(viewModel: libraryViewModel)
        case .history:
            HistoryView(viewModel: libraryViewModel)
        case .reports:
            ReportsView(viewModel: libraryViewModel)
        case .collections:
            CollectionsView(viewModel: collectionsViewModel)
        case .collection(let id):
            CollectionDetailView(viewModel: collectionsViewModel, collectionID: id)
        case .ownWords:
            OwnWordsView(viewModel: OwnWordsViewModel(library: dependencies.library, haptics: dependencies.haptics))
        case .editFollows:
            EditFollowsView(viewModel: EditFollowsViewModel(topics: topics, store: dependencies.store, haptics: dependencies.haptics))
        }
    }

    private var collectionsViewModel: CollectionsViewModel {
        CollectionsViewModel(content: content, library: dependencies.library, haptics: dependencies.haptics)
    }
}

/// Page poussée dans une sheet : retour, titre, contenu sur `surface`.
struct SheetPage<Content: View>: View {
    let title: Text?
    let content: Content
    @Environment(\.dismiss) private var dismiss

    init(_ title: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.title = title.map { Text($0) }
        self.content = content()
    }

    init(verbatim title: String, @ViewBuilder content: () -> Content) {
        self.title = Text(verbatim: title)
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let title {
                    title.textStyle(.sheetTitle).lineLimit(1).padding(.horizontal, 56).accessibilityAddTraits(.isHeader)
                }
                HStack {
                    CircleButton(systemImage: "chevron.left", accessibilityLabel: "Retour", size: 36) { dismiss() }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 8)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(.vSurface)
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    /// Paywall empilé par-dessus la sheet courante (verrous PRO).
    func stackedPaywall(_ router: AppRouter) -> some View {
        modifier(StackedPaywall(router: router))
    }
}

private struct StackedPaywall: ViewModifier {
    @Bindable var router: AppRouter
    @Environment(ScreenFactory.self) private var factory

    func body(content: Content) -> some View {
        content.floatingSheet(item: $router.stackedPaywall, detents: [.large]) { source in
            factory.paywall(source)
        }
    }
}
