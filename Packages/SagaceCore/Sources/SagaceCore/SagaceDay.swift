import Foundation

/// La journée Sagace commence à `Rules.newBatchHour` (4 h, heure locale) : une session à 1 h du matin
/// compte encore pour la veille. Toutes les règles de jour (lot, objectif, série, révisions) passent par ici.
public struct SagaceDay: Sendable {
    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Identifiant du jour : minuit du jour civil auquel appartient `date`.
    public func day(of date: Date) -> Date {
        let shifted = calendar.date(byAdding: .hour, value: -Rules.newBatchHour, to: date) ?? date
        return calendar.startOfDay(for: shifted)
    }

    /// Instant où commence le jour `day` (4 h).
    public func start(of day: Date) -> Date {
        calendar.date(byAdding: .hour, value: Rules.newBatchHour, to: calendar.startOfDay(for: day)) ?? day
    }

    /// Instant du prochain lot après `date`.
    public func nextBatch(after date: Date) -> Date {
        start(of: adding(days: 1, to: day(of: date)))
    }

    public func adding(days: Int, to day: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: day) ?? day
    }

    /// Nombre de jours entre deux identifiants de jour.
    public func days(from start: Date, to end: Date) -> Int {
        calendar.dateComponents([.day], from: day(of: start), to: day(of: end)).day ?? 0
    }

    /// Les 7 jours de la semaine (lundi à dimanche) qui contiennent `date`.
    public func week(containing date: Date) -> [Date] {
        let today = day(of: date)
        let weekday = calendar.component(.weekday, from: today) // 1 = dimanche
        let offsetFromMonday = (weekday + 5) % 7
        let monday = adding(days: -offsetFromMonday, to: today)
        return (0..<7).map { adding(days: $0, to: monday) }
    }
}
