# Revue de Sagace avant le lancement français

Revue du 10 novembre 2026. Sagace possède une base technique structurée et une promesse précise : aider les francophones à employer les mots courants avec justesse. La priorité est de rendre cette promesse fiable et visible dès la première fiche.

Plusieurs défauts touchent directement cette confiance : des tournures correctes sont jugées fautives, la maîtrise peut être obtenue sans espacement, et les signalements ne sont pas transmis. L'expérience demande aussi trop de configuration avant de laisser explorer.

## Périmètre retenu

- Adultes francophones, marché français en premier.
- Exploration libre : l'utilisateur choisit les mots, les jeux et son rythme. Aucun parcours d'apprentissage obligatoire.
- iPhone et expérience iPad dédiée dès la première version française.
- Pack anglais conservé pour l'avenir et continuité des anciens utilisateurs Words à traiter explicitement.
- Simplicité évaluée du point de vue de l'utilisateur. Le coût de développement ne justifie pas un parcours inutilement compliqué.
- Audit et propositions uniquement. Aucun correctif appliqué à l'application, aucune fusion, aucun envoi de message ni publication.

La revue porte sur les sources de l'application, SagaceCore, SagaceData, les composants partagés, les widgets, la production de contenu et les documents produit. Elle inclut la branche iPad et onze captures existantes de ses principaux écrans. Elle ne constitue pas une validation de chaque fiche ni une recette complète sur appareils physiques.

L'application a été examinée sur `m8-lot-test`, initialement à `79cc19d`, puis à `4249d4d` après un commit concurrent du pipeline. La branche iPad locale est à `c37b194`. La [PR iPad numéro 13](https://github.com/hugoPeyronCode/vocabularyAppFramework/pull/13) est ouverte et non fusionnée au moment de la revue. Les changements existants de catalogues de traduction n'ont pas fait l'objet d'une correction dans cet audit.

## Fonctionnement actuel

L'application charge un pack de fiches depuis son bundle. Le moteur choisit les fiches selon le niveau, les objectifs et les familles suivies. Le feed affiche un mot et sa définition, puis révèle des détails au toucher.

« Je savais » retire la fiche des prochaines sélections. « À retenir » la place dans un système de révisions à quatre étapes. Les révisions se trouvent dans Jeux et dans la bibliothèque. Les jeux libres produisent des statistiques ; seuls les parcours de révision font progresser les étapes de mémorisation.

La progression et la bibliothèque sont stockées localement avec SwiftData. Les widgets échangent des fichiers avec l'application. StoreKit détermine les droits Premium. Les événements d'usage sont écrits dans la console, sans service d'analyse distant.

Le pack français contient 176 fiches : 168 `autoChecked` et 8 `humanChecked`. Les huit familles sont présentes. Le pack anglais contient 24 909 fiches et représente environ 24 Mo de JSON. Il est actuellement inclus dans l'application.

## Points solides à conserver

- Le sujet est concret : comprendre une nuance et mieux employer un mot du quotidien.
- La séparation entre contenu, logique métier, stockage et interface permet de corriger les règles sans refaire toute l'application.
- Le fonctionnement local convient à une pratique courte, sans compte et sans réseau.
- La fiche détaillée donne des exemples, des distinctions et des sources consultables.
- Les explications après une réponse restent à l'écran jusqu'au choix « Continuer ».
- Les révisions sont accessibles sans abonnement. Les identifiants des achats Words restent reconnus.
- Le travail iPad apporte des colonnes de lecture, un détail visible à côté du feed et des commandes au clavier.

Ces qualités donnent une base utile. Les tests vérifient de nombreuses règles ; les défauts ci-dessous montrent surtout des scénarios manquants et des écarts entre les règles et la promesse.

## Failles prioritaires

P1 signifie « à traiter avant la publication de la version française visée ». P2 signifie « à corriger dans la préparation de cette version, après les P1 ». La priorité tient compte de la promesse pédagogique et de la conservation des données.

### F1 Des expressions correctes deviennent fautives

**P1 — Reproduit avec le contenu publié.**

Le générateur de « Juste ou fautif » traite systématiquement le champ `usage.avoid` comme une faute. Il ne tient pas compte du verdict `tolere`.

Exemple reproduit : « Faire de la natation. » attend la réponse « Fautif ». L'explication de la même question commence pourtant par « “Faire de la natation” est correct ». Le pack comporte 36 fiches avec un usage toléré et sans question explicite de ce jeu ; elles peuvent passer par cette génération.

