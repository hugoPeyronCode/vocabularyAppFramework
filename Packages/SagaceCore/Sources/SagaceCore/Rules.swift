import Foundation

/// Toutes les règles chiffrées de Sagace (`docs/sagace/03_ARCHITECTURE.md` section 7).
/// Toute nouvelle valeur métier va ici, jamais en dur ailleurs.
public enum Rules {

    // MARK: Feed

    /// Choix de rythme proposés (fiches nouvelles par jour).
    public static let dailyGoalOptions = [3, 5, 10]
    public static let defaultDailyGoal = 5
    /// Rythme réservé au premium.
    public static let premiumDailyGoal = 10
    /// Écart de niveau accepté autour du niveau de l'utilisateur.
    public static let feedLevelSpread = 1
    /// Gratuit : jusqu'à `freeNewFichesMultiplier × dailyGoal` fiches nouvelles par jour.
    public static let freeNewFichesMultiplier = 2
    /// Heure locale du nouveau lot.
    public static let newBatchHour = 4
    /// Une fiche glissée sans tri peut revenir après ce nombre de jours.
    public static let unsortedReturnDays = 7
    /// Délai avant le passage automatique après un tri (secondes).
    public static let sortAutoAdvanceDelay: TimeInterval = 0.3
    /// Pondération des thèmes, familles ou niveaux selon les objectifs d'onboarding.
    public static let goalWeight = 1.5
    public static let childrenGoalWeight = 1.3
    public static let childrenGoalMaxLevel = 2
    public static let workGoalThemes = ["travail", "argent"]
    public static let confidenceGoalThemes = ["relations", "emotions"]
    public static let examGoalFamilies: [Family] = [.impropriete, .motMalCompris]
    /// Niveau tant que l'onboarding (M4) ne l'a pas fixé.
    public static let defaultLevel = Level.intermediaire
    /// Une fiche apparue au feed compte comme vue après ce délai à l'écran (secondes).
    public static let ficheViewedDelay: TimeInterval = 1

    // MARK: Explorer et bibliothèque

    /// Gratuit : nombre de fiches visibles dans une famille ou un thème avant le bandeau PRO.
    public static let freeFichesPerTopic = 3
    public static let searchMaxResults = 50
    /// Historique : jours affichés par page ("Voir plus ancien").
    public static let historyPageDays = 7
    public static let ownWordMinLength = 1

    // MARK: Révisions (Leitner)

    public static let maxBox = 4
    /// Intervalle en jours avant la prochaine révision, par boîte.
    public static let reviewIntervalDays: [Int: Int] = [1: 1, 2: 3, 3: 7, 4: 21]

    public static func reviewIntervalDays(forBox box: Int) -> Int? { reviewIntervalDays[box] }

    // MARK: Série et rappels

    public static let eveningReminderHour = 20
    public static let eveningReminderMinute = 30
    public static let eveningReminderMinStreak = 2
    public static let reminderHorizonDays = 7
    public static let maxScheduledNotifications = 60
    public static let freeReminderCount = 1
    public static let reminderMaxPerDay = 10
    public static let reminderStepMinutes = 30
    public static let defaultReminderStartMinute = 9 * 60
    public static let defaultReminderEndMinute = 21 * 60

    // MARK: Questions et sessions

    public static let defaultChoiceCount = 3
    /// Mauvaises réponses : une confusion dont la forme est au moins à ce point proche est un paronyme
    /// (bonne mauvaise réponse) ; en dessous, c'est une confusion de sens, trop fine hors du Juste ou fautif.
    public static let paronymFormThreshold = 0.5
    /// Mauvaises réponses tirées parmi les plus proches de la bonne, pour varier d'une partie à l'autre.
    public static let decoyShortlist = 4
    /// Proximité : début de mot partagé compté à partir de 3 lettres (4 pour une fin de mot).
    public static let proximityMinAffix = 3
    public static let proximityMinKeywordLength = 4
    public static let proximityStemLength = 6
    public static let proximityThemeBonus = 0.15

    // MARK: Widgets

    /// Fiches préparées pour les widgets (fiche du jour d'abord).
    public static let widgetCardCount = 24
    /// Premium : fiches par famille, pour les widgets filtrés.
    public static let widgetCardsPerFamily = 8
    /// Révisions dues préparées en questions pour le widget de révision.
    public static let widgetReviewCount = 5
    /// Rafraîchissement "Toutes les heures" : entrées de la frise (une journée).
    public static let widgetHourlyEntries = 24

    // MARK: Mot croisé

    /// Mots par grille : on vise 5, on accepte 3.
    public static let crosswordWordCount = 5
    public static let crosswordMinWordCount = 3
    /// Longueur des réponses (lettres) ; un mot plus court ne forme pas une définition.
    public static let crosswordWordLength = 3...7
    public static let crosswordMinWordLength = 2
    /// Côté maximal de la grille, en cases (tient en largeur sur un iPhone).
    public static let crosswordMaxSide = 7
    /// Essais de placement ; la grille la plus riche gagne.
    public static let crosswordAttempts = 40
    public static let justeOuFautifChoiceCount = 2
    public static let sessionLength = 10
    public static let freeSessionsPerDay = 1
    public static let rushSecondsPerQuestion: TimeInterval = 5
    public static let rushLives = 3
    public static let sprintDuration: TimeInterval = 60

    // MARK: Test de précision

    public static let levelTestQuestionsPerLevel = 6
    public static let levelTestLength = levelTestQuestionsPerLevel * Level.allCases.count
    /// Score minimal pour atteindre chaque niveau.
    public static let levelTestThresholds: [Level: Int] = [
        .debutant: 0, .elementaire: 7, .intermediaire: 13, .avance: 19, .expert: 25,
    ]
    public static let miniTestLength = 5
    public static let miniTestQuestionLevel = Level.intermediaire
    public static let miniTestFamilies: [Family] = [.paronyme, .impropriete, .passePartout, .nuance, .pleonasme]

    /// Niveau obtenu au test de précision (30 questions).
    public static func level(forLevelTestScore score: Int) -> Level {
        Level.allCases.last { score >= levelTestThresholds[$0]! } ?? .debutant
    }

    /// Points manquants avant le niveau suivant, `nil` au niveau Expert.
    public static func pointsToNextLevel(forLevelTestScore score: Int) -> Int? {
        guard let next = level(forLevelTestScore: score).next else { return nil }
        return levelTestThresholds[next]! - score
    }

    /// Niveau de départ après le mini test d'onboarding (5 questions).
    public static func level(forMiniTestScore score: Int) -> Level {
        switch score {
        case ...2: .debutant
        case 3: .intermediaire
        case 4: .avance
        default: .expert
        }
    }

    // MARK: Stats

    public static let statsWindowDays = 14
    public static let statsMinAnswers = 10
    /// Écart (en points de pourcentage) au delà duquel une compétence est suggérée.
    public static let weakSkillGap = 10.0

    // MARK: Contenu

    public static let shortDefinitionMaxLength = 90
    public static let quizExplanationMaxLength = 160
    public static let usageExplanationMaxLength = 200
    public static let nuanceMaxLength = 300
    public static let examplesRange = 2...3
    public static let quizChoicesRange = 2...3

    // MARK: Achats

    /// Identifiants reconnus comme premium. Les trois premiers viennent de Words v3 : ne jamais les retirer.
    public static let premiumProductIDs: Set<String> = ["Yearly", "weekly", "lifetime"]
}
