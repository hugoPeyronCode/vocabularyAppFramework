# 04 Migration depuis Words v3

Sagace v4.0 est une **mise à jour** de l'app Words existante. Les utilisateurs actuels la recevront automatiquement. Ce document liste ce qui existe, ce qu'on garde, ce qu'on retire, et comment ne rien casser.

## 1. État actuel du dépôt (relevé le 4 novembre 2026, branche `master`, commit `4e59fac`, décembre 2024)
| Élément | Valeur actuelle |
| -- | -- |
| Projet / cible / schéma | `VocabularyAppFramework` |
| Bundle ID | `com.cortex.VocabularyAppFramework` |
| Équipe | `YA24P24868` |
| Nom affiché | Words |
| Version | 3.0 (build 1) |
| Déploiement | iOS 17.6 (une config à 16.4), iPhone et iPad |
| Langue du contenu | anglais, `Data/words.json` : 24 939 mots (Rank, List, Headword, Definition, Context sentence, Synonyms, Antonyms, Topic) |
| Persistance | `Documents/savedWords.json` (mots likés, tableau de `Word`), `UserDefaults` : `isShowingOnboarding`, `active_icon`, `quizApparitionValue`, `com.words.premiumAccess` |
| Achats (fichier `.storekit`) | groupe "Yearly" : `Yearly` (1 an, 17,99), `weekly` (1 semaine, 2,99) ; non consommable `lifetime` (99,99) |
| Dépendances | SDK Facebook (`facebook-ios-sdk` via SPM), `FacebookAppID` dans Info.plist |
| Icônes alternatives | `AppIcon1` à `AppIcon25`, sélection via `active_icon` |
| Notifications | locales, planifiées par `NotificationsSettingsViewModel` |
| Attention | `StoreKitManager.hasUnlockedPremium` renvoie `true` en dur dans le code : vérifier dans App Store Connect si la build en ligne a ce comportement (tout le monde premium) |

## 2. À confirmer par Hugo avant le jalon M1 (bloquant)
1. Ce dépôt est bien la source de la version en ligne (comparer version et build avec App Store Connect).
2. Apple ID de l'app, nom actuel sur le store, pays de disponibilité, langue principale.
3. Nombre d'abonnés actifs et d'achats à vie (App Store Connect › Abonnements), pour dimensionner la question de l'anglais (section 6).
4. Utilisation du SDK Facebook pour des campagnes Meta en cours. Par défaut : retrait.

## 3. Ce qu'on garde
- Projet Xcode, cible, bundle ID, équipe, App Group à créer : `group.com.cortex.VocabularyAppFramework`.
- Identifiants de produits `Yearly`, `weekly`, `lifetime` : **toujours reconnus comme premium**.
- La fiche App Store (même Apple ID) : renommée Sagace via la nouvelle version.

