import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Jeux (PRA-01) : niveau, révisions du jour, jeux, défis, familles suivies. Tout ce qui se joue vit ici, hors du feed.
@MainActor @Observable
final class PracticeHubViewModel {
    private(set) var level: Level = Rules.defaultLevel
    private(set) var hasTakenTest = false
    private(set) var suggestedGame: GameType?
    private(set) var gameSessionsToday = 0
    private(set) var followedFamilies: [Topics.FamilyInfo] = []
    private(set) var records: [ChallengeState.Kind: Int] = [:]
    /// Fiches "À retenir" dont la révision est due, la plus ancienne d'abord.
    private(set) var dueReviews: [String] = []

    private let content: ContentRepository
    private let topics: Topics
    private let progress: any ProgressStoring
    private let recorder: any PracticeRecording
    private let entitlements: any PremiumProviding
    private let stats: PracticeStats
    private let engine: FeedEngine
    private let now: () -> Date

    init(content: ContentRepository, topics: Topics, progress: any ProgressStoring, recorder: any PracticeRecording, entitlements: any PremiumProviding,
         day: SagaceDay, now: @escaping () -> Date) {
        self.content = content; self.topics = topics; self.progress = progress; self.recorder = recorder; self.entitlements = entitlements
        self.stats = PracticeStats(day: day); self.engine = FeedEngine(day: day); self.now = now
    }

    var isPremium: Bool { entitlements.isPremium }
    var canPlay: Bool { PracticeStats.canStartGame(isPremium: isPremium, gameSessionsToday: gameSessionsToday) }

    func load() {
        level = Level(rawValue: progress.profile.level) ?? Rules.defaultLevel
        hasTakenTest = recorder.lastLevelTest() != nil
        suggestedGame = stats.suggestedSkill(stats.accuracy(recorder.answers(), at: now()))?.games.first
        gameSessionsToday = recorder.gameSessionsToday(at: now())
        dueReviews = engine.dueReviews(progress.allProgress().values, at: now()).filter { content.fiche(id: $0) != nil }
        let followed = Set(progress.preferences.followedFamilies)
        followedFamilies = topics.families.filter { followed.contains($0.id.rawValue) }
        records = Dictionary(uniqueKeysWithValues: ChallengeState.Kind.allCases.compactMap { kind in
            recorder.bestScore(for: kind.mode).map { (kind, $0) }
        })
    }
}

struct PracticeHubView: View {
    @State var viewModel: PracticeHubViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetContainer("Jeux", systemImage: "gamecontroller") {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    levelCard
                    if !viewModel.dueReviews.isEmpty {
                        reviewCard
                    }
                    if !viewModel.isPremium {
                        if viewModel.canPlay {
                            Label("1 session gratuite aujourd'hui", systemImage: "gift").textStyle(.meta)
                        } else {
                            ProBanner { router.stackedPaywall = .proBanner }
                        }
                    }
                    section("Jeux") {
                        AdaptiveGrid {
                            ForEach(GameType.allCases, id: \.self) { game in
                                Tile(Text(game.title), systemImage: game.symbol,
                                     detail: viewModel.suggestedGame == game ? Text("Suggéré") : nil,
                                     badge: viewModel.canPlay ? .none : .locked) {
                                    router.open(.session(.game(game)))
                                }
                            }
                            Tile(Text("Mot croisé"), systemImage: "square.grid.3x3.fill", detail: Text("Nouveau"),
                                 badge: viewModel.canPlay ? .none : .locked) {
                                router.open(.crossword)
                            }
                        }
                    }
                    section("Défis") {
                        AdaptiveGrid {
                            ForEach(ChallengeState.Kind.allCases, id: \.self) { kind in
                                Tile(Text(kind.title), systemImage: kind.symbol,
                                     detail: viewModel.records[kind].map { Text("Record : \($0)") },
                                     badge: viewModel.canPlay ? .none : .locked) {
                                    router.open(.challenge(kind))
                                }
                            }
                        }
                    }
                    if !viewModel.followedFamilies.isEmpty {
                        section("Par famille") {
                            VStack(spacing: SagaceMetrics.rowSpacing) {
                                ForEach(viewModel.followedFamilies) { family in
                                    OptionRow(verbatim: family.name, systemImage: family.id.symbol, isSelected: false, haptic: .selection) {
                                        router.open(.session(.family(family.id)))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 16)
            }
        }
        .stackedPaywall(router)
        .onAppear { viewModel.load() }
    }

    /// Révisions du jour : gratuites et illimitées, elles font avancer les boîtes de Leitner.
    private var reviewCard: some View {
        Button { router.open(.session(.review(viewModel.dueReviews))) } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Révisions du jour").fontStyle(.rowTitle)
                    Text("À revoir : \(viewModel.dueReviews.count)").font(.subheadline).opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.vOnInverse)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.vInverse, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    /// Carte de niveau, couleur du niveau.
    private var levelCard: some View {
        Button { router.open(.levelTest) } label: {
            HStack(spacing: 14) {
                Image(systemName: viewModel.level.symbol)
                    .font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.hasTakenTest {
                        Text("Votre niveau : \(Text(viewModel.level.title))").fontStyle(.rowTitle)
                        Text("Repasser le test").font(.subheadline.weight(.semibold)).opacity(0.85)
                    } else {
                        Text("Testez votre précision").fontStyle(.rowTitle)
                        Text("30 questions, environ 5 minutes.").font(.subheadline).opacity(0.85)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(viewModel.level.selectedForeground)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(viewModel.level.selectedBackground, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).textStyle(.title).accessibilityAddTraits(.isHeader)
            content()
        }
    }
}
