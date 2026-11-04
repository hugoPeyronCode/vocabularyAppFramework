import Foundation
import Observation
import SagaceCore
import SagaceData
import SagaceUI
import SwiftUI

/// Listes de la bibliothèque : À retenir (LIB-01), Maîtrisés (LIB-02), Historique (LIB-05), Signalés.
@MainActor @Observable
final class LibraryViewModel {
    struct ToLearnRow: Identifiable, Hashable {
        let fiche: Fiche
        let daysUntilReview: Int
        var id: String { fiche.id }
    }

    struct MasteredRow: Identifiable, Hashable {
        let fiche: Fiche
        let masteredAt: Date
        var id: String { fiche.id }
    }

    struct HistorySection: Identifiable, Hashable {
        let day: Date
        let rows: [(fiche: Fiche, status: FicheStatus)]
        var id: Date { day }

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.day == rhs.day && lhs.rows.map(\.fiche) == rhs.rows.map(\.fiche) }
        func hash(into hasher: inout Hasher) { hasher.combine(day) }
    }

    struct ReportRow: Identifiable, Hashable {
        let id: UUID
        let title: String
        let reason: ReportReason
        let comment: String?
        let createdAt: Date
    }

    private(set) var toLearn: [ToLearnRow] = []
    private(set) var mastered: [MasteredRow] = []
    private(set) var history: [HistorySection] = []
    private(set) var hasOlderHistory = false
    private(set) var reports: [ReportRow] = []
    private var historyDays = Rules.historyPageDays

    private let content: ContentRepository
    private let store: any ProgressStoring
    private let library: any LibraryStoring
    private let rules: Library
    private let now: () -> Date

    init(content: ContentRepository, store: any ProgressStoring, library: any LibraryStoring, day: SagaceDay, now: @escaping () -> Date) {
        self.content = content; self.store = store; self.library = library; self.rules = Library(day: day); self.now = now
    }

    func loadToLearn() {
        toLearn = rules.toLearn(store.allProgress().values, at: now()).compactMap { item in
            content.fiche(id: item.ficheID).map { ToLearnRow(fiche: $0, daysUntilReview: item.daysUntilReview) }
        }
    }

    func loadMastered() {
        mastered = rules.mastered(store.allProgress().values).compactMap { item in
            guard let fiche = content.fiche(id: item.ficheID), let date = item.review.masteredAt else { return nil }
            return MasteredRow(fiche: fiche, masteredAt: date)
        }
    }

    func loadHistory() {
        let progress = store.allProgress().values
        history = rules.history(progress, at: now(), days: historyDays).map { day in
            HistorySection(day: day.day, rows: day.fiches.compactMap { item in
                content.fiche(id: item.ficheID).map { ($0, FicheStatus(progress: item)) }
            })
        }
        hasOlderHistory = rules.hasOlderHistory(progress, at: now(), days: historyDays)
    }

    func loadOlderHistory() {
        historyDays += Rules.historyPageDays
        loadHistory()
    }

    func loadReports() {
        reports = library.reports().map { report in
            let reason = ReportReason(rawValue: report.reason) ?? .other
            let title = reason == .suggestion ? (report.comment ?? "") : (content.fiche(id: report.ficheID)?.headword ?? report.ficheID)
            return ReportRow(id: UUID(), title: title, reason: reason, comment: reason == .suggestion ? nil : report.comment, createdAt: report.createdAt)
        }
    }
}

// MARK: - LIB-01 À retenir

