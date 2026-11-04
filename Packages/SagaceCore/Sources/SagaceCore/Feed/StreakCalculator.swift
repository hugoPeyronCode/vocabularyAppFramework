import Foundation

/// Activité d'une journée Sagace.
public struct DayActivity: Equatable, Sendable {
    /// Identifiant du jour (`SagaceDay.day(of:)`).
    public let day: Date
    public var sorted: Int
    public var reviewsDone: Int
    public var sessions: Int
    public var goalReached: Bool

    public init(day: Date, sorted: Int = 0, reviewsDone: Int = 0, sessions: Int = 0, goalReached: Bool = false) {
        self.day = day; self.sorted = sorted; self.reviewsDone = reviewsDone
        self.sessions = sessions; self.goalReached = goalReached
    }

    /// Jour actif : au moins un tri, une révision ou une session.
    public var isActive: Bool { sorted > 0 || reviewsDone > 0 || sessions > 0 }
}

public struct StreakSummary: Equatable, Sendable {
    public let current: Int
    public let longest: Int
    /// Jours parfaits : objectif atteint.
    public let perfectDays: Int
}

/// Série de jours actifs (`03_ARCHITECTURE.md` section 7, Objectif et série).
public struct StreakCalculator: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    /// Série actuelle : jours actifs consécutifs jusqu'à aujourd'hui, ou jusqu'à hier si aujourd'hui n'est pas encore actif.
    public func summary(of activity: [DayActivity], at now: Date) -> StreakSummary {
        let active = Set(activity.filter(\.isActive).map { day.calendar.startOfDay(for: $0.day) })
        let today = day.day(of: now)
        var cursor = active.contains(today) ? today : day.adding(days: -1, to: today)
        var current = 0
        while active.contains(cursor) {
            current += 1
            cursor = day.adding(days: -1, to: cursor)
        }

        var longest = 0
        var run = 0
        var previous: Date?
        for date in active.sorted() {
            if let previous, day.adding(days: 1, to: previous) == date { run += 1 } else { run = 1 }
            longest = max(longest, run)
            previous = date
        }

        return StreakSummary(current: current, longest: max(longest, current), perfectDays: activity.filter(\.goalReached).count)
    }

    /// Rappel du soir : aucune activité aujourd'hui et une série d'au moins 2 jours à protéger.
    public func needsEveningReminder(_ activity: [DayActivity], at now: Date) -> Bool {
        let today = day.day(of: now)
        let activeToday = activity.contains { day.calendar.startOfDay(for: $0.day) == today && $0.isActive }
        return !activeToday && summary(of: activity, at: now).current >= Rules.eveningReminderMinStreak
    }
}
