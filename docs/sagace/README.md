# Sagace : dossier de build

Mise à jour v4.0 de l'app Words, reconstruite sous le nom **Sagace : Coach de vocabulaire**, sous titre **Le mot juste, chaque jour**.

## Ordre de lecture
| # | Document | Contenu |
| -- | -- | -- |
| 0 | `00_PRODUCT.md` | Vision, positionnement, cible, boucle quotidienne, périmètre v4, monétisation |
| 1 | `01_SCREENS.md` | Tous les écrans de Sagace avec contenu, actions, états, textes français |
| 2 | `02_DESIGN_SYSTEM.md` | Style Sudoku a Day clair et sombre : tokens, typo, composants. Images dans `design/` |
| 3 | `03_ARCHITECTURE.md` | Structure du projet, modèles, services, navigation, règles chiffrées, widgets, analytics |
| 4 | `04_MIGRATION.md` | Ce qui existe dans Words v3, ce qu'on garde, achats, données, nettoyage |
| 5 | `05_CONTENT.md` | Format des fiches, sources gratuites, pipeline de production, prompts, contrôles |
| 6 | `06_BUILD_PLAN.md` | Jalons ordonnés avec tâches et critères d'acceptation |
| 7 | `07_APP_STORE.md` | Métadonnées App Store en français, captures, notes pour la review |
| 8 | `08_ILLUSTRATIONS.md` | Brief et prompt Astra pour les 53 illustrations |
| 9 | `09_IPAD.md` | Interface iPad : feed en une ou deux colonnes, Explorer en deux colonnes, sheets, multitâche |

Fichiers de données :
- `content/schema/fiche.schema.json` : schéma JSON d'une fiche (source de vérité du format).
- `content/fr/seed_fiches.json` : 25 fiches modèles (statut draft, à valider par Hugo), à utiliser comme données de développement et comme exemples pour le pipeline.
- `content/fr/topics.json` : familles et thèmes.

## Décisions déjà prises (ne pas rediscuter sans Hugo)
1. Même app, même bundle, même équipe : c'est une **mise à jour** de Words, pas une nouvelle app.
2. **Français d'abord**, anglais plus tard (pack de contenu séparé, interface via String Catalog).
3. **Positionnement : la précision au quotidien**, pas les mots rares.
4. Structure produit héritée de Vocabulary (feed vertical comme racine, tout le reste en sheets), **améliorée** : tri "Je savais / À retenir", révision espacée dans le feed, mot maîtrisé, test de précision, rythme choisi.
5. Design : style **Sudoku a Day**, clair et sombre, mêmes couleurs.
6. Contenu : **sources gratuites uniquement**, aucun relecteur payé. Contrôle par sources croisées, seconde passe IA, échantillon relu par Hugo, bêta testeurs.
7. Illustrations : générées avec ChatGPT et Astra (prompt dans `08_ILLUSTRATIONS.md`).
8. Essai gratuit avec **rappel de fin d'essai activé par défaut**.
