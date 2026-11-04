import Foundation

/// Ce que le feed doit savoir d'une fiche déjà rencontrée.
public struct FicheProgress: Equatable, Sendable {
    public let ficheID: String
    public var firstSeenAt: Date?
    public var lastSeenAt: Date?
    public var sorting: Sorting?
    public var sortedAt: Date?
    public var review: ReviewState

    public init(ficheID: String, firstSeenAt: Date? = nil, lastSeenAt: Date? = nil, sorting: Sorting? = nil, sortedAt: Date? = nil, review: ReviewState = ReviewState()) {
        self.ficheID = ficheID; self.firstSeenAt = firstSeenAt; self.lastSeenAt = lastSeenAt
        self.sorting = sorting; self.sortedAt = sortedAt; self.review = review
    }
}

/// Préférences et profil qui orientent la sélection.
public struct FeedProfile: Equatable, Sendable {
    public var level: Level
    public var goals: Set<LearningGoal>
    public var followedFamilies: Set<Family>
    public var followedThemes: Set<String>
    public var showFamiliar: Bool
    public var mutedTerms: Set<String>
    /// Fiches des collections suivies dans le feed (LIB-03).
    public var followedFicheIDs: Set<String>

    public init(
        level: Level = Rules.defaultLevel, goals: Set<LearningGoal> = [], followedFamilies: Set<Family> = [],
        followedThemes: Set<String> = [], showFamiliar: Bool = true, mutedTerms: Set<String> = [],
        followedFicheIDs: Set<String> = []
    ) {
        self.level = level; self.goals = goals; self.followedFamilies = followedFamilies
        self.followedThemes = followedThemes; self.showFamiliar = showFamiliar; self.mutedTerms = mutedTerms
        self.followedFicheIDs = followedFicheIDs
    }
}

/// Une page du feed : le feed ne contient que des mots (les révisions sont dans l'espace Jeux).
public enum FeedItem: Hashable, Sendable {
    case fiche(String)
    /// "C'est tout pour aujourd'hui."
    case end
}

