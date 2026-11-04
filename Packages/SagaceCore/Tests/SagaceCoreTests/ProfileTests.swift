import Foundation
import Testing
@testable import SagaceCore

@Suite("Rappels")
struct ReminderPlannerTests {
    let planner = ReminderPlanner(calendar: TestClock.calendar)
    /// Mercredi 4 novembre 2026, 6 h.
    let now = TestClock.date(hour: 6)

    @Test("Un seul rappel par jour : à l'heure de début")
    func single() {
        #expect(ReminderPlanner.minutes(count: 1, start: 540, end: 1260) == [540])
    }

    @Test("Plusieurs rappels : répartis à intervalles égaux entre début et fin")
    func spread() {
        #expect(ReminderPlanner.minutes(count: 3, start: 540, end: 1260) == [540, 900, 1260])
        #expect(ReminderPlanner.minutes(count: 4, start: 540, end: 720) == [540, 600, 660, 720])
    }

    @Test("Nombre borné de 1 à 10")
    func bounds() {
        #expect(ReminderPlanner.minutes(count: 0, start: 540, end: 600) == [540])
        #expect(ReminderPlanner.minutes(count: 25, start: 540, end: 1260).count == 10)
    }

    @Test("Jours cochés seulement, sur 7 jours glissants, jamais dans le passé")
    func weekdays() {
        let reminder = ReminderSpec(id: "a", count: 1, startMinute: 9 * 60, endMinute: 9 * 60, weekdays: [1, 3])
        let dates = planner.plan([reminder], eveningStreak: false, from: now).map(\.date)
        // Mercredi 4 (aujourd'hui, 9 h > 6 h) et lundi 9.
        #expect(dates == [TestClock.date(hour: 9), TestClock.date(days: 5, hour: 9)])
        #expect(dates.allSatisfy { planner.isoWeekday(of: $0) == 1 || planner.isoWeekday(of: $0) == 3 })
        let late = planner.plan([reminder], eveningStreak: false, from: TestClock.date(hour: 10))
        #expect(late.first?.date == TestClock.date(days: 5, hour: 9))
    }

    @Test("Plage horaire respectée")
    func timeRange() {
        let reminder = ReminderSpec(id: "a", count: 5, startMinute: 10 * 60, endMinute: 18 * 60)
        for item in planner.plan([reminder], eveningStreak: false, from: now) {
            let minutes = TestClock.calendar.component(.hour, from: item.date) * 60 + TestClock.calendar.component(.minute, from: item.date)
            #expect((600...1080).contains(minutes))
        }
    }

    @Test("Plafond de 60 notifications, les plus proches d'abord")
    func cap() {
        let reminders = (0..<3).map { ReminderSpec(id: "r\($0)", count: 10, startMinute: 8 * 60, endMinute: 22 * 60) }
        let planned = planner.plan(reminders, eveningStreak: true, from: now)
        #expect(planned.count == 60)
        #expect(planned.map(\.date) == planned.map(\.date).sorted())
        #expect(planned.first?.date == TestClock.date(hour: 8))
    }

    @Test("Rappel désactivé : rien")
    func disabled() {
        let reminder = ReminderSpec(id: "a", count: 3, startMinute: 540, endMinute: 1260, isEnabled: false)
        #expect(planner.plan([reminder], eveningStreak: false, from: now).isEmpty)
    }

    @Test("Rappel du soir à 20 h 30 si demandé et pas encore passé")
    func evening() {
        let planned = planner.plan([], eveningStreak: true, from: now)
        #expect(planned == [PlannedReminder(date: TestClock.date(hour: 20, minute: 30), kind: .eveningStreak)])
        #expect(planner.plan([], eveningStreak: true, from: TestClock.date(hour: 21)).isEmpty)
    }
}

@Suite("Stats et succès")
struct StatsTests {
    @Test("Carte 2 × 2, filtrable par famille")
    func summary() {
        let progress = [
            FicheProgress(ficheID: "a", firstSeenAt: TestClock.date(), sorting: .toLearn, review: ReviewState(box: 2)),
            FicheProgress(ficheID: "b", firstSeenAt: TestClock.date(), sorting: .known),
            FicheProgress(ficheID: "c", firstSeenAt: TestClock.date(), sorting: .toLearn, review: ReviewState(box: 0, masteredAt: TestClock.date())),
        ]
        #expect(ProgressSummary(progress: progress, sessions: 4) == ProgressSummary(progress: progress, sessions: 4))
        let all = ProgressSummary(progress: progress, sessions: 4)
        #expect((all.seen, all.toLearn, all.mastered, all.sessions) == (3, 1, 1, 4))
        let filtered = ProgressSummary(progress: progress, sessions: 4, fiches: ["a", "b"])
        #expect((filtered.seen, filtered.toLearn, filtered.mastered) == (2, 1, 0))
    }

    @Test("Calendrier du mois : plein si objectif, contour si activité, futur grisé")
    func calendar() {
        let day = TestClock.day
        let activity = [
            DayActivity(day: day.day(of: TestClock.date(days: -1)), sorted: 5, goalReached: true),
            DayActivity(day: day.day(of: TestClock.date(days: -2)), reviewsDone: 1),
        ]
        let month = MonthCalendar(month: TestClock.date(), activity: activity, today: day.day(of: TestClock.date()), day: day)
        #expect(month.days.count == 30)
        // Novembre 2026 commence un dimanche : 6 cases vides.
        #expect(month.leadingBlanks == 6)
        #expect(month.days[2].state == .perfect)
        #expect(month.days[1].state == .partial)
        #expect(month.days[3].state == .none)
        #expect(month.days[4].state == .future)
    }

    @Test("Succès débloqués selon les seuils")
    func achievements() {
        #expect(AchievementRules.unlocked(AchievementContext()).isEmpty)
        let context = AchievementContext(longestStreak: 7, mastered: 50, bestTestLevel: .expert, sortedFamilies: Set(Family.allCases), bestRush: 20)
        #expect(AchievementRules.unlocked(context) == [.serie3, .serie7, .maitrise10, .maitrise50, .testExpert, .toutesFamilles, .rush20])
        #expect(!AchievementRules.unlocked(AchievementContext(sortedFamilies: [.paronyme])).contains(.toutesFamilles))
    }
}