Le problème dépasse les tournures « critiquées » déjà identifiées. Il pénalise un utilisateur qui connaît le bon usage et rend les scores moins fiables.

**Correction attendue :** réserver le jugement binaire aux erreurs non ambiguës. Pour les registres et les formulations plus précises, demander quel choix convient au contexte. Conserver la distinction entre correct, familier, critiqué, régional et fautif jusque dans les réponses générées. Les croix rouges sur les usages tolérés doivent aussi être revues.

**Vérification attendue :** une expression explicitement correcte dans sa fiche ne peut jamais recevoir le verdict « Fautif » sans condition de contexte.

Sources : [génération du verdict](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceCore/Sources/SagaceCore/Practice/QuestionFactory.swift:240>), [affichage du bon usage](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Fiche/FicheDetailView.swift>).

### F2 La maîtrise peut être obtenue en quelques instants

**P1 — Reproduit au niveau du stockage et relié à un parcours accessible.**

« À retenir → Réviser maintenant » envoie toutes les fiches en apprentissage, y compris celles prévues pour demain. Chaque réponse correcte fait avancer l'étape de révision. Le stockage ne vérifie pas que l'échéance est atteinte.

Avec une fiche nouvellement enregistrée, quatre réponses correctes au même instant produisent successivement les étapes 2, 3, 4, puis « maîtrisée ». Le bouton « Rejouer » permet de relancer les mêmes identifiants de fiches.

**Correction attendue :** permettre de s'entraîner librement à tout moment, mais faire avancer la mémorisation espacée uniquement lors d'une révision éligible. La protection doit être dans la règle métier, pour couvrir l'application et les widgets.

**Vérification attendue :** répéter dix fois un exercice aujourd'hui n'accorde pas une maîtrise censée dépendre de plusieurs jours.

Sources : [entrée Réviser maintenant](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Explore/LibraryViews.swift:122>), [application de la réponse](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Practice/PracticeSessionViewModel.swift:149>), [progression sans contrôle de date](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/ProgressStore.swift:144>).

### F3 Une panne de stockage peut devenir une perte silencieuse

**P1 — Risque établi par le code ; panne réelle non provoquée.**

Si l'ouverture de la base échoue, l'application utilise une base en mémoire et continue normalement. L'utilisateur peut alors croire que sa progression est conservée. Cette nouvelle progression disparaît à l'arrêt du processus.

De plus, les erreurs de sauvegarde sont ignorées. La migration supprime les anciennes clés après une sauvegarde dont elle ne connaît pas le succès. Ces mécanismes se cumulent en cas de problème de disque ou de base.

**Correction attendue :** rendre l'échec explicite, conserver les données existantes et proposer une reprise. Ne finaliser la migration et le nettoyage qu'après une sauvegarde durable confirmée. Un mode temporaire doit être clairement annoncé et ne doit pas déclencher la suppression des données anciennes.

**Vérification attendue :** une erreur d'ouverture ou d'enregistrement simulée ne supprime aucune donnée de migration et ne donne pas un faux succès.

Sources : [repli en mémoire](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/AppDependencies.swift:51>), [sauvegarde silencieuse](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/ProgressStore.swift:217>), [finalisation de la migration](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/V3Migration.swift:60>).

### F4 Le contrôle éditorial peut être contourné par omission

**P1 — Reproduit dans un dossier temporaire.**

La construction du pack accepte une fiche contrôlée automatiquement lorsque son rapport de seconde relecture est absent. « Pas de rapport » équivaut actuellement à « pas de problème signalé ».

Le seuil d'erreur de l'échantillon humain est affiché dans l'outil de relecture. La construction du pack ne vérifie ni que cet échantillon est terminé, ni que son résultat autorise la publication.

**Correction attendue :** une fiche sans rapport requis reste en attente. La décision de publication doit porter sur une version précise de la fiche et du lot. L'échantillon et son seuil doivent être des conditions vérifiées, pas seulement une consigne affichée.

**Vérification attendue :** une relecture absente, périmée ou un échantillon incomplet bloque le pack avec une liste des éléments manquants. Cela ne démontre pas que les 176 fiches actuelles ont sauté la relecture ; cela démontre que le mécanisme le permet.

