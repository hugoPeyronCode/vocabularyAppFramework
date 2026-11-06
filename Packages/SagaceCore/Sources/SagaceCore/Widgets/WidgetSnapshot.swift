import Foundation

/// Ce que l'app prépare pour ses widgets (`03_ARCHITECTURE.md` section 9) : les prochaines fiches, les révisions
/// dues déjà mises en question, la série. Écrit dans l'App Group ; le widget ne fait aucun calcul lourd.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// Une fiche telle que le widget l'affiche.
    public struct Card: Codable, Equatable, Sendable {
        public let id: String
        public let headword: String
        public let phonetic: String
        public let grammar: String
        public let shortDefinition: String
        public let confusion: String?
        /// Premier exemple, sans le marquage du mot.
        public let example: String?
        public let quote: String?
        public let quoteSource: String?
        public let family: String

        public init(id: String, headword: String, phonetic: String, grammar: String, shortDefinition: String,
                    confusion: String?, example: String?, quote: String?, quoteSource: String?, family: String) {
            self.id = id; self.headword = headword; self.phonetic = phonetic; self.grammar = grammar
            self.shortDefinition = shortDefinition; self.confusion = confusion; self.example = example; self.quote = quote
            self.quoteSource = quoteSource; self.family = family
        }
    }

    /// Une révision due, déjà mise en question à choix.
    public struct Review: Codable, Equatable, Sendable {
        public let ficheID: String
        public let headword: String
        public let title: String
        public let prompt: String
        public let choices: [String]
        public let correctIndex: Int
        public let explanation: String

        public init(ficheID: String, headword: String, title: String, prompt: String, choices: [String], correctIndex: Int, explanation: String) {
            self.ficheID = ficheID; self.headword = headword; self.title = title; self.prompt = prompt
            self.choices = choices; self.correctIndex = correctIndex; self.explanation = explanation
        }
    }

    public let generatedAt: Date
    /// Jour (`SagaceDay.day(of:)`) où le snapshot a été écrit.
    public let day: Date
    public let isPremium: Bool
    /// Fiche du jour d'abord (le "mot du jour" du feed), puis les suivantes.
    public let cards: [Card]
    /// Premium : fiches par famille, pour les widgets filtrés.
    public let cardsByFamily: [String: [Card]]
    public let reviews: [Review]
    public let dueReviewCount: Int
    public let streak: Int
    public let isActiveToday: Bool
    public let sortedToday: Int
    public let dailyGoal: Int

    public init(generatedAt: Date, day: Date, isPremium: Bool, cards: [Card], cardsByFamily: [String: [Card]], reviews: [Review],
                dueReviewCount: Int, streak: Int, isActiveToday: Bool, sortedToday: Int, dailyGoal: Int) {
        self.generatedAt = generatedAt; self.day = day; self.isPremium = isPremium; self.cards = cards
        self.cardsByFamily = cardsByFamily; self.reviews = reviews; self.dueReviewCount = dueReviewCount
        self.streak = streak; self.isActiveToday = isActiveToday; self.sortedToday = sortedToday; self.dailyGoal = dailyGoal
    }

    /// Fiches d'un widget : filtrées par famille en premium seulement (gratuit : toutes les familles).
    public func cards(for family: Family?) -> [Card] {
        guard isPremium, let family, let filtered = cardsByFamily[family.rawValue], !filtered.isEmpty else { return cards }
        return filtered
    }

    /// Série vue plus tard sans que l'app ait été rouverte : intacte le lendemain d'un jour actif, perdue au-delà.
    public func streak(at now: Date, day calendar: SagaceDay) -> Int {
        switch calendar.days(from: day, to: calendar.day(of: now)) {
        case ...0: streak
        case 1: isActiveToday ? streak : 0
        default: 0
        }
    }

    /// Fiches triées aujourd'hui : remises à zéro au nouveau jour.
    public func sortedToday(at now: Date, day calendar: SagaceDay) -> Int {
        calendar.days(from: day, to: calendar.day(of: now)) <= 0 ? sortedToday : 0
    }
}

/// Construit le snapshot à partir du pack, de la progression et du profil. Les libellés localisés
/// (nature, nom du jeu) viennent de l'app.
public struct WidgetSnapshotBuilder: Sendable {
    public let day: SagaceDay

