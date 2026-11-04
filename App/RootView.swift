import SagaceCore
import SagaceUI
import SwiftUI

/// Racine : chargement du contenu, migration v3, puis le feed et ses sheets.
struct RootView: View {
    let dependencies: AppDependencies
    @State private var feed: FeedViewModel?
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
                if let feed {
                    FeedView(viewModel: feed, profileInitial: dependencies.store.profile.firstName?.first.map { String($0).uppercased() })
                        .floatingSheet(item: $router.sheet) { sheet in
                            sheetView(sheet, content: content)
                        }
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
            content: content, topics: topics, store: dependencies.store, entitlements: dependencies.entitlements,
            haptics: dependencies.haptics, analytics: dependencies.analytics, day: dependencies.day, now: dependencies.now
        )
        viewModel.load()
        WidgetTip.daysSinceInstall = dependencies.day.days(from: dependencies.store.profile.createdAt, to: dependencies.now())
        feed = viewModel
    }

    @ViewBuilder
    private func sheetView(_ sheet: Sheet, content: ContentRepository) -> some View {
        switch sheet {
        case .day(let day):
            DayView(viewModel: DayViewModel(day: day, content: content, store: dependencies.store)) { ids in
                feed?.replay(ids)
            }
        case .explore:
            ComingSoonSheet(title: "Explorer", systemImage: "square.grid.2x2")
        case .profile:
            ComingSoonSheet(title: "Profil", systemImage: "person.crop.circle")
        case .stats:
            ComingSoonSheet(title: "Stats", systemImage: "chart.bar")
        case .practice:
            ComingSoonSheet(title: "S'entraîner", systemImage: "gamecontroller")
        case .fiche:
            ComingSoonSheet(title: "Fiche détaillée", systemImage: "info.circle")
        case .share:
            ComingSoonSheet(title: "Partager", systemImage: "square.and.arrow.up")
        case .paywall:
            ComingSoonSheet(title: "Sagace Premium", systemImage: "crown")
        }
    }
}
