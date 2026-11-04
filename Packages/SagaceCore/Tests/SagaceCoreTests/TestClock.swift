import Foundation
@testable import SagaceCore

/// Calendrier et dates fixes pour des tests indépendants du fuseau de la machine.
enum TestClock {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        calendar.firstWeekday = 2
        return calendar
    }()

    static let day = SagaceDay(calendar: calendar)

    /// 2026-11-04 (mercredi) à `hour`:`minute`, plus `days` jours.
    static func date(days: Int = 0, hour: Int = 12, minute: Int = 0) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: hour, minute: minute))!
        return calendar.date(byAdding: .day, value: days, to: base)!
    }
}
