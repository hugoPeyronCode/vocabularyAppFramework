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
