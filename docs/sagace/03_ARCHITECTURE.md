# 03 Architecture

## 1. Stack
| Besoin | Choix |
| -- | -- |
| Cible | iOS 18.0+, iPhone, Swift 6 (mode strict de concurrence) |
| UI | SwiftUI, Observation (`@Observable`) |
| État utilisateur | SwiftData, conteneur dans l'App Group `group.com.cortex.VocabularyAppFramework` |
| Contenu | Pack JSON embarqué `content/fr/fiches.json` (+ `topics.json`), chargé en mémoire, versionné, mise à jour distante plus tard |
| Achats | StoreKit 2, paywall maison |
| Notifications | `UserNotifications` locales |
| Widgets | WidgetKit + App Intents (interactifs) |
| Audio | `AVSpeechSynthesizer`, voix `fr-FR` et `fr-CA` |
| Partage | `ImageRenderer` + `ShareLink` |
| Coachmarks | TipKit |
| Tâches de fond | `BGAppRefreshTask` pour replanifier les rappels |
| Langue | String Catalog `Localizable.xcstrings`, source `fr` |
| Analytics | protocole `Analytics` ; implémentation TelemetryDeck (à confirmer avec Hugo), console en debug |
| Tests | Swift Testing pour `SagaceCore`, XCUITest pour l'onboarding et l'achat sandbox |

## 2. Structure du dépôt (cible)

```
VocabularyAppFramework.xcodeproj        projet existant conservé (bundle, équipe, signature)
App/                                    nouveau code de l'app (remplace VocabularyAppFramework/*.swift)
├── SagaceApp.swift                     @main, ModelContainer, AppDependencies, migration
├── Routing/                            AppRouter, Sheet, PaywallSource
├── Features/
│   ├── Onboarding/                     ONB-01 à ONB-12
│   ├── Feed/                           FEED-01 à 06
│   ├── Fiche/                          DET-01, DET-02, SHR-01
│   ├── Explore/                        EXP, LIB
│   ├── Practice/                       PRA (hub, session, défis, test, résultats)
│   ├── Stats/
│   ├── Profile/                        PRO, SET, REM, WID, VOI, APP, ICO
│   ├── Paywall/
│   └── Migration/                      MIG-01
├── Resources/                          Assets.xcassets (couleurs, icônes alternatives, illustrations), Localizable.xcstrings
└── Content/fr/                         fiches.json, topics.json (copiés depuis content/fr au build)
Packages/
├── SagaceCore/                         Swift pur : modèles de contenu, moteurs, règles, planification. Tests.
├── SagaceData/                         @Model SwiftData, repositories, migration v3
└── SagaceUI/                           tokens, styles de texte, composants, HapticsService
SagaceWidgets/                          extension WidgetKit + App Intents
content/                                schéma, fiches sources, scripts du pipeline (hors bundle)
docs/sagace/                            cette spec
```

L'ancien code (`VocabularyAppFramework/` : HomeView, WordManager, QCM, Anagrams…) est supprimé à la fin du jalon M1, une fois la migration écrite (voir `04_MIGRATION.md`).

## 3. Contenu : modèle d'une fiche (lecture seule)

Schéma de référence : `content/schema/fiche.schema.json`. Exemples : `content/fr/seed_fiches.json`.

