# Pipeline de contenu

Production des fiches de Sagace, de `docs/sagace/05_CONTENT.md` section 3. Python 3.12 ou plus. Toutes les commandes se lancent depuis `content/pipeline/`.

```bash
python3 -m sagace_pipeline --help
python3 -m unittest discover tests     # tests, sans réseau ni API
```

Toutes les étapes n'utilisent que la bibliothèque standard. Les étapes IA (`draft`, `critic`) se font **sans clé API**, par des agents Claude Code (section suivante). Le mode API (`--confirm`, SDK `anthropic` de `requirements.txt`) reste disponible, mais il n'est pas utilisé.

## Avant de commencer

| Donnée | Où la trouver | Utilisée par |
| -- | -- | -- |
| Lexique 3 (`Lexique383.tsv`, CC BY-SA 4.0) | lexique.org, archive « Lexique383 » | select, gather, check |
| XMLittré (dossier de fichiers `*.xml`), facultatif | XMLittré (licence de la version numérique à vérifier, `05_CONTENT.md` section 2) | gather |
| Lafaye, *Dictionnaire des synonymes* (texte brut), facultatif | Wikisource ou Internet Archive, pas Gallica | gather |
| Liste éditoriale | `content/fr/listes/editorial.csv` (`headword,family,note`) | select |
| Mots sensibles | `content/fr/listes/sensibles.txt` | check |
| Requêtes par famille | `content/fr/listes/selection.json` | select |

Le Wiktionnaire et Wikisource sont lus par leurs API publiques, mises en cache dans `work/cache/` : pas de dump à télécharger. Les données de travail vont dans `work/`, non versionné.

## Rédaction et relecture sans clé API (mode agent)

```bash
python3 -m sagace_pipeline draft --agent export --limit 200   # work/agent/draft/CONSIGNES.md + in/<id>.json
# des agents Claude Code lisent CONSIGNES.md et écrivent out/<id>.json, un fichier par fiche
python3 -m sagace_pipeline draft --agent import               # → work/drafts/ (mêmes règles d'ancrage que l'API)
python3 -m sagace_pipeline check --lexique work/data/Lexique383.tsv
python3 -m sagace_pipeline critic --agent export              # work/agent/critic/
python3 -m sagace_pipeline critic --agent import              # → work/critic/, rapport_critic.csv
```

À l'import, l'identifiant, la famille, les sources et le statut viennent des extraits, et une phrase d'auteur n'est gardée que si elle fait partie des candidates. Une réponse illisible est signalée et reste à refaire.

## Les 8 étapes

```bash
python3 -m sagace_pipeline select --lexique ~/Lexique383.tsv          # 1 → work/candidats.csv (1 500 candidats)
python3 -m sagace_pipeline gather --lexique ~/Lexique383.tsv --limit 200   # 2 → work/raw/
python3 -m sagace_pipeline quotes --limit 200                           # 3 → work/quotes/
python3 -m sagace_pipeline draft --limit 200                            # 4 : estimation du coût seulement
python3 -m sagace_pipeline draft --limit 200 --confirm                  # 4 → work/drafts/ (Batches API)
python3 -m sagace_pipeline check --lexique ~/Lexique383.tsv             # 5 → work/checked/, rapport_check.csv
python3 -m sagace_pipeline critic --confirm                             # 6 → work/critic/, rapport_critic.csv
python3 -m sagace_pipeline review                                       # 7 → http://localhost:8765
python3 -m sagace_pipeline build                                        # 8 → content/fr/fiches.json
```

- **Coût.** `draft` et `critic` n'envoient rien sans `--confirm` : sans ce drapeau, elles affichent le nombre de requêtes et une estimation en dollars. Elles passent par la Batches API (moitié prix, résultats en moins d'une heure en général). `--sync` envoie les requêtes une à une, pour un essai de quelques fiches ; en cas de refus, l'API rejoue alors la requête sur un modèle de repli.
- **Modèle** : `claude-opus-5-5`, effort `high`, sortie JSON contrainte par le schéma. Les règles, le schéma et les fiches modèles sont mis en cache.
- **Ancrage.** Le modèle ne rédige qu'à partir des extraits. L'identifiant, la famille, les sources et le statut sont réimposés depuis les extraits, et une phrase d'auteur n'est gardée que si elle fait partie des candidates trouvées sur Wikisource.
- **Relecture.**
  - `review` liste d'abord toutes les fiches signalées par `critic`, puis 10 % des autres, tirées au hasard par lot de 200.
  - Une page montre la fiche rendue, les extraits sources et le rapport du correcteur, avec trois boutons : **Valider**, **Corriger** (le JSON modifié est enregistré), **Rejeter**.
  - La page d'accueil affiche le taux d'erreur de l'échantillon. Au-delà de 2 %, le lot repasse par `draft`, avec les corrections en exemples.
- **Construction du pack.** `build` n'écrit que des fiches conformes au schéma :
  - les fiches `autoChecked` non signalées ;
  - les fiches relues (`humanChecked`) ;
  - jamais une fiche rejetée.
  
  La version du pack est incrémentée dans `content/fr/fiches.version`. Au build suivant de l'app, `content/fr/fiches.json` remplace les 25 fiches modèles.

Lot test recommandé : 200 candidats de bout en bout, mesure du taux d'erreur, puis les 1 300 suivants.

## Pack anglais historique

```bash
python3 -m sagace_pipeline convert-en     # content/legacy/v3_words.json → content/en/fiches.json
```

Conversion des 24 939 mots de Words v3 (option A de `04_MIGRATION.md`). La v3 ne donne ni nature, ni prononciation, ni genre : ces champs restent vides (`partOfSpeech = inconnu`). L'app charge ce pack quand la langue de l'appareil n'est pas le français.
