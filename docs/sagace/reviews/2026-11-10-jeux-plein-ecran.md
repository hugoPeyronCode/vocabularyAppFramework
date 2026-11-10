# Jeux en plein écran et chargement

Les sessions, révisions, tests de précision, défis et mots croisés s’ouvrent en plein écran sur iPhone et iPad. La page de choix des jeux conserve sa présentation en sheet. Le nom du jeu apparaît en petit dans l’en-tête ; il ne figure plus au-dessus de la phrase dans la carte question.

La roue de chargement apparaît pendant la préparation. La croix reste disponible. Les questions et réponses gardent une colonne de lecture limitée à 560 points sur iPad.

## Réduction du travail

La fabrique de questions utilisait une recherche répétée dans un tableau pour séparer les quiz écrits des questions à générer. Elle utilise maintenant un ensemble d’identifiants. Les formes comparables et les mots proches des distracteurs sont calculés une fois. Le calcul de distance réutilise ses deux tableaux de travail.

Un acteur `QuestionPreparation` construit et réutilise la fabrique pour le pack actif, hors du thread d’affichage. Les défis préparent dix questions au plus par lot, au lieu d’une file couvrant tout le pack anglais. Un mot déjà proposé est exclu des lots suivants jusqu’à épuisement des fiches utilisables.

Les chronomètres sont arrêtés pendant une préparation. Une session n’est créée qu’une fois ses questions disponibles. Fermer pendant l’attente empêche la publication du résultat tardif. Les mots croisés sont aussi préparés hors du thread d’affichage.

## Mesure locale

Mesure en compilation Release sur le Mac, avec le pack anglais complet, dix questions et la graine 42. Le temps de génération exclut la construction initiale de la fabrique. Ce ne sont pas des temps de chargement mesurés sur iPhone.

| Opération | Avant | Après |
| --- | --- | --- |
| Sens | 0,966 s | 0,029 s |
| Le mot juste | 2,172 s | 0,518 s |
| Devine le mot | 2,154 s | 0,494 s |
| Construction initiale de la fabrique | 0,480 s | 0,598 s |

La construction initiale est légèrement plus coûteuse, mais elle est désormais réutilisée entre les parties et ne bloque plus l’affichage.

## Vérifications

- 195 tests métier et techniques passent : 135 SagaceCore, 30 SagaceData, 5 SagaceUI et 25 app.
- Les tests couvrent l’annulation pendant le chargement, l’absence de partie créée trop tôt, le démarrage du chrono, la taille des lots et l’absence de répétition entre deux lots.
- Les quatre essais UI passent : deux parcours exécutés sur iPhone et iPad. Ils couvrent l’ouverture depuis Jeux, la position de l’en-tête, une réponse, la fermeture, le défi Rush et le mot croisé.
- Les captures du « Mot juste » ont été vérifiées sur les deux formats.
- La version destinée à l’iPhone compile avec la signature de développement.

Les mesures de performance portent sur la préparation. Le temps total inclut aussi l’ouverture de la modale et dépend de l’appareil et du mode de compilation.
