# 05 Contenu

## 1. Ce qu'est une bonne fiche
- **Un mot courant**, dans les 15 000 mots les plus fréquents du français (Lexique 3), sauf expressions.
- **Un piège réel** : une confusion, un emploi critiqué, un verbe trop vague, une redite, un anglicisme, un sens mal compris.
- **Une règle claire et honnête** : on distingue *fautif* (erreur reconnue), *critiqué* (condamné par l'Académie ou les grammairiens, mais répandu) et *toléré* (correct mais moins précis). Jamais de ton moralisateur.
- **Des exemples du quotidien** (travail, mails, conversations), le mot entre `**`.
- **Une phrase d'auteur** du domaine public qui emploie le mot correctement.
- **Des sources** citées sur la fiche.

Format exact : `content/schema/fiche.schema.json`. Modèles : `content/fr/seed_fiches.json` (25 fiches, statut `draft`, à valider par Hugo avant d'être utilisées comme exemples dans les prompts).

## 2. Sources (toutes gratuites)
| Source | Licence | Usage |
| -- | -- | -- |
| Lexique 3 (lexique.org) | CC BY-SA 4.0 | fréquence, nature, genre ; sélection et niveau |
| Wiktionnaire (fr.wiktionary.org, dump XML) | CC BY-SA 4.0 | sens, synonymes, paronymes, prononciation API, étymologie |
| Littré (via XMLittré) | texte du domaine public, licence de la version numérique à vérifier | remarques d'usage, nuances |
| Lafaye, *Dictionnaire des synonymes de la langue française* (1858) | domaine public (prendre Wikisource ou Internet Archive, pas Gallica) | nuances entre voisins |
| Wikisource (fr.wikisource.org) | textes du domaine public, transcription CC BY-SA | phrases d'auteur |

**Interdits** : site du dictionnaire de l'Académie française (CGU : pas d'usage commercial ni d'extraction), TLFi, dictionnaires commerciaux, contenu généré sans source.

**Conséquence de la licence CC BY-SA** : les fiches dérivées du Wiktionnaire et de Lexique sont publiées sous CC BY-SA 4.0. Ajouter dans l'app (À propos › Sources et licences) l'attribution et la mention de licence, et sur chaque fiche la liste de ses sources.

## 3. Pipeline (scripts dans `content/pipeline/`, Python 3.12)

```
1 select      → candidats.csv       (Lexique + listes de familles tirées du Wiktionnaire)
2 gather      → raw/<id>.json        (extraits bruts : Wiktionnaire, Littré, Lafaye, Lexique)
3 quotes      → quotes/<id>.json     (phrases Wikisource contenant le mot, 3 candidates)
4 draft       → drafts/<id>.json     (IA : rédaction ancrée sur raw + quotes)
5 check       → rapport_check.csv    (contrôles automatiques, statut autoChecked ou rejet)
6 critic      → rapport_critic.csv   (seconde passe IA, signalements)
7 review      → interface de relecture (Hugo : signalés + 10 % tirés au hasard)
8 build       → App/Content/fr/fiches.json (seulement autoChecked et humanChecked, version incrémentée)
```

### 3.1 Sélection
- Paronymes : catégorie et annexes de paronymes du Wiktionnaire, croisées avec Lexique (les deux mots dans le top 30 000).
- Impropriétés, pléonasmes, anglicismes : sections "Usage", "Notes" et "Note d'usage" du Wiktionnaire qui contiennent des marqueurs (*critiqué*, *pléonasme*, *anglicisme*, *à éviter*), et remarques du Littré.
- Passe partout : verbes faire, mettre, dire, avoir, donner, prendre, gérer, voir ; pour chaque locution fréquente (« faire un discours »), le verbe précis attesté dans les sources.
- Nuances : paires de synonymes du Wiktionnaire présentes dans Lafaye.
- Mots mal compris et expressions : liste éditoriale d'Hugo (fichier `content/fr/listes/editorial.csv`) vérifiée contre le Wiktionnaire.
- Sortie : 1 500 candidats pour viser 1 000 fiches validées.

### 3.2 Phrases d'auteur
- Recherche plein texte dans un dump Wikisource (textes antérieurs à 1955, auteurs morts depuis plus de 70 ans).
- Filtres : phrase de 8 à 35 mots, le mot employé **dans le sens de la fiche** (vérifié à l'étape critic), pas d'archaïsme qui change le sens.
- Garder auteur, œuvre, année, URL de la page.
- Si aucune phrase fiable : `authorQuote = null` (la fiche reste publiable).

### 3.3 Prompt de rédaction (étape draft)

```
Tu rédiges une fiche pour Sagace, une app qui aide des francophones adultes à employer le mot juste au quotidien.
Règles :
- Tu n'utilises QUE les informations des extraits fournis (Wiktionnaire, Littré, Lafaye, Lexique). Tu n'inventes aucun sens, aucune règle, aucune étymologie. Si une information manque, mets null.
- Ton : clair, précis, bienveillant, jamais scolaire ni moralisateur.
- Verdict : "fautif" seulement si les sources parlent d'erreur ; "critique" si l'emploi est condamné par l'Académie ou des grammairiens mais répandu ; "tolere" si l'emploi est correct mais moins précis.
- shortDefinition : 90 caractères maximum, sans point final.
- examples : 2 phrases du quotidien moderne (travail, mails, vie courante), le mot entre ** **.
- quiz : 2 questions dont la bonne réponse est indiscutable selon les sources ; les mauvaises réponses ne doivent jamais être correctes dans la phrase ; mêmes nature et genre que la bonne réponse.
- Juste ou fautif et Le mot juste : un emploi de verdict "fautif" ou "critique" compte comme fautif (réponse « Fautif », ou mauvaise réponse) ; l'explication dit alors « tournure critiquée » et donne la forme recommandée. Pas de question Juste ou fautif sur un emploi "tolere".
- Prononciation et registre : ceux des extraits seulement. Registre "soutenu", "familier" ou "litteraire" seulement si un marqueur des extraits l'indique, sinon "courant".
- Pléonasmes : quand le Wiktionnaire ne signale pas la redondance mais qu'elle découle directement de la définition donnée par les extraits, verdict "critique" au plus, jamais "fautif".
- Impropriétés et anglicismes : les 2 exemples emploient le mot correctement (ou, s'il n'a pas d'emploi correct, la forme recommandée) ; la tournure critiquée n'apparaît que dans le bloc d'usage (avoid) et les quiz.
- Choisis la meilleure phrase d'auteur parmi les candidates fournies, ou null si aucune n'emploie le mot dans ce sens.
Réponds uniquement par un objet JSON conforme au schéma fourni.
Extraits : {raw}
Phrases candidates : {quotes}
Schéma : {schema}
Exemples de fiches validées : {3 fiches modèles de la même famille}
```

### 3.4 Contrôles automatiques (étape check, bloquants)
1. Conforme au schéma JSON.
2. `partOfSpeech` et `gender` identiques à Lexique et au Wiktionnaire.
3. Le mot (ou une forme fléchie) présent dans chaque exemple et dans la phrase d'auteur.
4. `shortDefinition` ≤ 90 caractères, sans point final.
5. Quiz : la bonne réponse n'apparaît pas parmi les synonymes interdits ; aucune mauvaise réponse n'est un synonyme listé ; même nature et même genre.
6. Pas de doublon d'`id` ni de `headword` dans la même famille.
7. Chaque fiche a au moins une source avec URL.
8. Liste de mots sensibles (sexualité, insultes, violence) : rejet automatique pour la v4.
Résultat : `reviewStatus = autoChecked` si tout passe, sinon la fiche est rejetée avec la raison.

### 3.5 Prompt critique (étape critic)

```
Tu es correcteur exigeant pour un dictionnaire d'usage du français.
Vérifie la fiche ci-dessous contre les extraits sources, point par point :
1. La définition est-elle fidèle aux sources ? 2. La règle d'usage et le verdict sont-ils justifiés par les sources ?
3. Chaque exemple est-il correct, naturel, et emploie-t-il le mot dans le bon sens ? 4. La phrase d'auteur emploie-t-elle le mot dans le sens de la fiche ?
5. Chaque question de quiz a-t-elle une seule bonne réponse indiscutable ? 6. Y a-t-il une faute de langue dans la fiche ?
Convention de Sagace, à ne pas signaler : dans les quiz, un emploi de verdict « critique » compte comme fautif (réponse « Fautif », ou mauvaise réponse), comme un emploi « fautif ». Signale en revanche un verdict que les sources ne justifient pas, ou une question Juste ou fautif sur un emploi « tolere ».
Un pléonasme dont la redondance découle directement de la définition donnée par les extraits justifie un verdict « critique », même si le Wiktionnaire ne le signale pas ; signale un verdict « fautif » sans source. Dans les impropriétés et anglicismes, les exemples emploient le mot correctement (ou la forme recommandée) : signale un exemple qui donne la tournure critiquée comme modèle. Signale une prononciation absente des extraits, et un registre soutenu, familier ou littéraire sans marqueur dans les extraits.
Réponds en JSON : { "ok": bool, "problems": [ { "field": "...", "issue": "...", "severity": "bloquant|mineur" } ] }.
Fiche : {draft}
Extraits : {raw}
```
Toute fiche avec un problème `bloquant` part en relecture humaine.

### 3.6 Relecture par Hugo (étape review)
- Petite interface locale (page HTML servie par le script, ou tableur) : la fiche rendue comme dans l'app, les extraits sources à côté, boutons **Valider**, **Corriger**, **Rejeter**.
- Relire : toutes les fiches signalées par l'étape critic, plus 10 % tirées au hasard par lot de 200.
- Seuil : si plus de 2 % d'erreurs dans l'échantillon, tout le lot repasse par draft avec les corrections en exemples.
- Estimation pour 1 000 fiches : environ 250 fiches à lire, 4 à 6 heures.

### 3.7 Après la sortie
- Bêta TestFlight de 30 à 50 personnes à l'aise avec la langue : boutons **Juste** / **À corriger** sur chaque fiche (build bêta uniquement), premium à vie en remerciement.
- Bouton **Signaler une erreur** en production, correction sous 7 jours, nouvelle version du pack.
- Objectif : 200 fiches nouvelles par mois.

## 4. Volumes de lancement (1 000 fiches)
| Famille | Fiches |
| -- | -- |
| Paronymes | 180 |
| Impropriétés | 150 |
| Verbes passe partout | 120 |
| Nuances | 150 |
| Pléonasmes | 80 |
| Anglicismes et faux amis | 100 |
| Mots mal compris | 120 |
| Expressions | 100 |

Niveaux : 15 % niveau 1, 25 % niveau 2, 30 % niveau 3, 20 % niveau 4, 10 % niveau 5.

## 5. Pack anglais historique (option A de `04_MIGRATION.md`)
Script `content/pipeline/convert_v3_en.py` : lit `content/legacy/v3_words.json` (le `Data/words.json` de la v3, déplacé au jalon M1), produit `App/Content/en/fiches.json` au format `Fiche` avec `family = motMalCompris`, `reviewStatus = draft`, `quiz` générés (Sens, Devine le mot) depuis définitions et mots voisins de même `Topic`. Visible uniquement si la langue de l'appareil n'est pas le français.
