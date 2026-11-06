import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Stats (STA-01 à 03) : onglets Série · Progrès · Succès.
@MainActor @Observable
final class StatsViewModel {
    enum Tab: Hashable { case streak, progress, achievements }

    struct AchievementRow: Identifiable, Hashable {
        let id: AchievementID
        let unlockedAt: Date?
    }

    var tab: Tab = .streak
    private(set) var streak = StreakSummary(current: 0, longest: 0, perfectDays: 0)
    private(set) var month: MonthCalendar?
    private(set) var family: Family?
    private(set) var summary = ProgressSummary(progress: [], sessions: 0)
    private(set) var accuracy: [Skill: SkillAccuracy] = [:]
    private(set) var achievements: [AchievementRow] = []
    let families: [Topics.FamilyInfo]

    private let content: ContentRepository
    private let progress: any ProgressStoring
    private let practice: any PracticeRecording
    private let profile: any ProfileStoring
    private let entitlements: any PremiumProviding
    private let haptics: any HapticPlaying
    private let day: SagaceDay
    private let now: () -> Date

    init(content: ContentRepository, topics: Topics, progress: any ProgressStoring, practice: any PracticeRecording,
         profile: any ProfileStoring, entitlements: any PremiumProviding, haptics: any HapticPlaying, day: SagaceDay, now: @escaping () -> Date) {
        self.content = content; self.families = topics.families; self.progress = progress; self.practice = practice
        self.profile = profile; self.entitlements = entitlements; self.haptics = haptics; self.day = day; self.now = now
    }

    var isPremium: Bool { entitlements.isPremium }

    func load() {
        let activity = progress.activity()
        streak = StreakCalculator(day: day).summary(of: activity, at: now())
        month = MonthCalendar(month: day.day(of: now()), activity: activity, today: day.day(of: now()), day: day)
        accuracy = PracticeStats(day: day).accuracy(practice.answers(), at: now())
        refreshSummary()

        let all = progress.allProgress()
        let sortedFamilies = Set(all.values.filter { $0.sorting != nil }.compactMap { content.fiche(id: $0.ficheID)?.family })
        let context = AchievementContext(
            longestStreak: streak.longest, mastered: summary(for: nil).mastered,
            bestTestLevel: practice.lastLevelTest().flatMap { Level(rawValue: $0.level) },
            sortedFamilies: sortedFamilies, bestRush: practice.bestScore(for: .rush) ?? 0
        )
        if !profile.unlock(AchievementRules.unlocked(context), at: now()).isEmpty { haptics.play(.celebration) }
        let unlocked = Dictionary(profile.achievements().map { ($0.id, $0.unlockedAt) }, uniquingKeysWith: { first, _ in first })
        achievements = AchievementID.allCases.map { AchievementRow(id: $0, unlockedAt: unlocked[$0.rawValue]) }
    }

    func select(_ family: Family?) {
        self.family = family
        refreshSummary()
    }

    private func refreshSummary() {
        summary = summary(for: family)
    }

    private func summary(for family: Family?) -> ProgressSummary {
        ProgressSummary(
            progress: Array(progress.allProgress().values), sessions: practice.finishedSessionCount(),
            fiches: family.map { Set(content.fiches(in: $0).map(\.id)) }
        )
    }
}

extension AchievementID {
    var title: LocalizedStringKey {
        switch self {
        case .serie3: "3 jours de série"
        case .serie7: "7 jours de série"
        case .serie30: "30 jours de série"
        case .maitrise10: "10 mots maîtrisés"
        case .maitrise50: "50 mots maîtrisés"
        case .maitrise100: "100 mots maîtrisés"
        case .testExpert: "Niveau Expert au test"
        case .toutesFamilles: "Toutes les familles explorées"
        case .rush20: "20 bonnes réponses en Rush"
        }
    }

    var symbol: String {
        switch self {
        case .serie3, .serie7, .serie30: "laurel.leading"
        case .maitrise10, .maitrise50, .maitrise100: "checkmark.seal.fill"
        case .testExpert: "crown.fill"
        case .toutesFamilles: "square.grid.2x2.fill"
        case .rush20: "bolt.fill"
        }
    }
}

