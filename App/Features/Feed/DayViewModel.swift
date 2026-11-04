import Foundation
import Observation
import SagaceCore
import SagaceData

/// Journée (FEED-06) : fiches triées ce jour-là et anneau de l'objectif.
@MainActor @Observable
final class DayViewModel {
    struct Row: Identifiable, Hashable {
        let ficheID: String
        let headword: String
        let shortDefinition: String
        let sorting: Sorting
        var id: String { ficheID }
    }

    let day: Date
    private(set) var rows: [Row] = []
    private(set) var sortedCount = 0
    private(set) var dailyGoal = Rules.defaultDailyGoal

    private let content: ContentRepository
    private let store: any ProgressStoring

    init(day: Date, content: ContentRepository, store: any ProgressStoring) {
        self.day = day; self.content = content; self.store = store
    }

    var progress: Double { Double(sortedCount) / Double(max(dailyGoal, 1)) }

    func load() {
        dailyGoal = store.preferences.dailyGoal
        rows = store.sortedFiches(on: day).compactMap { entry in
            content.fiche(id: entry.ficheID).map {
                Row(ficheID: $0.id, headword: $0.headword, shortDefinition: $0.shortDefinition, sorting: entry.sorting)
            }
        }
        sortedCount = store.activity().first { $0.day == day }?.sorted ?? rows.count
    }

    var replayIDs: [String] { rows.map(\.ficheID) }
}