## 4. Ce qu'on retire
- Tout l'ancien code Swift de `VocabularyAppFramework/` (vues, managers, modèles), après écriture de la migration.
- `Data/words.json` et `quotes21.json` du bundle (voir section 6 pour l'anglais).
- Le SDK Facebook et `FacebookAppID` (sauf décision contraire d'Hugo).
- Les 25 icônes alternatives (remplacées par 6 icônes Sagace).
- Les fonds d'écran et polices de thèmes v3 (`Backgrounds`, `Sorts_Mill_Goudy`…), `VocabAppContent/` (dossier de travail).
- Le support iPad (`TARGETED_DEVICE_FAMILY = 1`). Attention : les utilisateurs iPad actuels ne recevront plus de mises à jour sur iPad ; si App Store Connect montre une part iPad notable, garder `1,2` avec la mise en page iPhone centrée.

## 5. Achats : règles
1. **Réutiliser** `Yearly` (prix nouveau 29,99 €, offre d'introduction 3 jours gratuits à configurer dans App Store Connect pour les nouveaux abonnés) et `lifetime` (49,99 €).
2. `weekly` : retirer de la vente dans App Store Connect (les abonnés en cours restent premium jusqu'à expiration).
3. Les changements de prix des abonnés existants : appliquer le nouveau prix **aux nouveaux abonnés seulement** (option "conserver le prix actuel pour les abonnés existants").
4. Offre de bienvenue (`PAY-02`) : offre promotionnelle sur `Yearly`, à créer dans App Store Connect avec signature côté serveur, **ou** à défaut une offre d'introduction alternative ; si trop complexe en v4, la retirer (décision : la plus simple).
5. `EntitlementService` : au premier lancement de la v4, lire `Transaction.currentEntitlements` ; ignorer `com.words.premiumAccess` (clé locale non fiable) sauf si aucune transaction n'est trouvée **et** que la clé vaut `true` : dans ce cas, accorder le premium (cas d'un achat ancien non relu) et le journaliser.
6. Tester en sandbox : abonné `Yearly` actif, `weekly` actif, `lifetime`, aucun achat, restauration.

## 6. Utilisateurs anglophones actuels (décision à prendre)
Words v3 est en anglais. Sagace v4 est en français.
- **Option A (par défaut)** : garder un **pack anglais historique** pour les appareils dont la langue n'est pas le français, converti depuis `words.json` vers le format `Fiche` (champs disponibles : mot, définition, exemple, synonymes, antonymes, thème ; famille = `motMalCompris`, pas de confusion ni d'usage ni de phrase d'auteur, `reviewStatus = .draft` mais visible pour ce pack seulement). Interface traduite en anglais via le String Catalog. Le feed et les révisions fonctionnent ; les jeux Paronymes, Juste ou fautif et Passe partout sont masqués.
- **Option B** : tout le monde en français. Plus simple, mais l'app devient inutilisable pour les anglophones existants.
- **Option C** : restreindre la disponibilité aux pays francophones. Les utilisateurs existants ailleurs gardent la v3 sans mises à jour.

Le jalon M8 prévoit l'option A sauf avis contraire d'Hugo.

## 7. Migration au premier lancement de la v4 (`MIG-01`)
Exécutée une seule fois, si `UserDefaults` contient `isShowingOnboarding` ou si `Documents/savedWords.json` existe.
1. Lire `savedWords.json` : pour chaque mot liké, si une fiche du pack anglais historique correspond (`Headword` identique, insensible à la casse), créer `FicheState(sorting: .toLearn, box: 1)`. Compter le nombre importé.
2. Lire `active_icon` : remettre l'icône par défaut (`setAlternateIconName(nil)`) car les anciennes icônes n'existent plus.
3. Supprimer toutes les notifications en attente (`removeAllPendingNotificationRequests`) puis replanifier selon le nouveau modèle si l'autorisation existe déjà.
4. Relire les achats (section 5).
5. Marquer `UserProfile.migratedFromV3 = true` et supprimer les anciennes clés `UserDefaults`, puis renommer `savedWords.json` en `savedWords.v3.backup.json` (ne pas supprimer avant la v4.1).
6. Afficher un écran unique au lieu de l'onboarding complet :
   - Titre : **Words devient Sagace.**
   - Texte : *Nouveau nom, nouvelle app : des fiches pour employer le mot juste, des révisions pour les retenir, un nouveau design clair et sombre. Vos mots aimés ont été gardés (n).* Si premium : *Votre abonnement est conservé.*
   - Boutons : **Découvrir** (mini test ONB-05 à 07 puis rythme ONB-08, puis feed) · **Passer**.
7. Événement `migration_v3_completed`.

Tests : un test unitaire par étape avec un `savedWords.json` d'exemple tiré de la v3, et un test d'interface qui lance l'app avec des `UserDefaults` v3 simulés.

## 8. App Store Connect pour la v4.0
- Version 4.0, nouvelle langue principale **Français**, anglais en langue secondaire (option A).
- Nom : **Sagace : Coach de vocabulaire**. Sous titre : **Le mot juste, chaque jour**. Texte complet dans `07_APP_STORE.md`.
- Catégorie : Éducation. Catégorie secondaire : Référence.
- Nouvelle icône, nouvelles captures (FR).
- Confidentialité : mettre à jour la fiche de collecte (analytics, plus de SDK Facebook).
- Notes pour la review : expliquer le changement de nom et de langue, et que les achats existants sont conservés.