struct StatsView: View {
    @State var viewModel: StatsViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetContainer("Stats", systemImage: "chart.bar") {
            ScrollView {
                Group {
                    switch viewModel.tab {
                    case .streak: streakTab
                    case .progress: progressTab
                    case .achievements: achievementsTab
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
                .padding(.bottom, 16)
            }
        } bottomBar: {
            BottomTabs([
                .init(.streak, title: "Série", systemImage: "laurel.leading"),
                .init(.progress, title: "Progrès", systemImage: "chart.bar"),
                .init(.achievements, title: "Succès", systemImage: "trophy"),
            ], selection: $viewModel.tab)
        }
        .stackedPaywall(router)
        .onAppear { viewModel.load() }
    }

    // MARK: STA-01 Série

    private var streakTab: some View {
        VStack(spacing: 24) {
            HStack {
                metric("Série actuelle", value: viewModel.streak.current, symbol: "laurel.leading")
                metric("Record", value: viewModel.streak.longest, symbol: "trophy")
                metric("Jours parfaits", value: viewModel.streak.perfectDays, symbol: "checkmark.seal")
            }
            if let month = viewModel.month {
                VStack(alignment: .leading, spacing: 12) {
                    Text(month.days.first?.date ?? .now, format: .dateTime.month(.wide).year()).textStyle(.sheetTitle)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                        ForEach(0..<month.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 30) }
                        ForEach(month.days) { day in dayCircle(day) }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func metric(_ title: LocalizedStringKey, value: Int, symbol: String) -> some View {
        VStack(spacing: 4) {
            Label(title, systemImage: symbol).textStyle(.metricLabel).lineLimit(1).minimumScaleFactor(0.7)
            Text("\(value)").textStyle(.metricValue)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func dayCircle(_ day: MonthCalendar.Day) -> some View {
        ZStack {
            Circle()
                .fill(day.state == .perfect ? Color.vTextPrimary : .clear)
                .overlay(Circle().strokeBorder(day.state == .partial ? Color.vTextPrimary : .vSeparator, lineWidth: 2))
            Text("\(day.number)")
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(day.state == .perfect ? Color.vOnInverse : day.state == .future ? .vTextSecondary : .vTextPrimary)
        }
        .frame(height: 34)
        .accessibilityElement()
        .accessibilityLabel(Text(day.date, format: .dateTime.day().month()))
        .accessibilityValue(day.state == .perfect ? Text("Objectif atteint") : day.state == .partial ? Text("Activité") : Text(verbatim: ""))
    }

    // MARK: STA-02 Progrès

    private var progressTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    Chip("Tout", isActive: viewModel.family == nil) { viewModel.select(nil) }
                    ForEach(viewModel.families) { family in
                        Chip(verbatim: family.name, isActive: viewModel.family == family.id) { viewModel.select(family.id) }
                    }
                }
            }
            .scrollIndicators(.hidden)
            ZStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 20) {
                    AdaptiveGrid(regularColumns: 4) {
                        progressCell("Fiches vues", value: viewModel.summary.seen, symbol: "eye")
                        progressCell("À retenir", value: viewModel.summary.toLearn, symbol: "bookmark")
                        progressCell("Maîtrisées", value: viewModel.summary.mastered, symbol: "checkmark.seal")
                        progressCell("Sessions", value: viewModel.summary.sessions, symbol: "gamecontroller")
                    }
                    Text("Précision sur 14 jours").textStyle(.sheetTitle)
                    ForEach(Skill.allCases, id: \.self) { skill in skillBar(skill) }
                }
                .blur(radius: viewModel.isPremium ? 0 : 8)
                .allowsHitTesting(viewModel.isPremium)
                .accessibilityHidden(!viewModel.isPremium)
                if !viewModel.isPremium {
                    ProBanner { router.stackedPaywall = .stats }
                }
            }
        }
        .padding(.top, 8)
    }

    private func progressCell(_ title: LocalizedStringKey, value: Int, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol).textStyle(.metricLabel)
            Text("\(value)").textStyle(.metricValue)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.metricCardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func skillBar(_ skill: Skill) -> some View {
        let accuracy = viewModel.accuracy[skill]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(skill.title).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                Spacer()
                if let percent = accuracy?.percent {
                    Text("\(Int(percent.rounded())) %").textStyle(.meta)
                } else {
                    Text("Moins de 10 réponses").textStyle(.meta)
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.vSurfaceRaised)
                    Capsule().fill(.vTextPrimary).frame(width: proxy.size.width * (accuracy?.percent ?? 0) / 100)
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: STA-03 Succès

    private var achievementsTab: some View {
        VStack(spacing: SagaceMetrics.rowSpacing) {
            ForEach(viewModel.achievements) { row in
                HStack(spacing: 14) {
                    Image(systemName: row.id.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(row.unlockedAt != nil ? Color.vOnAccent : .vTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(row.unlockedAt != nil ? Color.vLevelAvance : .vSurfaceSelected, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.id.title).fontStyle(.rowTitle).foregroundStyle(.vTextPrimary)
                        if let date = row.unlockedAt {
                            Text(date, format: .dateTime.day().month(.wide).year()).textStyle(.meta)
                        } else {
                            Text("À débloquer").textStyle(.meta)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                .opacity(row.unlockedAt != nil ? 1 : 0.7)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, 8)
    }
}
