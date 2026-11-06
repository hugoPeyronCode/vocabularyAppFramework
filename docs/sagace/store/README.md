# Fiche App Store (v4.0)

Textes prêts à coller dans App Store Connect, en français (langue principale) et en anglais. Un fichier par champ, aux longueurs limites d'Apple : nom et sous titre 30 caractères, mots clés 100, texte promotionnel 170.

| Fichier | Champ App Store Connect |
| -- | -- |
| `name.txt` | Nom |
| `subtitle.txt` | Sous titre |
| `keywords.txt` | Mots clés |
| `promotional_text.txt` | Texte promotionnel |
| `description.txt` | Description |
| `release_notes.txt` | Nouveautés de cette version |
| `review_notes.txt` | Informations pour la vérification de l'app › Notes |
| `confidentialite.md`, `privacy.md` | Politique de confidentialité, à publier à une URL (`OPEN_QUESTIONS.md` n° 10) |

Les `{…}` sont à remplacer : URL des conditions et de la confidentialité, date, adresse, contact.

## Étiquette de confidentialité
« Données non collectées » : la v4.0 n'envoie rien (statistiques en console seulement, `OPEN_QUESTIONS.md` n° 63). Le manifeste `App/Resources/PrivacyInfo.xcprivacy` le déclare aussi : pas de pistage, aucune donnée collectée, `UserDefaults` pour l'app elle même (raison CA92.1). À revoir si un outil d'analytics est branché.

## Captures
`Scripts/screenshots.sh` produit les captures 6,9 pouces de `07_APP_STORE.md`, en clair et en sombre alternés, dans `docs/sagace/store/screenshots/`. La capture 5 (widgets sur l'écran d'accueil) se fait à la main : iOS ne permet pas de poser un widget depuis un test.
