# 08 Illustrations

Brief pour produire les illustrations avec ChatGPT (génération d'images) et Astra. Elles doivent tenir sur fond clair comme sur fond sombre et rester dans l'esprit de Sudoku a Day : peu d'images, mais de beaux objets 3D aux moments clés. Design system : 02_DESIGN_SYSTEM.md.

## 1. Direction

- **Objets 3D mats, style "clay" doux**, un seul objet par image, vue de trois quarts légèrement plongeante, lumière studio douce venant d'en haut à gauche.
- **Palette** : base gris clair chaud et blanc cassé, détails gris anthracite. **Une seule couleur d'accent par image**, prise dans le design system : bleu `#285DF0`, violet `#7129EE`, rouge `#F83328`, bronze `#9B7752`, orchidée `#A444D8`.
- **Fond transparent**, sans sol ni ombre portée détachée. Une légère ombre de contact sous l'objet est acceptée.
- **Aucun texte, aucune lettre lisible** (sauf les tuiles de lettres du splash), aucun personnage reconnaissable, aucun logo.
- **Lisibilité** : l'objet doit rester reconnaissable à 64 pt et ressortir sur `#181818` comme sur `#FDFDFD`. Un fin liseré clair sur les bords sombres de l'objet aide en mode sombre.

## 2. Prompt maître

À coller en tête de chaque génération, puis ajouter la ligne "Subject" de la liste.

```
Soft 3D clay render of a single object, matte material, rounded edges, gentle studio lighting from top left, subtle contact shadow only, three-quarter view slightly from above, centered with generous padding, transparent background, no text, no letters, no logo, no people.
Palette: warm light gray and off-white base, charcoal details, one accent color only: {ACCENT}.
Minimal, premium, calm, consistent icon family for an iOS app with dark and light mode. 1024x1024 PNG with alpha.
Subject: {SUBJECT}
```

Pour garder une famille cohérente :
1. Générer d'abord 4 objets "étalons" (livre ouvert, cible, cloche, sablier) et en choisir un comme référence.
2. Joindre cette référence à chaque nouvelle demande : "Match exactly the style, lighting and materials of the attached reference."
3. Générer par lots de 4 sujets, rejeter tout ce qui a des reflets brillants, des dégradés de couleur ou un fond.

## 3. Liste des visuels (V1 française)

### Onboarding et paywall (accent bleu sauf mention)
| Fichier | Subject |
| -- | -- |
| `ill_onb_splash` | a small stack of square letter tiles, the top tile showing a single serif letter "é" |
| `ill_onb_tailor` | three stacked rounded sliders like an equalizer |
| `ill_onb_goals` | a round archery target with one arrow in the center |
| `ill_onb_notifications` | a classic rounded bell with a small notification dot |
| `ill_onb_widget` | a phone lying flat showing a single blank rounded card on its screen |
| `ill_onb_test` | a graduation cap resting on two closed books |
| `ill_paywall` (violet) | an open hardcover book with a few small floating sparkles above the pages |
| `ill_trial` | an hourglass with a small check badge |

### Practice (une couleur par mode)
| Fichier | Accent | Subject |
| -- | -- | -- |
| `ill_game_guess` | bleu | a magnifying glass over a blank card |
| `ill_game_meaning` | violet | two speech bubbles overlapping |
| `ill_game_synonyms` | orchidée | two interlocked rings |
| `ill_game_gap` | bronze | a jigsaw puzzle piece fitting into a gap |
| `ill_game_shuffle` | bleu | two dice mid-roll |
| `ill_challenge_rush` | rouge | a lightning bolt |
| `ill_challenge_perfection` | violet | a faceted diamond |
| `ill_challenge_sprint` | bleu | a stopwatch |
| `ill_result_good` | bronze | a small trophy cup |
| `ill_result_retry` | rouge | a closed book with a bookmark ribbon hanging out |
| `ill_streak` | rouge | a stylized flame |

### États vides
| Fichier | Subject |
| -- | -- |
| `ill_empty_collections` | an empty open folder |
| `ill_empty_favorites` | a puffy heart |
| `ill_empty_ownwords` | a fountain pen lying on a blank card |
| `ill_empty_history` | a round wall clock |

### Topics, en français (accent selon la famille)
Familles : **Nous mêmes** (violet), **Société et travail** (bleu), **Savoirs** (bronze), **Précision de la langue** (orchidée : paronymes, impropriétés, passe-partout, nuances, pléonasmes, anglicismes, expressions, registres), **Examens** (rouge).

| Topic | Subject |
| -- | -- |
| Émotions | two round pebbles, one carved with a simple smile line, one with a frown line |
| Corps humain | a simple anatomical heart |
| Caractère et portraits | a hand mirror |
| Relations | two cups touching |
| Société | a small town hall building |
| Travail et entreprise | a briefcase |
| Politique | a ballot box |
| Droit | a balance scale |
| Économie | a small stack of coins |
| Sciences | a laboratory flask |
| Médecine | a stethoscope |
| Technologie | a laptop |
| Nature | a single leaf on a small branch |
| Animaux | a fox sitting |
| Cuisine | a cooking pot with steam |
| Voyage | a vintage suitcase |
| Arts | a painter palette with a brush |
| Musique | a violin |
| Littérature | a quill in an inkwell |
| Histoire | a classical column |
| Philosophie | an owl perched on a closed book |
| Paronymes | two nearly identical keys side by side, one slightly different |
| Pléonasmes | two identical rubber stamps side by side |
| Expressions | a speech bubble containing three dots |
| Verbes passe-partout | a skeleton key |
| Nuances | a fanned color swatch in shades of one color |
| Impropriétés | a pencil with its eraser end down |
| Anglicismes | two teacups side by side, one plain, one with a thin stripe |
| Registres | a bow tie |
| Bac et concours | a pencil and a sheet with checkboxes |

## 4. Export et intégration
- Génération en 1024 × 1024 PNG transparent, détourage vérifié (pas de halo blanc, à tester sur `#181818`).
- Réduction en 3 tailles pour l'asset catalog : 120, 240, 360 px (@1x, @2x, @3x d'un visuel affiché à 120 pt).
- Nom des fichiers : préfixe `ill_`, minuscules, sans accent.
- Toutes les images dans `SagaceUI/Resources/Illustrations.xcassets`, appelées par un enum `Illustration` pour éviter les chaînes en dur.
- Budget : 53 visuels, compter 2 à 3 générations par visuel retenu.

