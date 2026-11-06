# 02 Design system

Design system de l'app, basé sur le style de **Sudoku a Day** (vidéo du 4 novembre 2026), en mode clair et sombre, avec les mêmes couleurs. La structure produit vient de Vocabulary, l'habillage vient de Sudoku a Day : on ne copie le look de personne. Couleurs échantillonnées sur la vidéo (compression vidéo : ±3 sur chaque canal). Le mode sombre est mesuré sur une quarantaine d'images. Le clair n'apparaît que sur une image : ses valeurs mesurées sont marquées, les autres sont proposées par cohérence.

![](<design/SAD planche reference.jpg>)

## 1. Principes

1. **Le contenu est le héros.** Une grande carte centrée, un titre système très gras, presque rien autour. Le mot remplace la grille.
2. **Des couches de gris, pas des effets.** En sombre : fond, surface, surface relevée, chacune un cran plus claire, sans ombre. En clair : fond gris, carte blanche avec ombre douce.
3. **La couleur porte un sens, jamais de la déco.** Bleu = action principale et premium. Violet = soutien et membres PRO. Les 5 couleurs de difficulté = les 5 niveaux de vocabulaire.
4. **Sheets flottantes.** Détachées des bords, grands rayons, poignée en haut, et une barre d'onglets en pilules en bas pour passer d'une sous page à l'autre sans navigation.
5. **Icônes SF Symbols remplies partout**, illustrations 3D réservées à quelques moments (paywall, états vides, résultats). Détails : 08_ILLUSTRATIONS.md.

## 2. Couleurs

### Neutres
| Token | Sombre | Clair | Usage |
| -- | -- | -- | -- |
| `background` | `#181818` | `#E0E0E0` (mesuré) | Fond de l'écran principal |
| `backgroundDeep` | `#111111` | `#D2D2D2` (proposé) | Fond visible derrière une sheet |
| `surface` | `#212121` | `#FDFDFD` (mesuré) | Carte du jour, sheets, écran de jeu |
| `surfaceRaised` | `#2C2C2C` | `#F0F0F0` (proposé) | Lignes d'option, boutons ronds, blocs dans une sheet, stepper |
| `surfaceSelected` | `#333333` | `#D8D8D8` (mesuré) | Jour sélectionné dans la frise, onglet actif |
| `separator` | `#323232` | `#E3E3E3` | Lignes de grille, filets |
| `textPrimary` | `#FFFFFF` | `#111111` | Titres, mots, chiffres |
| `textSecondary` | `#8E8E8E` | `#6B6B6B` | Descriptions, libellés de métriques |
| `textGhost` | `#2A2A2A` sur `surface` | `#E8E8E8` sur `surface` | Grand libellé fantôme au dessus du titre ("Tuesday") |
| `inverseSurface` | `#E5E5E5` | `#1C1C1C` | Bouton de confirmation ("Yes, start over"), pilule Play, niveau Master |

### Accents
| Token | Hex (identique clair et sombre) | Usage |
| -- | -- | -- |
| `accentBlue` | `#285DF0` (pressé `#3653F5`) | CTA principal, bouton couronne, contour du plan sélectionné, "Apple Design Award winning team" |
| `accentPurple` | `#7129EE` | Carte de soutien, bandeau "réservé aux membres PRO" |
| `accentPurpleSoft` | `#995FF2` | Boutons posés sur le violet (Review, Share) |
| `avatar` | `#D1ADA8` | Pastille de profil avec l'initiale |

### Niveaux (difficultés de Sudoku a Day)
| Niveau Vocabulary | Couleur | Rendu sélectionné |
| -- | -- | -- |
| 1 Débutant | gris `surfaceRaised` + point `#8E8E8E` | fond `#3A3A3A`, texte blanc |
| 2 Élémentaire | violet `#A444D8` | fond violet, texte blanc |
| 3 Intermédiaire | rouge `#F83328` | fond rouge, texte blanc |
| 4 Avancé | bronze `#9B7752` | fond bronze, texte blanc |
| 5 Expert | inversé (`inverseSurface`) | fond clair en sombre, sombre en clair |

