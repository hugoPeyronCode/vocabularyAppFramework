# 06 Plan de build

Chaque jalon part de `sagace-v4`, se termine par une PR, et n'est validé que si ses critères d'acceptation sont cochés. Ordre imposé : M0 → M9. Durées indicatives pour un développeur assisté de Claude Code.

## M0 Socle (3 jours)
Tâches
- Monter iOS 18.0, Swift 6, iPhone seul, App Group `group.com.cortex.VocabularyAppFramework` sur l'app (et plus tard le widget).
- Créer les packages locaux `SagaceCore`, `SagaceData`, `SagaceUI` et le dossier `App/` ; nouveau point d'entrée `SagaceApp` (l'ancien code reste compilé mais non utilisé jusqu'à M1).
- `SagaceUI` : tokens clair et sombre, styles de texte, `PrimaryButton`, `SecondaryButton`, `ConfirmButton`, `CircleButton`, `OptionRow`, `Chip`, `SheetContainer` (sheet flottante), `BottomTabs`, `HapticsService`. Une page de démonstration en debug qui montre tous les composants.
- `SagaceCore` : modèle `Fiche`, `ContentRepository` (chargement de `seed_fiches.json`), `Rules.swift`.
- `Localizable.xcstrings` créé, source fr.
Critères
- [ ] La page de démo s'affiche en clair et en sombre, conforme à `02_DESIGN_SYSTEM.md`.
- [ ] `swift test` passe sur `SagaceCore` (chargement et validation des 25 fiches).

## M1 Feed et migration (5 jours)
Tâches
- `SagaceData` : tous les `@Model`, conteneur dans l'App Group.
- FEED-01 (carte fiche, barre du haut, barre d'actions, frise des jours), tri Je savais / À retenir, pagination verticale, coachmarks TipKit.
- `FeedEngine` (sélection, pondération, mélange, limites), `ReviewScheduler` (Leitner), FEED-02 révision, FEED-03 maîtrisé, FEED-04 objectif, FEED-06 journée.
- `StreakService`.
- Migration v3 complète (`04_MIGRATION.md` section 7) + écran MIG-01. Puis suppression de l'ancien code Swift, des ressources v3 et du SDK Facebook.
Critères
- [ ] Tests unitaires : sélection du feed, intervalles Leitner, maîtrise, série, objectif.
- [ ] Une installation par dessus la v3 (simulateur avec `savedWords.json` et `UserDefaults` v3) importe les mots aimés et affiche MIG-01.
- [ ] Plus aucune référence à l'ancien code ni à Facebook ; l'app compile sans.

## M2 Fiche détaillée, partage, Explorer (4 jours)
Tâches : DET-01, DET-02 (file locale de signalements), SHR-01, EXP-01 à 03, LIB-01 à 05, `AudioService` (voix fr).
Critères
- [ ] Toutes les sections de DET-01 s'affichent ou se masquent proprement selon les champs présents.
- [ ] La carte de partage s'exporte en image en clair et en sombre.
- [ ] Recherche instantanée sur 1 000 fiches (< 50 ms).

## M3 Practice (5 jours)
Tâches : `QuestionFactory`, 6 jeux, sessions, résultats, défis Rush, Sprint, Perfection, test de précision et résultat de niveau, `StatsService` par compétence.
Critères
- [ ] Tests : génération de questions (jamais deux bonnes réponses, nature et genre respectés), seuils du test, règles de chaque défi.
- [ ] Une session complète de chaque jeu jouable de bout en bout avec haptiques.

## M4 Onboarding et paywall (4 jours)
Tâches : ONB-01 à ONB-12, `EntitlementService` (IDs v3 + nouveaux), PAY-01 avec frise et rappel activé par défaut, PAY-02 si simple, `PaywallPresenter` et toutes les sources, verrous PRO (bandeau violet) partout.
Critères
- [ ] Tests sandbox : achat annuel avec essai, achat à vie, restauration, abonné `weekly` existant reconnu, annulation.
- [ ] La notification de fin d'essai est planifiée 24 h avant la fin quand le toggle est actif.
- [ ] Un gratuit atteint ses limites (2 × objectif, 1 session par jour) et voit le bon paywall.

## M5 Stats, profil, réglages, rappels (4 jours)
Tâches : STA-01 à 03, succès, PRO-01, SET-01 (5 onglets), REM-01 avec `ReminderScheduler` et `BGAppRefreshTask`, VOI-01, APP-01, ICO-01 (6 icônes Sagace).
Critères
- [ ] Les rappels respectent le nombre, la plage horaire et les jours, avec un plafond de 60 notifications.
- [ ] Le changement d'apparence s'applique immédiatement partout.

## M6 Widgets (4 jours)
Tâches : extension `SagaceWidgets`, snapshot App Group, Fiche du jour (S, M, L), Révision interactive, Série, écran verrouillé (rectangulaire, en ligne), WID-01.
Critères
- [ ] Répondre à une révision depuis le widget met à jour la boîte de la fiche dans l'app.
- [ ] Les widgets sont lisibles en clair, sombre et teinté.

## M7 Améliorations avant publication et finitions (3 jours)
Tâches : revue d'animations, accessibilité (VoiceOver sur feed et jeux, Dynamic Type XXL), états vides, hors ligne, analytics complètes (`03_ARCHITECTURE.md` section 11), page Sources et licences.
Critères
- [ ] Audit VoiceOver sans élément muet sur FEED-01, PRA-02, PAY-01.
- [ ] Tous les événements analytics émis et vérifiés en console.

## M8 Contenu et anglais historique (en parallèle de M3 à M7, piloté par Hugo)
Tâches : pipeline `content/pipeline/` (étapes 1 à 8 de `05_CONTENT.md`), lot test de 200 fiches mesuré, puis 1 000 fiches ; script `convert_v3_en.py` et traduction anglaise de l'interface (option A).
Critères
- [ ] Taux d'erreur de l'échantillon ≤ 2 % sur le lot test.
- [ ] 1 000 fiches `autoChecked` ou `humanChecked` dans le pack.

## M9 Sortie (2 jours)
Tâches : icône, captures (`07_APP_STORE.md`), fiche App Store FR et EN, confidentialité, TestFlight bêta (boutons Juste / À corriger), version 4.0, soumission.
Critères
- [ ] TestFlight externe validé par au moins 30 testeurs, aucun crash sur 3 jours.
- [ ] Soumission envoyée avec les notes de review.

## Prompts de démarrage pour Claude Code
- M0 : « Lis CLAUDE.md et docs/sagace dans l'ordre. Réalise le jalon M0 de 06_BUILD_PLAN.md sur une branche m0-socle. Commence par le package SagaceUI et sa page de démo. »
- Ensuite, pour chaque jalon : « Réalise le jalon Mn. Avant chaque écran, relis sa fiche dans 01_SCREENS.md. Termine par la liste des critères cochés et ce qui reste ouvert dans OPEN_QUESTIONS.md. »