## 5. Prompt Astra complet (copier coller)

```
Generate a cohesive set of 53 illustrations for a French vocabulary iOS app that supports dark and light mode. One image per item, named exactly as listed.

STYLE, identical for every image:
- Soft 3D clay render of ONE single object, matte material, rounded edges, no glossy reflections, no gradients in the background.
- Gentle studio light from top left, subtle contact shadow under the object only.
- Three-quarter view slightly from above, object centered with generous padding (object fills about 70% of the frame).
- Palette: warm light gray and off-white base, charcoal details, plus ONE accent color per image as specified.
- Transparent background, 1024x1024 PNG with alpha.
- No text, no letters, no numbers, no logos, no flags, no people, no human faces. The only allowed letter is in item 1.
- Must read clearly at 64 px on both a near-black #181818 and a white #FDFDFD background: add a faint light rim on dark edges.
- Same lighting, materials, camera angle and level of detail across the whole set, like one icon family.

ACCENT COLORS: BLUE #285DF0, PURPLE #7129EE, ORCHID #A444D8, RED #F83328, BRONZE #9B7752.

ONBOARDING AND PAYWALL
1. ill_onb_splash (BLUE): a small stack of square letter tiles, the top tile showing one serif letter "é"
2. ill_onb_tailor (BLUE): three stacked rounded sliders, like an equalizer
3. ill_onb_goals (BLUE): a round archery target with one arrow in the center
4. ill_onb_notifications (BLUE): a classic rounded bell with a small notification dot
5. ill_onb_widget (BLUE): a phone lying flat showing one blank rounded card on its screen
6. ill_onb_test (BLUE): a graduation cap resting on two closed books
7. ill_paywall (PURPLE): an open hardcover book with a few small floating sparkles above the pages
8. ill_trial (BLUE): an hourglass with a small check badge

PRACTICE
9. ill_game_guess (BLUE): a magnifying glass over a blank card
10. ill_game_meaning (PURPLE): two overlapping speech bubbles
11. ill_game_synonyms (ORCHID): two interlocked rings
12. ill_game_gap (BRONZE): a jigsaw puzzle piece fitting into a gap
13. ill_game_shuffle (BLUE): two dice mid-roll
14. ill_challenge_rush (RED): a lightning bolt
15. ill_challenge_perfection (PURPLE): a faceted diamond
16. ill_challenge_sprint (BLUE): a stopwatch
17. ill_result_good (BRONZE): a small trophy cup
18. ill_result_retry (RED): a closed book with a bookmark ribbon hanging out
19. ill_streak (RED): a stylized flame

EMPTY STATES (BLUE)
20. ill_empty_collections: an empty open folder
21. ill_empty_favorites: a puffy heart
22. ill_empty_ownwords: a fountain pen lying on a blank card
23. ill_empty_history: a round wall clock

TOPICS
24. ill_topic_emotions (PURPLE): two round pebbles, one carved with a simple smile line, one with a frown line
25. ill_topic_corps (PURPLE): a simple anatomical heart
26. ill_topic_caractere (PURPLE): a hand mirror
27. ill_topic_relations (PURPLE): two cups touching
28. ill_topic_societe (BLUE): a small town hall building
29. ill_topic_travail (BLUE): a briefcase
30. ill_topic_politique (BLUE): a ballot box
31. ill_topic_droit (BLUE): a balance scale
32. ill_topic_economie (BLUE): a small stack of coins
33. ill_topic_sciences (BRONZE): a laboratory flask
34. ill_topic_medecine (BRONZE): a stethoscope
35. ill_topic_technologie (BRONZE): a laptop
36. ill_topic_nature (BRONZE): a single leaf on a small branch
37. ill_topic_animaux (BRONZE): a sitting fox
38. ill_topic_cuisine (BRONZE): a cooking pot with a little steam
39. ill_topic_voyage (BRONZE): a vintage suitcase
40. ill_topic_arts (BRONZE): a painter palette with a brush
41. ill_topic_musique (BRONZE): a violin
42. ill_topic_litterature (BRONZE): a quill in an inkwell
43. ill_topic_histoire (BRONZE): a classical column
44. ill_topic_philosophie (BRONZE): an owl perched on a closed book
45. ill_topic_paronymes (ORCHID): two nearly identical keys side by side, one slightly different
46. ill_topic_pleonasmes (ORCHID): two identical rubber stamps side by side
47. ill_topic_expressions (ORCHID): a speech bubble containing three dots
48. ill_topic_passe_partout (ORCHID): a skeleton key
49. ill_topic_nuances (ORCHID): a fanned color swatch in shades of one color
50. ill_topic_improprietes (ORCHID): a pencil with its eraser end down
51. ill_topic_anglicismes (ORCHID): two teacups side by side, one plain, one with a thin stripe
52. ill_topic_registres (ORCHID): a bow tie
53. ill_topic_examens (RED): a pencil on a sheet with checkboxes

Start with items 7, 3, 4 and 8 as the reference set. Once approved, match their style, lighting and materials exactly for all other items.
```

