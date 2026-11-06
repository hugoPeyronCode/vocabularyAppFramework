import SagaceCore
import SagaceUI
import SwiftUI

/// Racine : chargement du contenu, migration v3, puis le feed et ses sheets.
struct RootView: View {
    let dependencies: AppDependencies
    @State private var feed: FeedViewModel?
    @State private var factory: ScreenFactory?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// APP-01 : réglage appliqué à toute la fenêtre, sheets comprises.
    private var colorScheme: ColorScheme? {
        switch dependencies.store.preferences.appearance {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
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
        .preferredColorScheme(colorScheme)
        .transaction { transaction in
            // Réglage « Animations » de l'app, ou « Réduire les animations » d'iOS.
            if !dependencies.store.preferences.animationsEnabled || reduceMotion { transaction.disablesAnimations = true }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Révisions et "À retenir" faits depuis les widgets pendant que l'app dormait.
                if dependencies.widgets.applyInbox() { feed?.load() }
                dependencies.widgets.refresh()
            case .background:
                dependencies.widgets.refresh()
                Task {
                    await dependencies.reminders.reschedule()
                    dependencies.reminders.submitBackgroundRefresh()
                }
            default:
                break
            }
        }
        .onChange(of: dependencies.entitlements.isPremium) { dependencies.widgets.refresh() }
        .onChange(of: router.fullScreen == nil) { _, visible in feed?.setObscured(!visible) }
        .onOpenURL { url in
            guard let link = WidgetLink(url: url) else { return }
            dependencies.analytics.track(.widgetInteraction(kind: link.kind, action: .open))
            switch link {
            case .fiche(let id): dependencies.router.open(.fiche(id, origin: .widget))
            case .revision: dependencies.router.open(.practice)
            case .serie: dependencies.router.open(.stats)
            }
        }
        .fullScreenCover(item: $router.fullScreen, onDismiss: { feed?.load() }) { screen in
            switch screen {
            case .migration(let report, let isPremium):
                MigrationView(report: report, isPremium: isPremium) {
                    router.fullScreen = nil
                } onDiscover: {
                    router.fullScreen = .onboarding(.afterMigration)
                }
            case .onboarding(let flow):
                if let factory {
                    factory.onboarding(flow) { router.fullScreen = nil }
                        .environment(factory)
                        .environment(dependencies.router)
                }
            }
        }
        .task { await dependencies.start() }
        #if DEBUG
        .fullScreenCover(isPresented: $isShowingDemo) { DesignSystemDemoView() }
        #endif
    }

    private func makeFeed(content: ContentRepository, topics: Topics) {
        let viewModel = FeedViewModel(
            content: content, topics: topics, store: dependencies.store, library: dependencies.library,
            practice: dependencies.practice, audio: dependencies.audio,
            entitlements: dependencies.entitlements, haptics: dependencies.haptics, analytics: dependencies.analytics,
            day: dependencies.day, now: dependencies.now
        )
        factory = ScreenFactory(dependencies: dependencies, content: content, topics: topics)
        if !dependencies.store.profile.hasCompletedOnboarding, dependencies.router.fullScreen == nil, !Self.skipsOnboarding {
            dependencies.router.fullScreen = .onboarding(.full)
        }
        viewModel.setObscured(dependencies.router.fullScreen != nil)
        viewModel.load()
        WidgetTip.daysSinceInstall = dependencies.day.days(from: dependencies.store.profile.createdAt, to: dependencies.now())
        feed = viewModel
        #if DEBUG
        if let sheet = DebugLaunch.sheet { dependencies.router.open(sheet) }
        #endif
    }

    /// `-skipOnboarding` (debug) : ouvre directement le feed.
    private static var skipsOnboarding: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
        #else
        false
        #endif
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
            factory.profile()
        case .stats:
            factory.stats()
        case .practice:
            factory.practiceHub()
        case .session(let request):
            factory.session(.session(request))
        case .challenge(let kind):
            factory.challenge(kind)
        case .levelTest:
            factory.session(.levelTest)
        case .crossword:
            factory.crossword()
        case .fiche(let id, let origin):
            NavigationStack {
                SheetContainer {
                    factory.ficheDetail(id, origin: origin)
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { factory.destination($0) }
            }
            .stackedPaywall(dependencies.router)
        case .share(let id):
            factory.share(id)
        case .paywall(let source):
            factory.paywall(source)
        }
    }
}