/// Sélection et ordre des fiches du feed (`03_ARCHITECTURE.md` section 7, Feed). Pur et déterministe à graine égale.
public struct FeedEngine: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    // MARK: Éligibilité

    /// Fiches qui peuvent entrer dans un lot : non triées, non masquées, registre accepté, familles et thèmes suivis,
    /// pas glissées sans tri depuis moins de 7 jours. Le niveau est appliqué par `pickNew`.
    public func eligible(_ fiches: [Fiche], progress: [String: FicheProgress], profile: FeedProfile, at now: Date) -> [Fiche] {
        let muted = Set(profile.mutedTerms.map { $0.lowercased() })
        return fiches.filter { fiche in
            if muted.contains(fiche.headword.lowercased()) { return false }
            if !profile.showFamiliar && fiche.register == .familier { return false }
            if !follows(fiche, profile) { return false }
            guard let state = progress[fiche.id] else { return true }
            if state.sorting != nil { return false }
            if let lastSeen = state.lastSeenAt, day.days(from: lastSeen, to: now) < Rules.unsortedReturnDays { return false }
            return true
        }
    }

    /// Aucun suivi : tout passe. Sinon, la fiche passe si sa famille, un de ses thèmes ou une collection qui la contient est suivi.
    private func follows(_ fiche: Fiche, _ profile: FeedProfile) -> Bool {
        if profile.followedFamilies.isEmpty && profile.followedThemes.isEmpty && profile.followedFicheIDs.isEmpty { return true }
        return profile.followedFamilies.contains(fiche.family)
            || !profile.followedThemes.isDisjoint(with: fiche.themes)
            || profile.followedFicheIDs.contains(fiche.id)
    }

    // MARK: Pondération et tirage

    /// Poids d'une fiche selon les objectifs d'onboarding (les bonus se multiplient).
    public func weight(of fiche: Fiche, goals: Set<LearningGoal>) -> Double {
        var weight = 1.0
        if goals.contains(.ecrireTravail), !Set(Rules.workGoalThemes).isDisjoint(with: fiche.themes) { weight *= Rules.goalWeight }
        if goals.contains(.parlerAssurance), !Set(Rules.confidenceGoalThemes).isDisjoint(with: fiche.themes) { weight *= Rules.goalWeight }
        if goals.contains(.examen), Rules.examGoalFamilies.contains(fiche.family) { weight *= Rules.goalWeight }
        if goals.contains(.enfants), fiche.level <= Rules.childrenGoalMaxLevel { weight *= Rules.childrenGoalWeight }
        return weight
    }

    /// Tire `count` fiches : d'abord dans la fenêtre de niveau (±1), pondérées par les objectifs,
    /// puis, si la fenêtre est épuisée, les plus proches du niveau. Le résultat ne place jamais deux fiches
    /// de la même famille d'affilée quand c'est possible.
    public func pickNew(_ count: Int, from eligible: [Fiche], profile: FeedProfile, seed: UInt64) -> [Fiche] {
        guard count > 0 else { return [] }
        var rng = SeededGenerator(seed: seed)
        let level = profile.level.rawValue
        let inWindow = eligible.filter { abs($0.level - level) <= Rules.feedLevelSpread }
        var picked = weightedSample(inWindow, count: count, goals: profile.goals, rng: &rng)
        if picked.count < count {
            let outside = eligible
                .filter { abs($0.level - level) > Rules.feedLevelSpread }
                .sorted { abs($0.level - level) < abs($1.level - level) }
            picked += outside.prefix(count - picked.count)
        }
        return Self.mix(picked)
    }

    private func weightedSample(_ fiches: [Fiche], count: Int, goals: Set<LearningGoal>, rng: inout SeededGenerator) -> [Fiche] {
        var pool = fiches.map { ($0, weight(of: $0, goals: goals)) }
        var result: [Fiche] = []
        while result.count < count, !pool.isEmpty {
            let total = pool.reduce(0) { $0 + $1.1 }
            var target = Double.random(in: 0..<total, using: &rng)
            var index = pool.count - 1
            for (offset, entry) in pool.enumerated() {
                target -= entry.1
                if target < 0 { index = offset; break }
            }
            result.append(pool.remove(at: index).0)
        }
        return result
    }

    /// Réordonne pour éviter deux fiches de la même famille d'affilée, en gardant l'ordre autant que possible.
    public static func mix(_ fiches: [Fiche]) -> [Fiche] {
        var remaining = fiches
        var result: [Fiche] = []
        while !remaining.isEmpty {
            let index = remaining.firstIndex { $0.family != result.last?.family } ?? 0
            result.append(remaining.remove(at: index))
        }
        return result
    }

    // MARK: Limites

    /// Fiches nouvelles encore autorisées aujourd'hui. Gratuit : 2 × objectif par jour. Premium : un lot de plus.
    public func newFicheAllowance(dailyGoal: Int, isPremium: Bool, newSeenToday: Int) -> Int {
        let batch = Rules.freeNewFichesMultiplier * dailyGoal
        return isPremium ? batch : max(0, batch - newSeenToday)
    }

    /// Objectif atteint : fiches triées dans la journée ≥ objectif.
    public static func isGoalReached(sortedToday: Int, dailyGoal: Int) -> Bool {
        sortedToday >= dailyGoal
    }

    // MARK: Révisions

    /// Fiches dont la révision est due, la plus ancienne d'abord.
    public func dueReviews(_ progress: some Sequence<FicheProgress>, at now: Date) -> [String] {
        progress
            .filter { $0.review.isDue(at: now) }
            .sorted { ($0.review.nextReviewAt ?? .distantPast, $0.ficheID) < ($1.review.nextReviewAt ?? .distantPast, $1.ficheID) }
            .map(\.ficheID)
    }

    /// Graine stable pour un jour : le lot du jour ne change pas d'un lancement à l'autre.
    public func seed(for date: Date) -> UInt64 {
        UInt64(bitPattern: Int64(day.day(of: date).timeIntervalSinceReferenceDate))
    }
}

/// Générateur pseudo aléatoire reproductible (SplitMix64).
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