    public init(day: SagaceDay = SagaceDay()) {
        self.day = day
    }

    public struct Input: Sendable {
        public let fiches: [Fiche]
        public let progress: [String: FicheProgress]
        public let profile: FeedProfile
        public let isPremium: Bool
        public let dailyGoal: Int
        public let activity: [DayActivity]

        public init(fiches: [Fiche], progress: [String: FicheProgress], profile: FeedProfile, isPremium: Bool, dailyGoal: Int, activity: [DayActivity]) {
            self.fiches = fiches; self.progress = progress; self.profile = profile
            self.isPremium = isPremium; self.dailyGoal = dailyGoal; self.activity = activity
        }
    }

    public func build(_ input: Input, at now: Date, grammar: (Fiche) -> String, gameTitle: (GameType) -> String) -> WidgetSnapshot {
        let engine = FeedEngine(day: day)
        let today = day.day(of: now)
        let byID = Dictionary(uniqueKeysWithValues: input.fiches.map { ($0.id, $0) })
        let eligible = engine.eligible(input.fiches, progress: input.progress, profile: input.profile, at: now)
        let seed = engine.seed(for: now)

        // Le mot du jour du feed : la première fiche vue aujourd'hui, sinon la première du lot.
        let seenToday = input.progress.values
            .filter { $0.firstSeenAt.map { day.day(of: $0) == today } ?? false }
            .sorted { ($0.firstSeenAt ?? now, $0.ficheID) < ($1.firstSeenAt ?? now, $1.ficheID) }
            .compactMap { byID[$0.ficheID] }
        let next = engine.pickNew(Rules.widgetCardCount, from: eligible, profile: input.profile, seed: seed)
        var ordered: [Fiche] = []
        for fiche in seenToday.prefix(1) + next where !ordered.contains(where: { $0.id == fiche.id }) {
            ordered.append(fiche)
        }
        let card = { (fiche: Fiche) in Self.card(fiche, grammar: grammar(fiche)) }

        var byFamily: [String: [WidgetSnapshot.Card]] = [:]
        if input.isPremium {
            for family in Family.allCases {
                let picked = engine.pickNew(Rules.widgetCardsPerFamily, from: eligible.filter { $0.family == family }, profile: input.profile, seed: seed)
                if !picked.isEmpty { byFamily[family.rawValue] = picked.map(card) }
            }
        }

        let due = engine.dueReviews(input.progress.values, at: now).compactMap { byID[$0] }
        let questions = QuestionFactory(fiches: input.fiches)
            .review(Array(due.prefix(Rules.widgetReviewCount)), count: Rules.widgetReviewCount, seed: seed, excluding: [.justeOuFautif, .sens])
        let reviews = questions.compactMap { question -> WidgetSnapshot.Review? in
            guard case .choice(let index) = question.correct, let fiche = byID[question.ficheID] else { return nil }
            return WidgetSnapshot.Review(
                ficheID: fiche.id, headword: fiche.headword, title: gameTitle(question.game), prompt: question.prompt,
                choices: question.choices, correctIndex: index,
                explanation: question.explanation.isEmpty ? fiche.shortDefinition : question.explanation
            )
        }

        let streak = StreakCalculator(day: day).summary(of: input.activity, at: now).current
        let todayActivity = input.activity.first { day.day(of: $0.day) == today }
        return WidgetSnapshot(
            generatedAt: now, day: today, isPremium: input.isPremium, cards: ordered.prefix(Rules.widgetCardCount).map(card),
            cardsByFamily: byFamily, reviews: reviews, dueReviewCount: due.count, streak: streak,
            isActiveToday: todayActivity?.isActive ?? false, sortedToday: todayActivity?.sorted ?? 0, dailyGoal: input.dailyGoal
        )
    }

    static func card(_ fiche: Fiche, grammar: String) -> WidgetSnapshot.Card {
        WidgetSnapshot.Card(
            id: fiche.id, headword: fiche.headword, phonetic: fiche.phonetic, grammar: grammar,
            shortDefinition: fiche.shortDefinition, confusion: fiche.confusions.first?.word,
            example: fiche.examples.first?.replacingOccurrences(of: "**", with: ""),
            quote: fiche.authorQuote?.text, quoteSource: fiche.authorQuote.map { "\($0.author), \($0.work)" },
            family: fiche.family.rawValue
        )
    }
}
