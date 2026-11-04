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