```swift
public struct Fiche: Codable, Identifiable, Hashable, Sendable {
    public let id: String                  // "fr.eminent"
    public let language: String            // "fr"
    public let headword: String
    public let family: Family              // .paronyme .impropriete .passePartout .nuance .pleonasme .anglicisme .motMalCompris .expression
    public let themes: [String]            // ids de topics.json : "travail", "emotions"…
    public let partOfSpeech: PartOfSpeech  // .nom .verbe .adjectif .adverbe .locution .preposition
    public let gender: Gender?             // .masculin .feminin .epicene, obligatoire si nom
    public let register: Register          // .courant .soutenu .familier .litteraire
    public let phonetic: String            // API, ex. "/e.mi.nɑ̃/"
    public let shortDefinition: String     // 90 caractères max
    public let definition: String          // sens complet
    public let confusions: [Confusion]     // { word, meaning, example }
    public let usage: UsageNote?           // { correct, avoid, verdict: .fautif .critique .tolere, explanation }
    public let nuance: String?
    public let examples: [String]          // 2 phrases modernes, le mot entre ** **
    public let authorQuote: AuthorQuote?   // { text, author, work, year, url }
    public let synonyms: [String]
    public let etymology: String?
    public let level: Int                  // 1 à 5 (Débutant à Expert)
    public let frequencyRank: Int?         // rang Lexique 3
    public let quiz: [QuizItem]            // questions prêtes à l'emploi pour révisions et jeux (voir 05_CONTENT)
    public let sources: [SourceRef]        // { name, url } : au moins 1
    public let reviewStatus: ReviewStatus  // .draft .autoChecked .humanChecked
}
```

`ContentRepository` charge le pack en tâche détachée au lancement, indexe par famille, thème, niveau, et expose des requêtes pures. Seules les fiches `autoChecked` ou `humanChecked` sont visibles en production.

## 4. État utilisateur (SwiftData)

```swift
@Model final class UserProfile {            // singleton
    var firstName: String?
    var ageRange: AgeRange?
    var attribution: AttributionSource?
    var goals: [LearningGoal]                // ecrireTravail, parlerAssurance, examen, enfants, curiosite
    var level: Int                           // 1…5, onboarding puis test
    var hasCompletedOnboarding: Bool
    var migratedFromV3: Bool
    var createdAt: Date
}

@Model final class Preferences {            // singleton
    var dailyGoal: Int                       // 3, 5, 10
    var followedFamilies: [String]
    var followedThemes: [String]
    var showFamiliar: Bool                   // expressions familières
    var mutedTerms: [String]
    var voiceIdentifier: String?
    var appearance: Appearance               // .automatic .light .dark
    var soundMode: SoundMode                 // .muted .effects .effectsAndAmbience
    var hapticsEnabled: Bool                 // true
    var animationsEnabled: Bool              // true
    var autoAdvance: Bool                    // true
    var eveningStreakReminder: Bool          // true
}

@Model final class FicheState {             // une ligne par fiche rencontrée
    @Attribute(.unique) var ficheID: String
    var firstSeenAt: Date
    var lastSeenAt: Date
    var sorting: Sorting?                    // .known ("Je savais") .toLearn ("À retenir")
    var sortedAt: Date?
    var box: Int                             // 0 = hors révision, 1…4 boîtes de Leitner
    var nextReviewAt: Date?
    var masteredAt: Date?
    var correctCount: Int
    var wrongCount: Int
}

@Model final class Collection { var name: String; var ficheIDs: [String]; var isFollowed: Bool; var createdAt: Date }
@Model final class OwnWord { var headword: String; var definition: String; var partOfSpeech: PartOfSpeech; var gender: Gender?; var createdAt: Date }
@Model final class PracticeSession { var mode: PracticeMode; var startedAt: Date; var endedAt: Date?; var score: Int; var total: Int
    @Relationship(deleteRule: .cascade) var answers: [PracticeAnswer] }
@Model final class PracticeAnswer { var ficheID: String; var game: GameType; var skill: Skill; var isCorrect: Bool; var responseMs: Int; var answeredAt: Date }
@Model final class LevelTestResult { var score: Int; var outOf: Int; var level: Int; var takenAt: Date }
@Model final class ActivityDay { @Attribute(.unique) var day: Date; var sorted: Int; var reviewsDone: Int; var sessions: Int; var goalReached: Bool }
@Model final class Reminder { var source: ReminderSource; var sourceID: String?; var count: Int; var startMinute: Int; var endMinute: Int; var weekdays: [Int]; var soundID: String; var isEnabled: Bool }
@Model final class WidgetConfig { var kind: WidgetKindRaw; var families: [String]; var refresh: RefreshRate; var showQuote: Bool }
@Model final class ErrorReport { var ficheID: String; var reason: String; var comment: String?; var createdAt: Date; var sent: Bool }
@Model final class Achievement { @Attribute(.unique) var id: String; var unlockedAt: Date }
```

