# Choix de langue et intégration iPad

Le réglage **Profil → Réglages → Contenu → Langue de l’app** permet de choisir Automatique, Français ou English. Il change l’interface et le pack de mots immédiatement. Le changement revient au feed et conserve la progression.

## Comportement

- Automatique conserve la règle existante : appareil francophone → français ; autre langue → anglais. Une liste de langues vide utilise le français.
- Le choix explicite reste enregistré après fermeture de l’app. Il est partagé avec les widgets via l’App Group.
- Les fiches françaises et anglaises gardent leurs identifiants et leur progression. Changer de langue ne supprime aucun mot.
- Les révisions du jour, les compteurs de bibliothèque et l’historique affichent les mots du pack actif.
- Les rappels sont replanifiés et le contenu des widgets est régénéré dans la langue choisie. Les textes de partage suivent aussi ce choix.
- Les objectifs, séries, droits premium et limites gratuites restent communs aux deux langues.
- Si le nouveau pack ne peut pas être chargé, le choix et le contenu précédents restent actifs. Un message permet de réessayer.

Le pack anglais historique est conservé. Les rubriques de navigation anglaises sont dans `content/en/topics.json`. Le contenu français en cours de relecture n’est pas modifié.

## Intégration des branches

La branche `codex/app-language` part de `m8-lot-test` au commit `2410983`. Elle intègre `m10-ipad` au commit local `c37b194`, y compris le travail iPad de la PR #13. Le commit de fusion est `a39fc1b`.

Deux conflits ont été résolus : le catalogue de chaînes garde les modifications M8 et les deux libellés iPad ; le projet garde le build **4.1 (3)** pour l’app et les widgets. Le correctif StoreKit du commit `79cc19d` reste présent.

Les branches sources ne sont pas modifiées. Les données locales du pipeline et le serveur de relecture sont conservés.

## Fiches et révisions actuelles

Une fiche décrit un mot ou une expression : définition, exemples, confusions et remarque d’usage, selon les données disponibles. La carte du feed et la fiche détaillée présentent le même contenu.

| Action | Effet |
| --- | --- |
| Faire défiler sans choisir | Le mot est vu. Il pourra revenir après sept jours. Aucune révision n’est créée. |
| Je savais | Le mot sort du feed et du programme de révision. Ce choix ne prouve pas sa maîtrise. |
| À retenir | Le mot entre dans le programme de révision. La première révision est prévue le lendemain. |
| Répondre correctement en révision | La prochaine échéance s’éloigne, puis le mot devient maîtrisé. |
| Se tromper en révision | Le mot revient à la première étape, avec une révision le lendemain. |

En respectant les échéances et avec quatre bonnes réponses, un mot enregistré à J0 est révisé à **J1, J4, J11 et J32**, puis marqué maîtrisé. Chaque délai part de la réponse précédente. La journée Sagace commence à 4 h.

Les révisions sont accessibles dans Jeux, via « Révisions du jour », et dans « À retenir », via « Réviser maintenant ». Les jeux libres entraînent les compétences, mais leurs réponses ne font pas avancer automatiquement ce programme.

Le défaut relevé dans l’audit reste ouvert : « Réviser maintenant » permet de faire avancer un mot avant son échéance. Plusieurs sessions rapprochées peuvent donc le marquer maîtrisé trop tôt. Le changement de langue ne modifie pas cet algorithme.

## Vérification

Les tests métier et techniques passent : 135 SagaceCore, 30 SagaceData, 5 SagaceUI et 21 app. Les nouveaux tests vérifient le choix automatique et explicite, sa persistance, le chargement des deux packs, les traductions hors SwiftUI et le filtrage des révisions sans perte de progression.

Le test d’interface `AppLanguageTests.testSwitchLanguageAndRelaunch` couvre Français sur un appareil anglais, la réouverture, English et le retour à Automatique. Ce parcours passe sur les deux simulateurs : iPhone et iPad, avec vérification du mot affiché dans le bon pack.

StoreKit réel, migration Words v3 et fenêtres iPad redimensionnées restent à vérifier sur appareil, comme indiqué dans la revue initiale.
