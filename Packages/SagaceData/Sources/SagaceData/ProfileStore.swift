import Foundation
import SagaceCore
import SwiftData

/// Rappels (REM-01) et succès (STA-03).
@MainActor
public protocol ProfileStoring: AnyObject {
    func reminders() -> [Reminder]
    @discardableResult func addReminder() -> Reminder
    func delete(_ reminder: Reminder)
    func save()
    func achievements() -> [Achievement]
    /// Enregistre les succès nouvellement débloqués et les renvoie.
    @discardableResult func unlock(_ ids: Set<AchievementID>, at now: Date) -> [AchievementID]
}

@MainActor
public final class ProfileStore: ProfileStoring {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func reminders() -> [Reminder] {
        (try? context.fetch(FetchDescriptor<Reminder>(sortBy: [SortDescriptor(\.startMinute)]))) ?? []
    }

    @discardableResult
    public func addReminder() -> Reminder {
        let reminder = Reminder()
        context.insert(reminder)
        save()
        return reminder
    }

    public func delete(_ reminder: Reminder) {
        context.delete(reminder)
        save()
    }

    public func save() {
        try? context.save()
    }

    /// Par date de déblocage, puis dans l'ordre du catalogue pour ceux débloqués ensemble.
    public func achievements() -> [Achievement] {
        let order = Dictionary(uniqueKeysWithValues: AchievementID.allCases.enumerated().map { ($1.rawValue, $0) })
        let all = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        return all.sorted { ($0.unlockedAt, order[$0.id] ?? .max) < ($1.unlockedAt, order[$1.id] ?? .max) }
    }

    @discardableResult
    public func unlock(_ ids: Set<AchievementID>, at now: Date) -> [AchievementID] {
        let known = Set(achievements().map(\.id))
        let new = AchievementID.allCases.filter { ids.contains($0) && !known.contains($0.rawValue) }
        for id in new { context.insert(Achievement(id: id.rawValue, unlockedAt: now)) }
        if !new.isEmpty { save() }
        return new
    }
}