Le test de niveau de Vocabulary a exactement 5 niveaux : on reprend tels quels les 5 codes couleur de difficulté. Ils servent pour le résultat du test, les badges de niveau des mots, les filtres de stats et la difficulté des jeux.

### Seule addition : feedback de quiz
Sudoku a Day n'a pas de vert. Les jeux en ont besoin pour la bonne réponse.
| Token | Sombre | Clair |
| -- | -- | -- |
| `correct` | `#30D158` | `#28B44C` |
| `incorrect` | `#F83328` (rouge du niveau 3) | `#F83328` |

```swift
extension Color {
    /// Couleur dynamique clair / sombre sans passer par l'asset catalog.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let vBackground      = Color(light: 0xE0E0E0, dark: 0x181818)
    static let vBackgroundDeep  = Color(light: 0xD2D2D2, dark: 0x111111)
    static let vSurface         = Color(light: 0xFDFDFD, dark: 0x212121)
    static let vSurfaceRaised   = Color(light: 0xF0F0F0, dark: 0x2C2C2C)
    static let vSurfaceSelected = Color(light: 0xD8D8D8, dark: 0x333333)
    static let vTextPrimary     = Color(light: 0x111111, dark: 0xFFFFFF)
    static let vTextSecondary   = Color(light: 0x6B6B6B, dark: 0x8E8E8E)
    static let vTextGhost       = Color(light: 0xE8E8E8, dark: 0x2A2A2A)
    static let vInverse         = Color(light: 0x1C1C1C, dark: 0xE5E5E5)
    static let vBlue            = Color(hex: 0x285DF0)
    static let vPurple          = Color(hex: 0x7129EE)
    static let vPurpleSoft      = Color(hex: 0x995FF2)
    static let vCorrect         = Color(light: 0x28B44C, dark: 0x30D158)
    static let vIncorrect       = Color(hex: 0xF83328)
}

enum VocabLevel: Int, CaseIterable { case debutant = 1, elementaire, intermediaire, avance, expert
    var tint: Color {
        switch self {
        case .debutant: .vSurfaceRaised
        case .elementaire: Color(hex: 0xA444D8)
        case .intermediaire: Color(hex: 0xF83328)
        case .avance: Color(hex: 0x9B7752)
        case .expert: .vInverse
        }
    }
}
```

Apparence : réglage Automatique, Clair, Sombre dans les réglages (`preferredColorScheme`). Automatique par défaut.

## 3. Typographie

Tout en **SF Pro** (police système), comme Sudoku a Day. Tailles relevées sur la vidéo et ramenées à un écran de 393 pt.

| Style | Spec SwiftUI | Usage dans Sudoku a Day | Usage chez nous |
| -- | -- | -- | -- |
| `hero` | `.system(size: 40, weight: .heavy)` | "November 3" | Le mot sur la carte |
| `heroGhost` | `.system(size: 36, weight: .heavy)`, `textGhost` | "Tuesday" au dessus | Famille de la fiche ("Paronymes", "Nuances") |
| `title` | `.system(size: 26, weight: .bold)` | Titre du paywall, "Game Over!" | Titres de sheets, résultats |
| `sheetTitle` | `.system(size: 20, weight: .bold)` + icône | "Stats", "Streak", "Settings" | Titres de sheets centrés |
| `rowTitle` | `.system(size: 19, weight: .semibold)` | "Medium", "Yearly", "Play with friends" | Options, réponses de quiz, réglages |
| `body` | `.system(size: 15, weight: .regular)`, `textSecondary` | descriptions | Définition sous le mot (17 pt, `textPrimary`), descriptions |
| `meta` | `.system(size: 15, weight: .medium).monospacedDigit()` | "○ 0:09", "Nov 3" | Phonétique, compteurs |
| `metricValue` | `.system(size: 28, weight: .bold).monospacedDigit()` | "2", "50%" | Stats |
| `metricLabel` | `.system(size: 12, weight: .semibold)` + icône | "Started", "Won" | Libellés de stats |
| `button` | `.system(size: 20, weight: .semibold)` | "Continue", "Undo Last Move" | CTA |
| `tab` | `.system(size: 17, weight: .semibold)` | "Gameplay", "Limits" | Onglets de sheet |
| `keypad` | `.system(size: 30, weight: .regular)` | pavé numérique | Lettres du jeu "tape le mot" |