Sources : [assemblage du pack](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/content/pipeline/sagace_pipeline/build.py:17>), [échantillon et taux d'erreur](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/content/pipeline/sagace_pipeline/review.py>).

### F5 Le signalement promet une transmission qui ne se produit pas

**P1 — Confirmé dans le code.**

Après « Envoyer », l'application affiche « Merci, on corrige sous 7 jours ». Le signalement reste dans SwiftData sur l'appareil. La proposition d'un mot suit le même principe local. L'export des relectures est réservé à la bêta.

**Correction attendue :** rendre possible un envoi réel, par exemple un brouillon de mail ou une feuille de partage explicite. Afficher une confirmation adaptée à ce qui est réellement fait. Retirer la promesse de délai tant qu'aucun traitement ne la garantit.

**Vérification attendue :** l'utilisateur sait si son message est seulement enregistré, prêt à envoyer ou transmis. Une erreur de livraison ne produit pas une confirmation de réception.

Sources : [enregistrement local](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Fiche/ReportView.swift:26>), [promesse de correction](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Fiche/ReportView.swift:65>), [suggestions](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Explore/ExploreViewModel.swift>).

### F6 La politique de confidentialité manque dans l'application

**P1 — Confirmé dans le code et les fichiers de publication.**

`AppLinks.privacy` vaut `nil`. Le lien disparaît du paywall et des réglages. Le document local comporte encore des champs à compléter : date, adresse et contact.

Apple demande un lien vers la politique dans l'application et dans les métadonnées App Store Connect. Le manifeste de confidentialité ne remplace pas cette politique. Source : [règle Apple 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy).

**Correction attendue :** publier le texte final adapté à iPhone et iPad, puis vérifier le lien depuis l'application. La configuration réelle d'App Store Connect reste à contrôler séparément.

Sources : [lien absent](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Shared/AppLinks.swift:8>), [texte à compléter](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/docs/sagace/store/confidentialite.md>).

### F7 Le pack anglais est déjà actif

**P2 — Reproduit sur la règle de sélection.**

Un appareil dont la première langue est l'anglais charge le pack anglais, même si le français figure ensuite dans ses préférences. Le comportement s'applique aussi aux autres langues non françaises. Il dépend de la langue du système, pas du marché choisi pour Sagace.

Conséquence supplémentaire reproduite : le mini-test annonce cinq pièges, mais le pack anglais ne fournit aucune question pour les cinq familles demandées. Il contient uniquement la famille `motMalCompris`.

**Correction attendue :** conserver le pack et les données historiques, mais définir explicitement leur accès. Les nouvelles installations de la version française doivent recevoir l'expérience française. Les anciens utilisateurs Words ont besoin d'un accès compréhensible à leurs mots conservés, sans changement implicite de langue du téléphone.

Sources : [sélection de langue](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceCore/Sources/SagaceCore/Content/ContentRepository.swift:90>), [choix du pack](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/AppDependencies.swift:84>), [construction du mini-test](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceCore/Sources/SagaceCore/Purchases.swift>).

### F8 Une partie des questions rédigées reste inaccessible

**P2 — Reproduit sur cent graines de génération.**

Pour une fiche et un jeu, le moteur sélectionne toujours la première question écrite. Sur les 352 questions du pack français, 79 sont des questions supplémentaires du même jeu dans une fiche. Elles ne sont pas utilisées par cette sélection.

Exemple : la fiche « acception » contient deux contextes opposés pour distinguer « acception » et « acceptation ». Cent graines différentes n'affichent que le premier contexte.

**Correction attendue :** sélectionner plusieurs variantes et suivre les questions déjà rencontrées. Tester le transfert vers un contexte nouveau, plutôt que la mémorisation d'une phrase unique.

Source : [sélection de la première question](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceCore/Sources/SagaceCore/Practice/QuestionFactory.swift:129>).

### F9 Le compteur de maîtrise peut diminuer

**P2 — Reproduit au niveau du stockage.**

Après avoir maîtrisé une fiche, la trier « Je savais » remplace son état de révision par un état vide. Le compteur passe de un à zéro dans le scénario testé.

La description App Store affirme pourtant que ce compteur ne fait que monter. Plus largement, un tri de découverte ne devrait pas effacer une validation déjà obtenue sans action explicite.

**Correction attendue :** séparer le choix de rangement de la preuve d'apprentissage. Prévoir une action distincte pour réinitialiser ou reprendre un mot si nécessaire.

Sources : [réinitialisation du statut](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/ProgressStore.swift:116>), [promesse publique préparée](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/docs/sagace/store/fr-FR/description.txt>).

### F10 Certaines promesses dépassent le contenu disponible

**P2 — Comptage du pack français.**

125 fiches sur 176 comportent une phrase d'auteur. La description préparée pour l'App Store en annonce une sur chaque fiche. Les statuts du pack indiquent huit relectures humaines ; les autres fiches sont contrôlées automatiquement. Présenter tout le pack comme individuellement relu par une personne serait inexact.

L'attribution d'« acception » a été vérifiée sur [Wikisource](https://fr.wikisource.org/wiki/Albert_Savarus) : la phrase est présente et l'édition consultée date de 1855. Ce contrôle ponctuel ne valide pas toutes les citations. Les dates doivent être présentées comme dates d'édition lorsqu'elles correspondent à l'édition consultée.

**Correction attendue :** aligner les textes publics avec le pack réellement embarqué. Une citation est un exemple d'usage à contextualiser ; son ancienneté ne suffit pas à établir l'usage contemporain.

Sources : [pack publié](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/content/fr/fiches.json>), [description App Store](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/docs/sagace/store/fr-FR/description.txt>).

## Autres défauts à vérifier ou corriger

| Sujet | Constat et conséquence | Action |
| --- | --- | --- |
| Réglages du feed | Au retour des réglages, le feed actualise ses compteurs et ses tris, mais ne recharge pas les préférences ni les pages. Le nouveau rythme ou filtre peut attendre un rechargement. | Tester un changement de rythme et de famille, puis actualiser les éléments concernés sans perdre la position. |
| Fin du feed Premium | Les nouvelles pages sont insérées avant la carte de fin, tandis que la page courante reste identifiée comme la fin. | Vérifier le maintien de position sur appareil et orienter vers la première nouvelle fiche. Le symptôme visuel reste à reproduire. |
| Sons | Le choix « Effets et ambiance » est enregistré, mais aucune consommation de `soundMode` n'a été trouvée hors des réglages et du modèle. | Fournir le comportement annoncé ou retirer temporairement cette option de l'interface. |
| Accessibilité | Le test de session échoue deux fois sur « Exact. », avec « Label not human-readable ». | Examiner le libellé exposé et l'animation avec VoiceOver. L'échec automatisé est confirmé ; la gêne réelle reste à qualifier. |
| Achats lents | Le lancement est borné, mais la restauration et la confirmation après achat attendent encore StoreKit sans état d'attente prolongée explicite. | Tester hors ligne et avec réponse lente. Informer l'utilisateur et proposer une reprise. |
| Migration | Les mots anglais peuvent être conservés en attente sans apparaître dans la bibliothèque française. | Montrer où retrouver les mots Words et distinguer « conservés » de « disponibles dans cette bibliothèque ». |

Sources : [retour des réglages](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Feed/FeedViewModel.swift:228>), [lot Premium](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Feed/FeedViewModel.swift:187>), [sons](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Profile/SettingsView.swift:60>), [retour de réponse](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Practice/AnswerFeedback.swift>), [achats](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Services/EntitlementService.swift>), [mots conservés](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/V3Migration.swift>).

## Simplifier les parcours en conservant la liberté

### Rendre visible ce que Sagace enseigne

Aujourd'hui, la carte commence par le mot et sa définition. La distinction utile arrive après un toucher. Sur iPad portrait, la grande carte accentue l'espace vide autour de cette définition.

Proposition : montrer directement un exemple court ou la confusion essentielle, selon la fiche. Garder les sources, l'étymologie et les développements dans le détail. L'utilisateur doit pouvoir comprendre en quelques secondes ce que cette fiche lui apporte.

L'amélioration attendue est une valeur plus visible. Elle doit être vérifiée auprès de nouveaux utilisateurs ; aucune mesure de conversion ne permet encore de la chiffrer.

### Donner des noms aux actions principales

Les deux actions centrales sont actuellement une coche et un marque-page. Les libellés existent pour l'accessibilité, mais ne restent pas visibles dans la barre.

Proposition : afficher « Je connais » et « À retenir », avec une possibilité simple d'annuler le dernier tri. Le défilement reste possible sans répondre. « Je connais » exprime une déclaration ; le statut de maîtrise découle des exercices.

Un exercice facultatif sur le mot courant peut vérifier son emploi. Il ne doit ni interrompre le défilement ni devenir une condition de passage.

Source : [barre d'actions](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Feed/FeedChrome.swift:70>).

### Donner trois destinations stables

| Destination proposée | Rôle |
| --- | --- |
| Découvrir | Feed, recherche et exploration des mots. |
| Mes mots | Mots à retenir, mots maîtrisés, collections et carnet personnel. |
| Jeux | Exercices au choix, révisions et défis. |

Cette structure doit rester cohérente entre iPhone et iPad. Le profil, les réglages et les informations légales peuvent rester secondaires. La bibliothèque ne devrait pas nécessiter de comprendre d'abord l'icône Explorer.

Le carnet de mots saisis à la main doit avoir un nom distinct de « Mes mots ». Dans le fonctionnement actuel, ces entrées restent des notes et ne rejoignent pas automatiquement les jeux ni les révisions. L'interface doit l'expliquer, ou le produit doit intégrer ce contenu à l'apprentissage.

### Organiser les jeux par intention

Conserver les jeux utiles ne nécessite pas de les présenter tous au même niveau.

| Intention visible | Exercices possibles |
| --- | --- |
| Comprendre un mot | Sens, Devine le mot. |
| Choisir le bon mot | Mot juste, Paronymes. |
| Employer avec précision | Reformulations, usages en contexte. |
| Jouer un défi | Mot croisé, Rush, Sprint, Perfection. |

L'utilisateur reste libre d'ouvrir chaque mode. Les révisions dues doivent être clairement accessibles, sans concurrencer un grand appel au test de trente questions. Une session libre ne doit pas commencer par une obligation de niveau.

La suggestion de jeu qui s'ouvre automatiquement après l'objectif peut devenir une proposition discrète. Atteindre son objectif doit laisser continuer le défilement sans fenêtre imposée.

### Clarifier objectif et disponibilité

Le rythme quotidien définit aujourd'hui aussi la limite gratuite : deux fois l'objectif, soit dix nouvelles fiches pour le réglage par défaut. Un simple affichage marque immédiatement la fiche comme vue ; le délai d'une seconde défini dans les règles n'est pas utilisé par le feed.

Afficher clairement ce qui relève d'un objectif personnel et ce qui relève de l'offre gratuite. Un défilement rapide ne devrait pas donner l'impression d'avoir consommé une séance d'apprentissage.

Avec 176 fiches, parcourir dix nouvelles fiches triées par jour épuise le stock en environ dix-huit jours, sous cette hypothèse de rythme. Prévoir un état de catalogue épuisé distinct d'une limite quotidienne et une manière de reparcourir les mots. Le pack de mille fiches améliore la profondeur, mais ne remplace pas une bonne variation des contextes.

Sources : [sélection et limites](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceCore/Sources/SagaceCore/Feed/FeedEngine.swift>), [fiche marquée vue](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Feed/FeedViewModel.swift:151>), [fin du lot](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Feed/EndCard.swift>).

## Onboarding proposé

Le parcours actuel comporte onze étapes logiques, dont une étape de cinq questions avec leurs corrections. L'attribution et l'âge arrivent avant la découverte. Le choix d'un objectif est obligatoire. Le test n'est pas facultatif. Le paywall et le widget précèdent l'accès libre au feed.

La question d'âge annonce une adaptation des exemples. Dans les sources examinées, l'âge est stocké mais n'intervient pas dans la sélection ni les exemples. Cette question n'apporte donc pas le bénéfice annoncé.

Le parcours cible proposé tient en trois moments :

1. **Une promesse et une action.** « Les mots courants, employés avec précision. » Bouton « Découvrir les mots ». Pas de donnée à renseigner.
2. **Une première vraie fiche.** Un mot, un contexte utile et les actions « Je connais » et « À retenir ». Une aide brève explique le défilement. L'utilisateur peut continuer immédiatement.
3. **Une découverte facultative de la pratique.** « Essayer ce mot dans une phrase » ou continuer à explorer. L'exercice montre une explication utile, puis laisse revenir au feed.

Les autres choix arrivent quand ils ont un sens : rappel après un premier mot enregistré, widget depuis une demande explicite, personnalisation dans les réglages. Le test de niveau reste accessible dans Jeux. Le paywall apparaît lors d'une demande de fonction Premium ou d'une limite clairement annoncée.

L'objectif proposé pour une séance de test utilisateur est d'atteindre la première fiche utile en moins de trente secondes. C'est une cible à mesurer, pas un résultat observé. L'application doit conserver la position et les choix si l'utilisateur ferme cette introduction.

Pour Words, prévoir une entrée distincte : expliquer le changement, montrer les données retrouvées et l'état réel des achats, puis permettre d'explorer. Un ancien utilisateur ne doit pas refaire un examen pour retrouver sa bibliothèque.

Sources : [étapes](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Onboarding/OnboardingViewModel.swift:22>), [promesse liée à l'âge](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Onboarding/OnboardingView.swift:141>), [entrée Words](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/App/Features/Migration/MigrationView.swift>).

## iPad dès la première version française

La branche iPad compile. Ses captures montrent une amélioration réelle : largeur de lecture limitée, détail à côté du mot en grande largeur, grilles plus lisibles et onboarding centré.

Quatre points restent à traiter pour considérer cette expérience prête :

1. **Réunir les corrections.** La branche iPad locale ne contient pas encore le délai maximal ajouté pour StoreKit dans `79cc19d`. Publier cette branche seule réintroduirait le chemin de lancement non borné.
2. **Tester les largeurs intermédiaires.** Explorer passe à deux colonnes dès 600 points, avec une colonne gauche fixe de 360 points. Il ne reste alors qu'environ 239 points à droite avant les marges. Les captures plein écran ne valident pas ce cas. Adapter le seuil au contenu et à la taille du texte.
3. **Préserver le contexte au redimensionnement.** Vérifier qu'une fiche ou une collection ouverte reste sélectionnée lors d'un passage de deux colonnes à une seule, puis au retour. Les deux présentations utilisent des structures de navigation différentes.
4. **Vérifier la continuité entre appareils.** Le stockage actuel ne prévoit pas de synchronisation de progression. Un usage alterné sur iPhone et iPad donnera des bibliothèques et des révisions séparées. Définir cette expérience avant la sortie, avec une information claire si elle reste locale.

Sur grand écran, la colonne de droite peut privilégier le contexte, les nuances et les sources. Répéter le même mot, sa prononciation et sa définition sur les deux côtés utilise une partie de l'espace sans information supplémentaire.

La recette iPad doit couvrir portrait, paysage, petites fenêtres, Split View, grandes tailles de texte, VoiceOver et clavier matériel. Le widget très grand doit être utilisé sur l'écran d'accueil, au-delà de sa présence dans la galerie. Les captures App Store doivent représenter cette version.

Sources : [spécification iPad](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/.claude/worktrees/m10-ipad/docs/sagace/09_IPAD.md>), [bascule en deux colonnes](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/.claude/worktrees/m10-ipad/App/Features/Explore/ExploreView.swift:19>), [largeurs](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/.claude/worktrees/m10-ipad/Packages/SagaceUI/Sources/SagaceUI/Tokens/Metrics.swift:42>), [feed iPad](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/.claude/worktrees/m10-ipad/App/Features/Feed/FeedView.swift>), [stockage](</Users/hugo.peyron/Documents/CODE/Cortex SASU/Sagace/Packages/SagaceData/Sources/SagaceData/SagaceStore.swift>).

## Architecture et maintenance

L'architecture actuelle mérite d'être conservée. La priorité technique est de renforcer ses garanties aux frontières : sauvegarde, migration, publication du contenu et passage d'un exercice à une révision validante.

Il faut aussi une séparation explicite entre quatre notions : avoir vu un mot, déclarer le connaître, vouloir le revoir et démontrer une maîtrise. Elles peuvent rester discrètes dans l'interface tout en étant distinctes dans les données.

Le contenu devrait disposer d'identifiants de questions stables et d'un contexte d'usage structuré. Cela facilite les variantes, la détection des répétitions et les corrections éditoriales. Une mise à jour importante d'une fiche doit pouvoir être reliée aux résultats obtenus sur son ancienne version.

Les documents produit doivent être réconciliés avec les décisions récentes : iPad autrefois hors périmètre, révisions autrefois dans le feed, offre annuelle avec essai dans l'ancienne vision, offre hebdomadaire et à vie dans le code. Les modifications futures doivent partir d'une référence commune.

Aucun SDK tiers ni client réseau d'envoi de progression n'a été trouvé dans le runtime examiné. Cela réduit la surface d'exposition. Cette revue ne comprend pas un test d'intrusion, un audit juridique exhaustif ni une recherche de secrets dans tout l'historique Git.

## Ordre de travail proposé

Les efforts sont relatifs. Ils servent à comparer les chantiers, sans constituer un calendrier.

| Ordre | Chantier | Effort relatif | Résultat attendu |
| --- | --- | --- | --- |
| 1 | Corriger les verdicts et protéger les révisions espacées | Moyen | Les réponses et la maîtrise deviennent cohérentes avec la promesse. |
| 2 | Sécuriser sauvegarde, migration et publication du contenu | Moyen à élevé | Aucun succès silencieux après un échec ; aucun lot incomplet publié. |
| 3 | Rendre les signalements réels et finaliser les liens publics | Faible à moyen | Les actions annoncées et les informations accessibles sont exactes. |
| 4 | Réunir iPad et correction de lancement | Faible pour l'intégration, moyen pour la recette | Une seule version testable sur les deux appareils. |
| 5 | Montrer une fiche utile immédiatement | Moyen | Première valeur sans test ni formulaire obligatoire. |
| 6 | Clarifier navigation, tri et accès aux jeux | Moyen à élevé | L'utilisateur retrouve ses mots et choisit son activité sans hésitation. |
| 7 | Varier les contextes et fiabiliser les états de progression | Moyen | Les exercices mesurent davantage que le souvenir d'une phrase. |
| 8 | Valider le lot français et mesurer l'expérience | Élevé selon les corrections | Contenu plus profond et décisions fondées sur des usages observés. |

Pour une expérience iPad présente dès la première version, le chantier 4 et sa recette font partie de la préparation de sortie.

## Vérifications réalisées et limites

| Vérification | Résultat |
| --- | --- |
| Tests SagaceCore | 132 tests réussis. |
| Tests SagaceData | 30 tests réussis. |
| Tests applicatifs et StoreKit local | 17 tests réussis. |
| Test SagaceUI de partage | 1 test réussi. |
| Tests Python du pipeline | 22 tests réussis. |
| Audit UI automatisé | 6 tests réussis sur 7. Échec de `testGameSession`, reproduit séparément sur « Exact. ». |
| Compilation de la branche iPad | Réussie, destination simulateur. |
| Contrôle structurel du pack français | 176 fiches chargées, aucune erreur de validation. |
| Sondes ciblées temporaires | Verdict erroné, maîtrise immédiate, baisse du compteur, répétition des questions, choix de langue et publication sans rapport reproduits. |

Les premiers échecs de fichiers de widgets dans l'environnement restreint ont disparu avec l'accès système requis. Ils ne sont pas retenus comme défauts de l'application.

Les tests StoreKit utilisent la configuration locale. Ils ne remplacent pas les essais App Store sur appareil : ancien abonnement, achat à vie, restauration, réseau lent et mise à jour depuis Words v3. Le temps avant la première valeur n'a pas été mesuré sur appareil. Les onze captures iPad examinées préexistent à cette revue ; elles ne prouvent pas le comportement en fenêtre étroite.

La revue ne valide pas les mille fiches en préparation. Les constats chiffrés concernent le pack français embarqué de 176 fiches. Les recommandations UX sont à confronter à des utilisateurs, sans les présenter comme des gains déjà mesurés.

## Protocole de validation produit

Faire essayer la version simplifiée à cinq à huit adultes francophones, avec au moins un ancien utilisateur Words et un utilisateur iPad. Inclure une personne dont le téléphone est réglé en anglais.

Sans expliquer les commandes, demander de découvrir un mot, d'en conserver un, de le retrouver, de lancer un exercice et de reprendre l'exploration. Observer les hésitations et les retours en arrière. Demander ensuite ce que signifie « maîtrisé » pour la personne.

Mesurer le délai avant la première fiche comprise, la réussite des actions sans aide et la capacité à employer le mot dans une nouvelle phrase. Tester cette dernière capacité après un délai, pas seulement juste après la correction.

Les événements existants en console donnent des points de départ. Un service de mesure ne doit être ajouté qu'avec une décision explicite sur les données nécessaires et leur traitement. Pour la première validation, les séances observées suffisent à repérer les principaux obstacles.
