import Foundation

/// Un rappel tel que l'utilisateur l'a réglé (REM-01).
public struct ReminderSpec: Equatable, Sendable {
    public let id: String
    public let source: ReminderSource
    public let sourceID: String?
    /// Notifications par jour (1 à 10).
    public let count: Int
    /// Début et fin de la plage, en minutes depuis minuit.
    public let startMinute: Int
    public let endMinute: Int
    /// Jours cochés : 1 = lundi … 7 = dimanche.
    public let weekdays: Set<Int>
    public let isEnabled: Bool
    /// Son de la notification ("default" ou nom d'un fichier .caf du bundle).
    public let soundID: String

    public init(id: String, source: ReminderSource = .fichesDuJour, sourceID: String? = nil, count: Int, startMinute: Int,
                endMinute: Int, weekdays: Set<Int> = Set(1...7), isEnabled: Bool = true, soundID: String = "default") {
        self.id = id; self.source = source; self.sourceID = sourceID; self.count = count
        self.startMinute = startMinute; self.endMinute = endMinute; self.weekdays = weekdays; self.isEnabled = isEnabled
        self.soundID = soundID
    }
}

/// Une notification à planifier.
public struct PlannedReminder: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case reminder(id: String, source: ReminderSource, sourceID: String?, soundID: String)
        /// 20 h 30 si aucune activité aujourd'hui et une série d'au moins 2 jours.
        case eveningStreak
    }

    public let date: Date
    public let kind: Kind
}

/// Planification glissante sur 7 jours, plafond de 60 notifications (`03_ARCHITECTURE.md` section 7, Rappels).
public struct ReminderPlanner: Sendable {
    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Minutes des notifications d'une journée : une seule à l'heure de début, sinon réparties à intervalles égaux.
    public static func minutes(count: Int, start: Int, end: Int) -> [Int] {
        let count = min(max(count, 1), Rules.reminderMaxPerDay)
        guard count > 1, end > start else { return [start] }
        let step = Double(end - start) / Double(count - 1)
        return (0..<count).map { start + Int((Double($0) * step).rounded()) }
    }

    /// Jour ISO (1 = lundi … 7 = dimanche) d'une date.
    public func isoWeekday(of date: Date) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7 + 1
    }

    public func plan(_ reminders: [ReminderSpec], eveningStreak: Bool, from now: Date) -> [PlannedReminder] {
        var planned: [PlannedReminder] = []
        let today = calendar.startOfDay(for: now)
        for offset in 0..<Rules.reminderHorizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = isoWeekday(of: day)
            for reminder in reminders where reminder.isEnabled && reminder.weekdays.contains(weekday) {
                for minute in Self.minutes(count: reminder.count, start: reminder.startMinute, end: reminder.endMinute) {
                    guard let date = calendar.date(byAdding: .minute, value: minute, to: day), date > now else { continue }
                    planned.append(PlannedReminder(date: date, kind: .reminder(id: reminder.id, source: reminder.source, sourceID: reminder.sourceID, soundID: reminder.soundID)))
                }
            }
        }
        if eveningStreak,
           let evening = calendar.date(bySettingHour: Rules.eveningReminderHour, minute: Rules.eveningReminderMinute, second: 0, of: now),
           evening > now {
            planned.append(PlannedReminder(date: evening, kind: .eveningStreak))
        }
        return Array(planned.sorted { $0.date < $1.date }.prefix(Rules.maxScheduledNotifications))
    }
}
