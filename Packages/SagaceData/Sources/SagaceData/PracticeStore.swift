import Foundation
import SagaceCore
import SwiftData

/// Enregistrement des sessions de jeu, défis, révisions et tests de précision.
@MainActor
public protocol PracticeRecording: AnyObject {
    func start(_ mode: PracticeMode, at now: Date) -> PracticeSession
    func record(_ question: Question, correct: Bool, responseMs: Int, in session: PracticeSession, at now: Date)
    /// Clôt la session et la compte comme activité du jour.
    func finish(_ session: PracticeSession, score: Int, total: Int, at now: Date)
    func answers() -> [AnswerRecord]
    /// Sessions de jeu et défis terminés aujourd'hui (limite gratuite).
    func gameSessionsToday(at now: Date) -> Int
    /// Les 5 derniers jours, du plus ancien à aujourd'hui : au moins une session terminée ?
    func sessionDays(last count: Int, at now: Date) -> [Bool]
    func bestScore(for mode: PracticeMode) -> Int?
    /// Sessions terminées (jeux, défis, révisions, tests), pour les stats.
    func finishedSessionCount() -> Int
    /// Enregistre le test et fait du niveau obtenu le niveau du profil.
    func saveLevelTest(score: Int, outOf: Int, at now: Date) -> Level
    func lastLevelTest() -> LevelTestResult?
}

@MainActor
public final class PracticeStore: PracticeRecording {
    private let context: ModelContext
    private let day: SagaceDay

    public init(context: ModelContext, day: SagaceDay = SagaceDay()) {
        self.context = context
        self.day = day
    }

    public func start(_ mode: PracticeMode, at now: Date) -> PracticeSession {
        let session = PracticeSession(mode: mode, startedAt: now)
        context.insert(session)
        return session
    }

    public func record(_ question: Question, correct: Bool, responseMs: Int, in session: PracticeSession, at now: Date) {
        let answer = PracticeAnswer(ficheID: question.ficheID, game: question.game, skill: question.skill,
                                    isCorrect: correct, responseMs: responseMs, answeredAt: now)
        context.insert(answer)
        session.answers.append(answer)
        session.total += 1
        if correct { session.score += 1 }
    }

    public func finish(_ session: PracticeSession, score: Int, total: Int, at now: Date) {
        session.score = score
        session.total = total
        session.endedAt = now
        let key = day.day(of: now)
        var descriptor = FetchDescriptor<ActivityDay>(predicate: #Predicate { $0.day == key })
        descriptor.fetchLimit = 1
        let activity = (try? context.fetch(descriptor).first) ?? {
            let activity = ActivityDay(day: key)
            context.insert(activity)
            return activity
        }()
        activity.sessions += 1
        try? context.save()
    }

    public func answers() -> [AnswerRecord] {
        let answers = (try? context.fetch(FetchDescriptor<PracticeAnswer>())) ?? []
        return answers.map { AnswerRecord(game: $0.game, isCorrect: $0.isCorrect, answeredAt: $0.answeredAt) }
    }

    private func finishedSessions() -> [PracticeSession] {
        let sessions = (try? context.fetch(FetchDescriptor<PracticeSession>())) ?? []
        return sessions.filter { $0.endedAt != nil }
    }

    public func gameSessionsToday(at now: Date) -> Int {
        let today = day.day(of: now)
        return finishedSessions().filter { session in
            session.mode.countsAsGameSession && session.endedAt.map { day.day(of: $0) == today } ?? false
        }.count
    }

    public func sessionDays(last count: Int, at now: Date) -> [Bool] {
        let days = Set(finishedSessions().compactMap { $0.endedAt.map(day.day(of:)) })
        let today = day.day(of: now)
        return (0..<count).reversed().map { days.contains(day.adding(days: -$0, to: today)) }
    }

    public func bestScore(for mode: PracticeMode) -> Int? {
        finishedSessions().filter { $0.mode == mode }.map(\.score).max()
    }

    public func finishedSessionCount() -> Int {
        finishedSessions().count
    }

    public func saveLevelTest(score: Int, outOf: Int, at now: Date) -> Level {
        let level = Rules.level(forLevelTestScore: score)
        context.insert(LevelTestResult(score: score, outOf: outOf, level: level.rawValue, takenAt: now))
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            profile.level = level.rawValue
        } else {
            let profile = UserProfile(createdAt: now)
            profile.level = level.rawValue
            context.insert(profile)
        }
        try? context.save()
        return level
    }

    public func lastLevelTest() -> LevelTestResult? {
        var descriptor = FetchDescriptor<LevelTestResult>(sortBy: [SortDescriptor(\.takenAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
