# 09 iPad

Interface iPad, écran par écran. Proposition validée par Hugo le 6 novembre 2026 (les quatre options recommandées, et les trois compléments : raccourcis clavier, onboarding centré, widget très grand). Base : `01_SCREENS.md` et `02_DESIGN_SYSTEM.md`, décision n° 88 de `OPEN_QUESTIONS.md`. Aujourd'hui (build 4.1 (1)), l'iPad affiche la mise en page iPhone étirée : carte de 1 100 pt de large, mot perdu au centre, barre d'actions et frise écartelées ; les sheets s'ouvrent en petite fenêtre système de 540 pt où les grilles se tassent.

## 1. Principes

1. **Même produit, même structure.** Le feed reste la racine, tout le reste s'ouvre en sheets (décision n° 4 du README). L'iPad ne gagne pas d'onglets ni de barre latérale globale : il gagne de la place pour lire.
2. **Une colonne de lecture, jamais une ligne de 1 000 pt.** Le texte courant ne dépasse pas 640 pt de large (environ 75 caractères en 17 pt). La place en plus va aux marges, à des grilles plus larges et, en paysage, à une seconde colonne.
3. **On décide sur la largeur disponible, pas sur l'appareil.** Tout est piloté par la classe de taille horizontale (`regular`) et la largeur de la fenêtre. En Split View étroit, en Slide Over ou dans une petite fenêtre de Stage Manager, l'app est en `compact` et retrouve **exactement** la mise en page iPhone. L'iPhone (portrait seul, donc toujours `compact`) ne change pas.
4. **Mêmes tokens.** Couleurs, rayons et styles de texte de `SagaceUI` ; seules deux valeurs s'ajoutent à `SagaceMetrics` (largeur de lecture, taille des sheets) et le mot du feed passe à 56 pt sur iPad (style `hero` agrandi, toujours relatif à Dynamic Type).

## 2. Écran par écran

### Feed (FEED-01 à 06)
- **Portrait** : barre du haut sur toute la largeur (couronne et série à gauche, Explorer et avatar à droite, comme les apps iPad). Carte, barre d'actions et frise centrées dans une colonne de 640 pt ; la carte garde environ 62 % de la hauteur. Le mot passe en 56 pt, la définition en 21 pt.
- **Paysage** (fenêtre d'au moins 1 000 pt) : deux colonnes. À gauche, la carte (mot, phonétique, définition), la barre d'actions et la frise. À droite, la **fiche détaillée** (DET-01) de la fiche affichée, qui suit la pagination : sens, confusions, bon usage, nuance, exemples, auteurs, synonymes, sources. Le dévoilement au toucher devient inutile (tout est à droite) ; le bouton info disparaît. *Variante possible : colonne centrée comme en portrait.*
- Gestes inchangés : glisse verticale, Je savais, À retenir, frise, toasts, suggestion de jeu. Clavier matériel : ↑ et ↓ changent de fiche.

### Fiche détaillée, partage, signalement (DET, SHR)
- Sheet flottante centrée (voir Sheets ci dessous), contenu dans la colonne de lecture.

### Explorer et bibliothèque (EXP, LIB)
- Sheet large (900 pt au plus) en **deux colonnes** (dessinées à la main plutôt qu'avec `NavigationSplitView`, qui se replie en pile dans une sheet ; `OPEN_QUESTIONS.md` n° 90) : à gauche, l'Explorer actuel (bibliothèque, familles, thèmes, recherche) en colonne de 340 pt ; à droite, la page choisie (À retenir, une famille, une collection…), et la fiche détaillée qui s'y empile au toucher d'une ligne. Ouverture sur À retenir.
- *Variante possible : Explorer comme sur iPhone, mais avec des grilles de 3 ou 4 colonnes et une navigation par pile.*

### Jeux (PRA) et révisions
- Sheet flottante centrée. Hub : grilles de jeux et défis en 3 colonnes. Session : question et réponses dans une colonne de 560 pt, centrée verticalement.
- Clavier matériel (iPad avec clavier) : 1, 2, 3 pour répondre, Entrée pour Continuer, ← et → pour Juste ou fautif.

### Stats, Journée, Profil, Réglages, Rappels, Widgets, Voix, Apparence, Icône (STA, PRO, SET…)
- Sheet flottante centrée, contenu dans la colonne de lecture, sans autre changement. La carte 2 × 2 des stats passe en 4 × 1 quand la place le permet.

### Paywall (PAY)
- Sheet flottante centrée (point d'entrée couronne, bandeaux PRO) ; dans l'onboarding, plein écran avec la colonne centrée.

### Onboarding (ONB-01 à 12) et migration (MIG-01)
- Plein écran, contenu et boutons centrés dans une colonne de 560 pt, posée au milieu de l'écran plutôt qu'en haut ; illustrations agrandies. Barre de progression dans la même colonne.

## 3. Sheets sur iPad
Une taille propre à Sagace remplace la petite fenêtre système : carte flottante centrée de 700 × 880 pt au plus (rayon 44, fond `surface`), qui rétrécit avec la fenêtre. Explorer prend 900 pt de large. En `compact`, la sheet iPhone actuelle (fraction 0,93) est conservée.

## 4. Paysage et multitâche
| Contexte | Largeur | Mise en page |
| -- | -- | -- |
| iPad portrait, plein écran | 744 à 1 032 pt | colonne centrée |
| iPad paysage, plein écran | 1 133 à 1 376 pt | feed en deux colonnes |
| Split View moitié | 507 à 688 pt (`regular` sur les grands iPad) | colonne centrée |
| Split View un tiers, Slide Over | 320 à 375 pt (`compact`) | mise en page iPhone |
| Stage Manager | toute largeur | selon la largeur, change en direct au redimensionnement |

Toutes les orientations restent permises sur iPad ; rien ne se verrouille.

### Widget (WID)
- « Fiche du jour » gagne le très grand format de l'écran d'accueil de l'iPad (`systemExtraLarge`) : la fiche à gauche, l'exemple et la phrase d'auteur à droite, boutons Suivante et À retenir.

## 5. Vérification
`Scripts/ipad_screens.sh` (simulateur « Sagace iPad UX », iPad Pro 11 pouces) capture les écrans principaux en portrait et en paysage, en clair et en sombre, en Dynamic Type standard et XXL, dans `docs/sagace/ipad/raw/`.

## 6. Hors périmètre (suites possibles)
- Captures App Store iPad 13 pouces : App Store Connect garde celles de Words tant qu'on ne les remplace pas (`OPEN_QUESTIONS.md` n° 93).
