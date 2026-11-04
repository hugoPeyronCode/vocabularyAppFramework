# Questions ouvertes

À trancher par Hugo. Claude Code ajoute ici toute décision manquante rencontrée pendant le build, avec l'option retenue par défaut.

| # | Question | Option par défaut | Bloquant pour |
| -- | -- | -- | -- |
| 1 | Ce dépôt est-il bien la source de la version en ligne ? Apple ID, version et build en ligne ? | oui (à vérifier dans App Store Connect) | M1 |
| 2 | Nombre d'abonnés actifs et d'achats à vie dans Words v3 ; la build en ligne donne-t-elle le premium à tous (`hasUnlockedPremium = true` dans le code) ? | traiter tout achat existant comme premium | M4 |
| 3 | Utilisateurs anglophones : pack anglais historique (A), tout en français (B), ou pays francophones seulement (C) ? | A | M8 |
| 4 | SDK Facebook : utilisé pour des campagnes Meta en cours ? | retrait | M1 |
| 5 | Outil d'analytics | TelemetryDeck | M7 |
| 6 | Garder l'iPad ? | non, sauf part iPad notable dans App Store Connect | M0 |
| 7 | Offre de bienvenue (PAY-02) : offre promotionnelle signée côté serveur ou abandon en v4 ? | abandon si pas de serveur | M4 |
| 8 | Endpoint pour recevoir les signalements d'erreur | file locale + envoi par mail prérempli en v4 | M2 |
| 9 | Prix : 29,99 € par an avec essai, 49,99 € à vie | oui, à tester | M9 |
| 10 | Marque Sagace : dépôt INPI / EUIPO, domaine, URL des conditions et de la confidentialité | à faire par Hugo | M9 |
| 11 | Validation des 25 fiches modèles (`content/fr/seed_fiches.json`, statut draft) | Hugo relit avant le lancement du pipeline | M8 |
| 12 | Textes de description des 5 niveaux (ligne dépliée de PRA-08 et du sélecteur de niveau) | à écrire par Hugo ; la démo M0 affiche « Niveau n sur 5 » | M3 |
| 13 | Sheet flottante : sur iOS 26 le système fait déjà flotter la sheet (marge et rayon système, proches de 12 pt et 44 pt) et garde son verre si le fond est transparent | iOS 26 : sheet système flottante avec fond `surface` ; iOS 18 : sheet dessinée par `SheetContainer` à 12 pt des bords (non vérifiée faute de simulateur iOS 18 sur le Mac) | M1 |
| 14 | Les commandes de CLAUDE.md visaient le simulateur `iPhone 16`, absent avec Xcode 26.1 | tranché : CLAUDE.md passe à `iPhone 17 Pro` | M0 |
| 15 | Nom affiché sur l'écran d'accueil (`CFBundleDisplayName = Words`) | inchangé jusqu'à M9 (icône, captures, version 4.0) | M9 |
| 16 | Feed : si l'utilisateur suit à la fois des familles et des thèmes, faut-il l'union ou l'intersection ? | union : une fiche passe si sa famille **ou** un de ses thèmes est suivi | M2 |
| 17 | Feed : que faire quand la fenêtre de niveau (±1) n'a plus assez de fiches ? | compléter avec les fiches les plus proches du niveau | M8 |
| 18 | Feed : sans aucune fiche nouvelle disponible, les révisions dues n'apparaissent jamais (règle « après 5 fiches ») | les révisions dues prennent la place des fiches | M3 |
| 19 | Migration : le pack anglais historique (M8) n'existe pas encore, les mots aimés v3 ne trouvent donc aucune fiche | ils sont gardés dans `UserProfile.pendingV3Headwords` et MIG-01 annonce « gardés (n) » ; l'import en « À retenir » se fera à l'arrivée du pack | M8 |
| 20 | Migration, règle 5 : « aucune transaction trouvée » | aucune transaction StoreKit, même expirée, sur `Yearly`, `weekly` ou `lifetime` (`Transaction.all`) ; la valeur de la clé v3 est conservée dans le profil | M4 |
| 21 | MIG-01 « Découvrir » doit mener au mini test et au rythme (ONB-05 à 08), qui arrivent en M4 | en M1, « Découvrir » et « Passer » ouvrent le feed | M4 |
| 22 | Écrans des jalons suivants appelés depuis le feed (Explorer, Profil, Stats, Practice, fiche détaillée, partage, paywall) | sheet provisoire « Bientôt disponible. » | M2 à M5 |
| 23 | Le modèle `Collection` de la spec masque `Swift.Collection` | renommé `UserCollection` | M2 |
| 24 | Test d'interface de la migration (XCUITest) demandé par `04_MIGRATION.md` | migration couverte par 8 tests unitaires + vérification manuelle sur simulateur ; cible XCUITest à créer en M4 avec les tests d'achat | M4 |
| 25 | Pack embarqué : `content/fr/fiches.json` (sortie du pipeline M8) n'existe pas encore | une phase de script copie `content/fr/seed_fiches.json` vers `Content/fr/fiches.json` dans le bundle ; à pointer sur la sortie du pipeline en M8 | M8 |
| 26 | Collections : « collections illimitées » en premium, mais quelle limite en gratuit ? | aucune limite en M2, à fixer avec les verrous PRO en M4 | M4 |
| 27 | Signalements (DET-02) et mots proposés (EXP-03) : l'envoi par mail prérempli de la question n° 8 suppose une adresse de réception | file locale seulement (visible dans Explorer › Signalés) ; envoi à brancher quand l'adresse ou l'endpoint existe | M7 |
| 28 | SHR-01 « Messages » | affiché seulement si l'appareil peut envoyer des messages ; « Partager… » couvre les autres apps | M2 |
| 29 | Textes d'état vide non écrits dans la spec (À retenir, Historique, Signalés, collection vide) | textes provisoires courts, à relire par Hugo | M7 |
| 30 | Collections suggérées (« Écrire au travail », « Pièges des mails », « Bac de français ») : avec quelles fiches ? | créées vides tant qu'il n'y a pas de sélection éditoriale | M8 |
| 31 | Illustrations des familles, thèmes, états vides et MIG-01 | symboles SF en attendant les images de `08_ILLUSTRATIONS.md` | M7 |
| 32 | « Suivre » une famille ou un thème (EXP-02) et « Modifier » (EXP-01) | réservés au premium (« tous les filtres de familles et thèmes »), paywall sinon | M4 |
| 33 | Texte d'autorisation Photos (« Enregistrer l'image ») | en build setting, en français ; à passer dans un `InfoPlist.xcstrings` avec l'anglais (M8) | M8 |
| 34 | PRA-03 « phrase selon le score » : textes non écrits pour les sessions | score et « bonnes réponses » seulement, sans phrase | M7 |
| 35 | Défis en gratuit : PRA-01 les met derrière le bandeau PRO, `03_ARCHITECTURE.md` les compte dans la session gratuite du jour | règle chiffrée de l'architecture : 1 session par jour, défis compris | M4 |
| 36 | Test de précision avec le pack modèle (25 fiches, aucune de niveau 5) : 25 questions au lieu de 30 | les niveaux manquants sont complétés par les voisins ; les seuils restent ceux de 30 questions, à revoir si le pack final ne permet pas 30 fiches distinctes | M8 |
| 37 | Sprint et Perfection : quels jeux ? | tous les jeux en alternance ; Rush garde Le mot juste et Paronymes | M3 |
| 38 | PRA-08 « Voir mes réponses » | la liste des réponses s'affiche directement sous le résultat | M7 |
| 39 | Contenu : `fr.acronyme` liste « sigle » à la fois en synonyme et en confusion | la règle « jamais un synonyme en mauvaise réponse » l'emporte : pas de question Paronymes sur cette fiche ; fiche à corriger (n° 11) | M8 |
| 40 | Texte quand la session gratuite du jour est jouée | « Votre session gratuite du jour est jouée. » + bandeau PRO, provisoire | M4 |
| 41 | App Store Connect avant la v4 : `Yearly` à 29,99 € avec offre d'introduction de 3 jours gratuits, `lifetime` à 49,99 €, partage familial activé (le paywall l'annonce), `weekly` retiré de la vente | à faire par Hugo ; la configuration locale `Config/Sagace.storekit` reflète cette cible, `Config/Words.storekit` reste l'instantané synchronisé de 2024 | M9 |
| 42 | PAY-02 offre de bienvenue (offre promotionnelle signée côté serveur) | non faite, faute de serveur (défaut de la question n° 7) | M9 |
| 43 | Paywall : lien « Confidentialité » sans URL ; « Conditions » | lien Confidentialité masqué tant que l'URL manque ; Conditions = contrat de licence standard d'Apple (n° 10) | M9 |
| 44 | Texte de la notification de fin d'essai | « Votre essai gratuit se termine demain. » / « Vous pouvez annuler à tout moment depuis les réglages de votre compte Apple. », provisoire | M7 |
| 45 | ONB-08 : 10 fiches choisies pendant l'onboarding sans finir en premium | rythme ramené à 5 à la fin de l'onboarding | M5 |
| 46 | Annuel sans essai (déjà utilisé, ou pas d'offre d'introduction) | « 29,99 € par an » et bouton « Continuer », sans frise ni rappel | M4 |
| 47 | ONB-09 : heure du rappel quotidien | enregistrée (modèle `Reminder`) et autorisation demandée ; planification réelle avec `ReminderScheduler` en M5 | M5 |
| 48 | Tester les achats dans Xcode | choisir `Config/Sagace.storekit` dans Scheme › Run › Options › StoreKit Configuration ; les tests `SagaceAppTests` l'utilisent déjà sans réglage | M4 |
