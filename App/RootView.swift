import SagaceCore
import SagaceUI
import SwiftUI

/// Racine : chargement du contenu, migration v3, puis le feed et ses sheets.
struct RootView: View {
    let dependencies: AppDependencies
    @State private var feed: FeedViewModel?
    @State private var factory: ScreenFactory?
    #if DEBUG
    @State private var isShowingDemo = DesignSystemDemo.isRequestedAtLaunch
    #endif

    var body: some View {
        @Bindable var router = dependencies.router
        Group {
            switch dependencies.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                Text("Le contenu n'a pas pu être chargé.")
                    .textStyle(.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready(let content, let topics):
                if let feed, let factory {
                    FeedView(viewModel: feed, profileInitial: dependencies.store.profile.firstName?.first.map { String($0).uppercased() })
                        .floatingSheet(item: $router.sheet, onDismiss: { feed.refreshAfterSheet() }) { sheet in
                            sheetView(sheet, content: content, factory: factory)
                                .environment(factory)
                        }
                        .environment(factory)
                } else {
                    Color.clear.onAppear { makeFeed(content: content, topics: topics) }
                }
            }
        }
        .background(.vBackground)
        .fullScreenCover(item: $router.fullScreen) { screen in
            switch screen {
            case .migration(let report, let isPremium):
                MigrationView(report: report, isPremium: isPremium) { router.fullScreen = nil }
            }
        }
        .task { await dependencies.start() }
        #if DEBUG
        .fullScreenCover(isPresented: $isShowingDemo) { DesignSystemDemoView() }
        #endif
    }

    private func makeFeed(content: ContentRepository, topics: Topics) {
        let viewModel = FeedViewModel(
            content: content, topics: topics, store: dependencies.store, library: dependencies.library, audio: dependencies.audio,
            entitlements: dependencies.entitlements, haptics: dependencies.haptics, analytics: dependencies.analytics,
            day: dependencies.day, now: dependencies.now
        )
        factory = ScreenFactory(dependencies: dependencies, content: content, topics: topics)
        viewModel.load()
        WidgetTip.daysSinceInstall = dependencies.day.days(from: dependencies.store.profile.createdAt, to: dependencies.now())
        feed = viewModel
    }

    @ViewBuilder
    private func sheetView(_ sheet: Sheet, content: ContentRepository, factory: ScreenFactory) -> some View {
        switch sheet {
        case .day(let day):
            DayView(viewModel: DayViewModel(day: day, content: content, store: dependencies.store)) { ids in
                feed?.replay(ids)
            }
        case .explore:
            factory.explore()
        case .profile:
            ComingSoonSheet(title: "Profil", systemImage: "person.crop.circle")
        case .stats:
            ComingSoonSheet(title: "Stats", systemImage: "chart.bar")
        case .practice:
            ComingSoonSheet(title: "S'entraîner", systemImage: "gamecontroller")
        case .fiche(let id):
            NavigationStack {
                SheetContainer {
                    factory.ficheDetail(id, origin: nil)
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { factory.destination($0) }
            }
            .stackedPaywall(dependencies.router)
        case .share(let id):
            factory.share(id)
        case .paywall:
            ComingSoonSheet(title: "Sagace Premium", systemImage: "crown")
        }
    }
}