struct ToLearnView: View {
    @State var viewModel: LibraryViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        SheetPage("À retenir") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    if viewModel.toLearn.isEmpty {
                        EmptyState(systemImage: "bookmark", text: "Les fiches triées « À retenir » apparaîtront ici.")
                    } else {
                        PrimaryButton("Réviser maintenant", systemImage: "play.fill") { router.open(.session(.review(viewModel.toLearn.map(\.fiche.id)))) }
                            .padding(.bottom, 6)
                        ForEach(viewModel.toLearn) { row in
                            NavigationLink(value: AppRoute.fiche(row.fiche.id)) {
                                FicheRow(fiche: row.fiche, status: nil, detail: reviewLabel(row.daysUntilReview))
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.loadToLearn() }
    }

    private func reviewLabel(_ days: Int) -> Text {
        switch days {
        case 0: Text("Révision aujourd'hui")
        case 1: Text("Révision demain")
        default: Text("dans \(days) jours")
        }
    }
}

// MARK: - LIB-02 Maîtrisés

struct MasteredView: View {
    @State var viewModel: LibraryViewModel

    var body: some View {
        SheetPage("Maîtrisés") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.mastered.count)")
                            .font(.system(size: 64, weight: .heavy).monospacedDigit())
                            .foregroundStyle(.vTextPrimary)
                        Text("mots maîtrisés").textStyle(.metricLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    ForEach(viewModel.mastered) { row in
                        NavigationLink(value: AppRoute.fiche(row.fiche.id)) {
                            FicheRow(fiche: row.fiche, status: nil, detail: Text(row.masteredAt, format: .dateTime.day().month(.abbreviated)))
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.loadMastered() }
    }
}

// MARK: - LIB-05 Historique

struct HistoryView: View {
    @State var viewModel: LibraryViewModel

    var body: some View {
        SheetPage("Historique") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if viewModel.history.isEmpty {
                        EmptyState(systemImage: "clock.arrow.circlepath", text: "Les fiches vues apparaîtront ici, jour par jour.")
                    }
                    ForEach(viewModel.history) { section in
                        VStack(alignment: .leading, spacing: SagaceMetrics.rowSpacing) {
                            Text(section.day, format: .dateTime.weekday(.wide).day().month(.wide))
                                .textStyle(.metricLabel)
                                .textCase(.uppercase)
                            ForEach(section.rows, id: \.fiche.id) { row in
                                NavigationLink(value: AppRoute.fiche(row.fiche.id)) {
                                    FicheRow(fiche: row.fiche, status: row.status)
                                }
                                .buttonStyle(PressScaleButtonStyle())
                            }
                        }
                    }
                    if viewModel.hasOlderHistory {
                        SecondaryButton("Voir plus ancien", systemImage: "arrow.down") { viewModel.loadOlderHistory() }
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.loadHistory() }
    }
}

// MARK: - Signalés

struct ReportsView: View {
    @State var viewModel: LibraryViewModel

    var body: some View {
        SheetPage("Signalés") {
            ScrollView {
                VStack(spacing: SagaceMetrics.rowSpacing) {
                    if viewModel.reports.isEmpty {
                        EmptyState(systemImage: "flag", text: "Vos signalements et suggestions apparaîtront ici.")
                    }
                    ForEach(viewModel.reports) { report in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: report.title).textStyle(.rowTitle)
                                Text(report.reason.label).textStyle(.body)
                                if let comment = report.comment {
                                    Text(verbatim: comment).textStyle(.body).italic()
                                }
                            }
                            Spacer()
                            Text(report.createdAt, format: .dateTime.day().month(.abbreviated)).textStyle(.meta)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.vSurfaceRaised, in: .rect(cornerRadius: SagaceMetrics.rowRadius, style: .continuous))
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, SagaceMetrics.pageMargin)
            }
        }
        .onAppear { viewModel.loadReports() }
    }
}

extension ReportReason {
    var label: LocalizedStringKey {
        switch self {
        case .definition: "Définition inexacte"
        case .example: "Exemple maladroit"
        case .typo: "Faute dans le texte"
        case .other: "Autre"
        case .suggestion: "Mot proposé"
        }
    }
}

/// État vide : icône (en attendant les illustrations) et phrase.
struct EmptyState: View {
    let systemImage: String
    let text: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .symbolVariant(.fill)
                .font(.system(size: 44))
                .foregroundStyle(.vTextSecondary)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.definition)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
