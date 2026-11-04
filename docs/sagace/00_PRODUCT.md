# 00 Produit

## One liner
**Sagace aide à employer le mot juste au quotidien** : une fiche par écran, quelques minutes par jour, pour ne plus confondre éminent et imminent, ne plus "pallier à", remplacer "faire" par le verbe précis, et le retenir pour de bon.

## Pour qui
- Adultes francophones, actifs ou étudiants, qui écrivent et parlent tous les jours (mails, réunions, dossiers, examens) et veulent être plus précis sans retourner à l'école.
- Persona de référence : **Claire, 34 ans**, cheffe de projet. Elle écrit 40 mails par jour, elle sait qu'elle dit "au final" et "impacter", elle a peur de passer pour approximative en réunion. Elle a 3 minutes dans le métro.
- Ton : calme, précis, jamais donneur de leçons. On explique l'usage, on distingue "fautif", "critiqué" et "toléré", on respecte l'intelligence de l'utilisateur.

## Positionnement
- **Ce n'est pas** une app de mots rares (Vocabulary) ni un cours d'orthographe (Projet Voltaire).
- **C'est** un coach de précision : des mots courants, bien employés. Chaque fiche montre un piège réel et la bonne façon de dire.
- Différenciants :
  1. **Une phrase d'auteur** du domaine public (Hugo, Balzac, Flaubert, Proust…) sur chaque fiche : l'emploi réel, juste par construction.
  2. **Sources affichées** sur chaque fiche (Wiktionnaire, Littré, Lexique) : la confiance par la transparence.
  3. **On retient vraiment** : tri "Je savais / À retenir", révisions espacées dans le feed, compteur de mots maîtrisés.
  4. **Beau et calme** : style Sudoku a Day, clair et sombre.

## Les 8 familles de fiches
| Famille | Ce que la fiche apprend | Exemple |
| -- | -- | -- |
| Paronymes | Distinguer deux mots proches | éminent / imminent |
| Impropriétés | Corriger un emploi courant mais fautif ou critiqué | pallier un manque, pas "à" |
| Verbes passe partout | Remplacer faire, mettre, dire, avoir, gérer | faire un discours → prononcer |
| Nuances | Choisir entre deux voisins | éviter / empêcher |
| Pléonasmes | Supprimer la redite | prévoir à l'avance |
| Anglicismes et faux amis | Retrouver le mot français juste | réaliser au sens de "se rendre compte" |
| Mots courants mal compris | Le sens exact d'un mot qu'on croit connaître | une alternative = un choix entre deux possibilités |
| Expressions | Sens et bon emploi d'une locution | au temps pour moi |

## La boucle quotidienne
1. Un widget et une notification par jour montrent une fiche.
2. L'utilisateur ouvre l'app : le feed propose les fiches du jour (3, 5 ou 10 selon son rythme).
3. Sur chaque fiche il trie : **Je savais** (la fiche ne revient plus) ou **À retenir** (elle entre en révision).
4. Toutes les 5 fiches, une **carte de révision** (mini quiz) reprend une fiche "À retenir" arrivée à échéance.
5. L'anneau du jour se remplit, la série continue. Un jeu de 2 minutes est proposé en fin de lot.
6. Une fiche réussie en révision à 21 jours devient **maîtrisée**. Le compteur de mots maîtrisés ne fait que monter.

Moment clé qui fait revenir : **l'anneau du jour et le compteur de mots maîtrisés**.

## Périmètre v4.0
**Dedans**
- Onboarding court avec mini test de précision avant le paywall.
- Feed de fiches, fiche détaillée, partage en image.
- Tri Je savais / À retenir, révisions espacées, mots maîtrisés.
- Explorer : familles, thèmes, recherche, bibliothèque (À retenir, Maîtrisés, Collections, Mes mots, Historique).
- Practice : 6 jeux, 3 défis, test de précision.
- Stats et série.
- Widgets (fiche du jour, révision interactive, série), écran verrouillé.
- Rappels, voix françaises, apparence clair, sombre, automatique, icônes alternatives.
- Abonnement annuel avec essai et achat à vie, achats existants préservés.
- 1 000 fiches françaises au lancement.

**Dehors (plus tard)**
- Version anglaise (v4.x), compte et synchronisation, Apple Watch, Live Activities, social, puzzle du jour commun, iPad.

## Monétisation
- Gratuit utile : feed complet, tri, révisions (dans la limite du rythme choisi), fiche détaillée avec sources, 1 session de jeu par jour, le test, 1 widget, 1 rappel.
- Premium : jeux et défis illimités, tous les filtres de familles et thèmes, rythme 10 fiches et lots supplémentaires, stats complètes, widgets multiples et configurables, rappels multiples, toutes les voix, collections illimitées.
- Prix de départ (à tester) : **29,99 € par an avec 3 jours d'essai**, **49,99 € à vie**. Rappel de fin d'essai activé par défaut.
- Produits StoreKit : réutiliser les identifiants existants (voir `04_MIGRATION.md`).

## Indicateurs de réussite
| Indicateur | Cible v4 |
| -- | -- |
| Onboarding terminé | 70 % des installs |
| Widget ajouté au J1 | 25 % |
| Rétention J7 | 20 % |
| Rétention J30 | 8 % (Vocabulary : 4,3 %) |
| Essai démarré | 15 % des installs |
| Essai converti | 40 % |
| Fiches maîtrisées par utilisateur actif à J30 | 20 |