Tous les styles utilisent `relativeTo:` pour suivre Dynamic Type. Le mot du jour reste en SF Pro Heavy. **New York Bold** (la serif système d'Apple) peut devenir une option d'affichage premium, pas le défaut.

## 4. Formes et espacements

| Élément | Valeur |
| -- | -- |
| Marges de page | 24 pt |
| Carte du jour | pleine largeur moins 48 pt, rayon 36 pt continu, environ 62 % de la hauteur d'écran |
| Sheet | flottante, 12 pt des bords et du bas, rayon 44 pt, poignée 36 × 5 pt `separator` |
| Ligne d'option | hauteur 56 pt (dépliée 96 pt avec description), rayon 18 pt, fond `surfaceRaised` |
| Bouton principal | capsule pleine largeur, hauteur 56 pt, `accentBlue`, texte blanc |
| Bouton secondaire | même forme, `surfaceRaised`, texte `textPrimary` |
| Bouton de confirmation | capsule `inverseSurface` avec icône check, à côté d'un bouton rond retour |
| Bouton rond | 44 à 52 pt, `surfaceRaised` |
| Chip | capsule 36 pt, actif `inverseSurface`, inactif `surfaceRaised` |
| Grille 2 × 2 de métriques | carte `surfaceRaised` rayon 24 pt, gouttière 16 pt |
| Ombres | aucune en sombre. En clair : carte du jour `y 10, blur 30, noir 8 %` |

## 5. Composants, et ce qu'ils deviennent chez nous

| Composant Sudoku a Day | Notre usage | Écrans Vocabulary concernés |
| -- | -- | -- |
| **Carte du jour** (libellé fantôme, titre héros, ligne meta, aperçu, pilule Play) | `FicheCard` : famille en fantôme, mot en héros, nature, phonétique et haut parleur en meta, définition, confusion, usage, phrase d'auteur. Pilule "S'entraîner" en bas de carte | Feed |
| **Barre du haut** : couronne bleue ronde, chip laurier + compteur, avatar rose | Couronne (paywall), chip streak, avatar (profil). On ajoute un bouton rond Topics | Feed |
| **Frise des jours** en bas (jour, chiffre, anneau de progression, "Next in 6 hrs") | **Objectif du jour** : 7 jours, anneau = fiches triées / objectif (3, 5 ou 10), le jour actif en `surfaceSelected` | Feed, remplace la pilule "0/5" et le toast streak |
| Pavé et boutons ronds d'action du jeu | `ActionBar` : info, partager, Je savais (`checkmark`), À retenir (`bookmark`) en boutons ronds `surfaceRaised`, symbole rempli quand actif | Feed |
| **Sheet de profil** : carte violette de soutien, carte des avantages + Sign in with Apple, liste Settings / Feedback / About | Profil : carte violette (noter, partager), carte premium, puis lignes Thèmes, Rappels, Voix, Widgets, Icône, Bibliothèque, Réglages | Profil |
| **Paywall** : 3D en haut, ligne tag bleue, titre, histoire des fondateurs, 2 plans avec contour bleu, preuve sociale entre lauriers, CTA bleu, partage familial | Paywall avec notre histoire, plans annuel et à vie, frise d'essai si essai, rappel activé par défaut | Paywall |
| **Sélecteur de difficulté** : lignes colorées, la sélectionnée se déplie avec description et check, barre retour + confirmer | Choix du niveau (onboarding, réglages), choix des topics, niveau des jeux | Onboarding, Practice |
| **Game Over** sheet : icône, titre, sous titre, CTA bleu, bouton secondaire | Feedback de réponse, fin de Rush ("Plus de vies"), fin de session | Practice |
| **Stats** : chips de filtre (All, Easy, Medium…), carte 2 × 2, pagination par points, onglets Streak / Achievements / Stats | Stats : filtres par niveau, Lus / Sauvegardés / Maîtrisés / Sessions, série, succès | Stats |
| **Streak** : calendrier du mois en cercles, Current / Perfect / Longest | Calendrier d'activité, série actuelle et record | Stats |
| **Réglages en onglets** (Gameplay, Assistance, Limits, Effects, Notifications), lignes icône + titre + description + toggle, steppers − n + | Réglages : Contenu, Rappels, Voix, Effets, Notifications | Réglages, Rappels |
| **Bandeau PRO violet** "These settings are for PRO users" + Unlock | Verrou de toute section premium dans une sheet | Partout où Vocabulary mettait un cadenas |
| **Sélecteur d'effets** en segments ronds (muet, effets, musique) | Sons : muet, effets, effets + ambiance | Réglages |
| Toggles | `.tint(.vTextPrimary)` : piste blanche en sombre, noire en clair | Réglages |

## 6. Composants Practice (à dessiner dans ce langage)

| Composant | Spec |
| -- | -- |
| `QuestionCard` | Carte `surface` rayon 36, prompt en `rowTitle` ou mot en `hero` 34, libellé du jeu en fantôme au dessus |
| `AnswerRow` | Ligne d'option 56 pt. Réponse juste : fond `correct`, check blanc. Mauvais choix : fond `incorrect`, croix. Les autres passent à 40 % d'opacité |
| `ProgressDots` | Segments fins en haut de sheet, comme la pagination des stats |
| `TimerBar` + vies | Barre capsule `surfaceRaised` qui se vide en `accentBlue`, 3 cœurs SF remplis |
| `ScoreBlock` | Score en `metricValue` géant, sous titre "7 sur 10", ligne de 5 cercles d'activité |
| `LevelResult` | Les 5 lignes de niveau, celle de l'utilisateur dépliée et colorée, "3 points avant Avancé" |

## 7. Mouvement

| Moment | Animation |
| -- | -- |
| Mot suivant | Pagination verticale, la carte suivante monte avec `.spring(duration: 0.35)` |
| Option sélectionnée | La ligne se déplie et prend sa couleur, `.spring(duration: 0.3, bounce: 0.2)` |
| Sheets | Présentation flottante, fond qui recule en `backgroundDeep` |
| Frise des jours | L'anneau du jour se remplit à chaque sauvegarde |
| Réponse | Couleur immédiate, sheet de feedback ou passage auto après 0,8 s |
| Bouton pressé | Échelle 0,97, retour en ressort |
| Annulation par secousse | Sudoku a Day annule avec "Shake to undo" : reprenable pour annuler un like ou une suppression |

## 8. Haptiques et sons

| Interaction | Haptique |
| -- | -- |
| Changement de mot | `selectionChanged` |
| Je savais, À retenir | `.light` ; anneau du jour complété : `.success` |
| Sélection d'une option | `.soft` |
| Bonne réponse | `.success` + son court |
| Mauvaise réponse | `.error` |
| Perte d'une vie | `.heavy` |
| Fin de session, nouveau niveau | `.success` puis `.light` |

Comme Sudoku a Day : un réglage "Retour haptique" et un réglage "Animations", tous deux activés par défaut.

## 9. Accessibilité
Dynamic Type sur tous les styles. Contraste vérifié sur les couleurs de niveau avec du texte blanc : le bronze `#9B7752` est le plus juste, prévoir le texte en gras dessus. Libellés VoiceOver sur les 4 actions du feed et sur chaque réponse.

