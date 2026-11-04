# CLAUDE.md : Sagace (mise à jour v4 de l'app Words)

Ce dépôt contient l'app iOS **Words** (bundle `com.cortex.VocabularyAppFramework`, équipe `YA24P24868`, v3.0 en ligne). On la reconstruit entièrement à l'intérieur du même projet Xcode pour publier la **v4.0 sous le nom Sagace**, en mise à jour de l'app existante. Toute la spec est dans `docs/sagace/`. Lis `docs/sagace/README.md` en premier, puis les documents dans l'ordre indiqué.

## Ce qu'on construit, en une phrase
Une app française qui apprend à employer le mot juste au quotidien : une fiche par écran (paronymes, impropriétés, verbes passe partout, nuances, pléonasmes, anglicismes), une phrase d'auteur du domaine public sur chaque fiche, des révisions espacées, des jeux courts, un widget. Design inspiré de Sudoku a Day, clair et sombre.

## Règles non négociables
- **Swift 6, SwiftUI, iOS 18.0 minimum**, iPhone uniquement en v4 (retirer l'iPad de `TARGETED_DEVICE_FAMILY`).
- **MVVM strict** : vues sans logique, view models `@MainActor @Observable`. **Jamais** `ObservableObject`, `@Published`, `@StateObject`, `@EnvironmentObject`.
- **SwiftData** pour l'état utilisateur, dans le conteneur App Group `group.com.cortex.VocabularyAppFramework`.
- Le contenu (fiches) est un **pack JSON en lecture seule**, validé par `content/schema/fiche.schema.json`. Jamais de contenu en dur dans le code.
- **Toute la logique métier dans le package `SagaceCore`** (Swift pur, sans SwiftUI ni SwiftData), couverte par des tests Swift Testing. Les règles chiffrées sont dans `docs/sagace/03_ARCHITECTURE.md` section 7 : les appliquer à l'identique, et toute valeur nouvelle va dans `SagaceCore/Rules.swift`.
- **Haptique sur chaque interaction utile** via `HapticsService` (table dans `02_DESIGN_SYSTEM.md` section 8).
- **Interface en français**, toutes les chaînes dans `Localizable.xcstrings` (source fr). Aucune chaîne visible en dur.
- **Couleurs, typo, rayons uniquement via `SagaceUI`** (tokens de `02_DESIGN_SYSTEM.md`). Aucune couleur littérale dans les vues.
- **Ne jamais casser un achat existant** : les identifiants `Yearly`, `weekly`, `lifetime` restent reconnus comme premium (voir `04_MIGRATION.md`).
- Pas de SDK tiers sans accord explicite d'Hugo. Le SDK Facebook actuel est retiré (voir `04_MIGRATION.md`).

## Méthode de travail
1. Suivre `docs/sagace/06_BUILD_PLAN.md` jalon par jalon. Un jalon = une branche `m<n>-<nom>` depuis `sagace-v4`, une PR, des critères d'acceptation cochés.
2. Avant de coder un écran, relire sa fiche dans `01_SCREENS.md` et, pour la structure fine, la capture de référence Vocabulary indiquée (chemin ci dessous).
3. Écrire les tests de `SagaceCore` avant ou avec le code.
4. Build et tests à chaque étape :
   ```
   xcodebuild -scheme VocabularyAppFramework -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   xcodebuild -scheme VocabularyAppFramework -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
   swift test --package-path Packages/SagaceCore
   ```
5. Vérifier chaque écran en clair **et** en sombre, en Dynamic Type standard et XXL.
6. Si une décision produit manque, ne pas inventer : la noter dans `docs/sagace/OPEN_QUESTIONS.md` et prendre l'option la plus simple, réversible.

## Références hors dépôt (Mac d'Hugo)
- Captures et spec écran par écran de Vocabulary (référence de **structure** uniquement, le visuel est remplacé) : `~/Documents/Hugo's/Cortex SASU/Produits/Words/Vocabulary Rebuild/` (fichiers `Vocabulary Rebuild Écrans A…D` et dossier `Screens/`).
- Analyse business : `~/Documents/Hugo's/Cortex SASU/Produits/Words/Vocabulary Deconstruction.md`.

## Définition de "terminé" pour un jalon
- Compile sans warning nouveau, tests verts.
- Clair et sombre vérifiés, haptiques branchées, chaînes dans le catalogue.
- Événements analytics du jalon émis (liste dans `03_ARCHITECTURE.md` section 11).
- Critères d'acceptation du jalon cochés dans la PR.