## 5. Services et injection

```swift
@MainActor @Observable final class AppDependencies {
    let content: ContentRepository
    let feed: FeedEngine
    let reviews: ReviewScheduler          // Leitner
    let questions: QuestionFactory
    let streaks: StreakService
    let stats: StatsService
    let reminders: ReminderScheduler
    let entitlements: EntitlementService  // StoreKit 2, isPremium observable, IDs v3 compris
    let paywall: PaywallPresenter
    let audio: AudioService
    let widgets: WidgetBridge
    let haptics: HapticsService
    let analytics: Analytics
    let share: ShareCardRenderer
    let reports: ErrorReportService       // envoi des signalements (endpoint à définir, file locale en attendant)
}
```
Injecté une fois via `.environment`. Chaque view model reçoit dans son `init` les seuls services utiles (protocoles, pour les fakes de test).

## 6. Navigation
Pas de tab bar. Le feed est la racine. Tout le reste s'ouvre en sheet flottante, avec `NavigationStack` interne pour les sous pages. Onboarding et migration en `fullScreenCover`.

```swift
enum Sheet: Identifiable, Hashable {
    case explore, profile, stats, practice, day(Date)
    case fiche(String), share(String), report(String)
    case session(PracticeMode), levelTest
    case paywall(PaywallSource)
    var id: Self { self }
}

@MainActor @Observable final class AppRouter {
    var sheet: Sheet?
    var stackedPaywall: PaywallSource?       // paywall par dessus une sheet ouverte
    var fullScreen: FullScreen?              // .onboarding .migration
    func requirePremium(_ source: PaywallSource, isPremium: Bool, then action: () -> Void) {
        isPremium ? action() : (stackedPaywall = source)
    }
}
```

## 7. Règles chiffrées (toutes dans `SagaceCore/Rules.swift`)

### Feed
- Lot du jour = `dailyGoal` fiches nouvelles (3, 5 ou 10).
- Sélection : fiches visibles, non triées, non masquées (`mutedTerms`), `register == .familier` exclu si `showFamiliar == false`, niveau dans {niveau utilisateur − 1, niveau, niveau + 1}, familles et thèmes suivis (tous si aucun).
- Pondération des thèmes par objectifs : écrire au travail → `travail` et `argent` ×1,5 ; parler avec assurance → `relations`, `emotions` ×1,5 ; examen → famille `impropriete` et `motMalCompris` ×1,5 ; enfants → niveau ≤ 2 ×1,3 ; curiosité → aucun.
- Mélange : jamais 2 fiches de la même famille d'affilée.
- Une fiche glissée sans tri reste "vue" (`lastSeenAt`) et peut revenir après 7 jours.
- Gratuit : jusqu'à 2 × `dailyGoal` fiches nouvelles par jour, puis carte de fin. Premium : sans limite.
- Nouveau lot à 4 h du matin heure locale.

### Révisions (Leitner)
- "À retenir" → boîte 1, `nextReviewAt` = demain.
- Intervalles : boîte 1 → 1 jour, 2 → 3 jours, 3 → 7 jours, 4 → 21 jours.
- Révision juste : boîte + 1 ; si la révision juste se fait en boîte 4 → `masteredAt` = maintenant (mot maîtrisé), boîte 0.
- Révision fausse : boîte 1.
- Dans le feed : après chaque groupe de 5 fiches, insérer 1 révision due (la plus ancienne). Les révisions ne comptent pas dans l'anneau mais comptent comme activité.
- "Je savais" : `sorting = .known`, jamais revue. Un "Je savais" faux est possible ; on ne le vérifie pas en v4.

### Objectif et série
- Objectif atteint quand le nombre de fiches **triées** dans la journée ≥ `dailyGoal`.
- Jour actif = au moins 1 tri, 1 révision ou 1 session. Série = jours actifs consécutifs jusqu'à aujourd'hui (ou hier si aujourd'hui pas encore actif).
- Jour parfait = objectif atteint.
- Rappel du soir à 20:30 si aucun jour actif aujourd'hui et série ≥ 2.

### Questions (QuestionFactory)
- Priorité aux `quiz` écrits dans la fiche (qualité contrôlée). Sinon génération :
  - Le mot juste / Paronymes : une phrase d'exemple avec le mot en blanc, choix = le mot + ses `confusions` (complétées par des fiches de même famille, même nature, même genre si nom).
  - Juste ou fautif : `usage.correct` ou `usage.avoid` tiré au hasard (50/50).
  - Passe partout : phrase de `usage.avoid`, choix = le verbe précis + 2 verbes de la même famille.
  - Sens : le mot, 3 définitions courtes (distracteurs de même nature).
  - Devine le mot : la définition courte, 3 mots.
- Jamais un synonyme listé comme mauvaise réponse. Toujours 3 choix sauf Paronymes (2 ou 3) et Juste ou fautif (2).
- Compétences : Sens (Sens, Devine le mot) · Usage (Juste ou fautif, Paronymes) · Choix du mot (Le mot juste, Passe partout).

### Sessions et défis
- Session de jeu : 10 questions, feedback après chaque réponse.
- Rush : questions Le mot juste ou Paronymes, 5 s par question, 3 vies, erreur ou temps écoulé = 1 vie. Score = justes / répondues.
- Sprint : 60 s au total, pas de vies, score = justes.
- Perfection : sans limite, fin à la première erreur, score = série.
- Gratuit : 1 session de jeu par jour (défis compris), test illimité.

### Test de précision
- 30 questions, 6 par niveau (1 à 5), toutes familles, passage automatique 0,8 s.
- Seuils : 0 à 6 Débutant · 7 à 12 Élémentaire · 13 à 18 Intermédiaire · 19 à 24 Avancé · 25 à 30 Expert. "Points avant le niveau suivant" = borne suivante − score.
- Le résultat remplace `UserProfile.level`.
- Mini test d'onboarding : 5 questions (une par famille principale, niveau 3). 0 à 2 → 1 (Débutant), 3 → 3, 4 → 4, 5 → 5.

### Stats
- Précision par compétence : moyenne des réponses des 14 derniers jours, affichée si ≥ 10 réponses.
- Compétence suggérée : la plus faible si elle a plus de 10 points de retard sur la moyenne des deux autres.

### Succès (v4)
`serie_3`, `serie_7`, `serie_30`, `maitrise_10`, `maitrise_50`, `maitrise_100`, `test_expert`, `toutes_familles` (au moins 1 fiche triée dans chaque famille), `rush_20` (20 justes en Rush).

### Rappels
- `count` notifications réparties à intervalles égaux entre début et fin, jours cochés. Une seule si `count == 1` (à l'heure de début).
- Planification glissante sur 7 jours, plafond 60 notifications, replanifiée à chaque ouverture et en `BGAppRefreshTask`.
- Contenu figé à la planification : *mot, ou confusion* en titre, définition courte en corps.
- Gratuit : 1 rappel. Premium : illimité.

## 8. Exemple de view model (machine à états)

```swift
@MainActor @Observable final class PracticeSessionViewModel {
    enum Phase: Equatable { case question, answered(correct: Bool), finished }
    private(set) var questions: [Question] = []
    private(set) var index = 0
    private(set) var phase: Phase = .question
    private(set) var selectedChoice: Int?
    private(set) var score = 0
    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var progress: Double { Double(index + (phase == .question ? 0 : 1)) / Double(max(questions.count, 1)) }

    private let mode: PracticeMode
    private let factory: QuestionFactory
    private let recorder: PracticeRecorder
    private let haptics: HapticsService
    private let analytics: Analytics
    private var shownAt = Date()

    init(mode: PracticeMode, factory: QuestionFactory, recorder: PracticeRecorder, haptics: HapticsService, analytics: Analytics) {
        self.mode = mode; self.factory = factory; self.recorder = recorder; self.haptics = haptics; self.analytics = analytics
    }
    func start() { questions = factory.make(for: mode, count: Rules.sessionLength); shownAt = .now; analytics.track(.practiceStarted(mode)) }
    func select(_ choice: Int) {
        guard phase == .question, let q = current else { return }
        selectedChoice = choice
        let correct = choice == q.correctIndex
        if correct { score += 1 }
        haptics.notify(correct ? .success : .error)
        recorder.record(q, correct: correct, ms: Int(Date.now.timeIntervalSince(shownAt) * 1000))
        phase = .answered(correct: correct)
    }
    func next() {
        guard case .answered = phase else { return }
        index += 1; selectedChoice = nil
        if index >= questions.count {
            phase = .finished
            recorder.finish(mode: mode, score: score, total: questions.count)
            analytics.track(.practiceCompleted(mode, score: score, total: questions.count))
        } else { phase = .question; shownAt = .now }
    }
}
```
Le même moteur sert le test (passage automatique) et les défis (`ChallengeRules` ajoute timer et vies).

## 9. Widgets
- L'app écrit un **snapshot** JSON dans l'App Group à chaque changement utile (`WidgetSnapshot` : 24 prochaines fiches par configuration, prochaine révision due, série). Le widget ne fait aucun calcul lourd.
- **Fiche du jour** (small, medium, large) : mot, définition courte, confusion principale ; large ajoute la phrase d'auteur. Boutons interactifs (`Button(intent:)`) : suivante, À retenir.
- **Révision** (medium) : question + 3 réponses ; `AnswerReviewIntent` note la réponse dans la boîte d'envoi de l'App Group (`WidgetInbox`) et affiche l'explication jusqu'à « Continuer ». L'app applique la boîte d'envoi à l'ouverture et au retour au premier plan (`WidgetBridge`) : la boîte de Leitner de la fiche est mise à jour à l'heure de la réponse. Seule l'app ouvre la base SwiftData (`OPEN_QUESTIONS.md` n° 57).
- **Série** (small) : flamme, nombre de jours, anneau du jour.
- **Écran verrouillé** : `accessoryRectangular` (mot + définition courte), `accessoryInline` (mot ≠ confusion).
- Rafraîchissement : toutes les heures, 2 fois par jour, 1 fois par jour (par défaut).
- Apparence système, rendu teinté géré via `widgetRenderingMode`.
- `WidgetBridge.refresh()` au lancement, au retour au premier plan, au passage en arrière-plan et au changement de premium (les widgets ne sont visibles que l'app en arrière-plan).

## 10. Achats (détail dans `04_MIGRATION.md`)
- `EntitlementService` écoute `Transaction.updates` et lit `Transaction.currentEntitlements` au lancement.
- Premium = entitlement actif sur `Yearly`, `weekly` ou `lifetime` (identifiants v3 conservés) ou sur tout nouvel identifiant listé dans `Rules.premiumProductIDs`.
- Paywall : `PaywallPresenter` décide de l'affichage selon `PaywallSource` ; rappel de fin d'essai = notification locale 24 h avant la fin, activée par défaut.

## 11. Analytics (événements v4)
| Événement | Propriétés |
| -- | -- |
| `onboarding_step_viewed` | step |
| `onboarding_completed` | mini_test_score, daily_goal, notifications_granted |
| `paywall_viewed` | source |
| `purchase_completed` | product_id |
| `fiche_viewed` | fiche_id, family, origin (feed, widget, notification, explore) |
| `fiche_sorted` | fiche_id, sorting (known, to_learn) |
| `review_answered` | fiche_id, box, correct |
| `fiche_mastered` | fiche_id, days_to_master |
| `daily_goal_completed` | streak |
| `practice_started` / `practice_completed` | mode, score, total |
| `level_test_completed` | score, level |
| `widget_interaction` | kind, action |
| `notification_opened` | reminder_source |
| `error_reported` | fiche_id, reason |
| `migration_v3_completed` | had_saved_words, was_premium |

Questions à suivre dès la sortie : part des installs avec widget au J1 ; rétention J7 avec et sans widget ; fiches maîtrisées par actif à J30 ; conversion d'essai par source de paywall.
