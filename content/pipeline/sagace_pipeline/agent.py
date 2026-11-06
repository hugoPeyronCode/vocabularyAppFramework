"""Étapes 4 et 6 sans clé API : la rédaction et la relecture sont faites par des agents (Claude Code), fichier par fichier.

`export` écrit les consignes et une entrée par fiche dans `work/agent/<étape>/` ; l'agent écrit sa réponse JSON dans
`out/<id>.json` ; `import` la contrôle et la range comme l'aurait fait l'appel à l'API (mêmes règles d'ancrage).
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import critic, draft
from .common import SCHEMA_PATH, SEED_PATH, WORK, read_csv, read_json, stage_dir, write_json

STEPS = ("draft", "critic")


def folders(step: str, work: Path) -> tuple[Path, Path, Path]:
    root = work / "agent" / step
    inputs, outputs = root / "in", root / "out"
    inputs.mkdir(parents=True, exist_ok=True)
    outputs.mkdir(parents=True, exist_ok=True)
    return root, inputs, outputs


def draft_pending(work: Path, limit: int | None) -> list[tuple[str, dict[str, Any], list[dict[str, Any]]]]:
    """Candidats avec des extraits et au moins un sens, sans brouillon : mêmes critères que l'étape draft."""
    done = work / "drafts"
    pending = []
    for candidate in read_csv(work / "candidats.csv")[:limit]:
        identifier = candidate["id"]
        raw_path = work / "raw" / f"{identifier}.json"
        if (done / f"{identifier}.json").exists() or not raw_path.exists():
            continue
        raw = read_json(raw_path)
        if not raw["wiktionary"]["senses"]:
            continue
        quotes_path = work / "quotes" / f"{identifier}.json"
        pending.append((identifier, raw, read_json(quotes_path) if quotes_path.exists() else []))
    return pending


def draft_instructions(seeds: list[dict[str, Any]]) -> str:
    examples = {}
    for fiche in seeds:
        examples.setdefault(fiche["family"], fiche)
    return f"""# Rédaction des fiches Sagace (étape 4, sans API)

{draft.RULES}

## Ce que tu fais, pour chaque fichier `in/<id>.json` qui t'est confié
1. Lis les extraits (`extracts`) et les phrases candidates (`quotes`).
2. Rédige la fiche, en t'appuyant uniquement sur ces extraits.
3. Écris l'objet JSON seul, sans texte autour, dans `out/<id>.json` (même nom de fichier).

Précisions :
- `synonyms` : seulement des mots donnés par les extraits (synonymes du Wiktionnaire, mots liés), sinon une liste vide.
- Les exemples du Wiktionnaire (`examples`, avec leur source) montrent les constructions courantes ; ne les recopie pas dans `examples`, qui reste 2 phrases du quotidien moderne.
- `level` et `frequencyRank` viennent de Lexique : ils seront remplacés à l'import.
- Phrase d'auteur : préfère un auteur de langue française à une traduction, et une phrase qui se comprend seule ; null plutôt qu'une phrase où le mot n'a pas le sens de la fiche.

Les champs `id`, `language`, `headword`, `family`, `sources` et `reviewStatus` seront remplacés par ceux des extraits : remplis les quand même. `authorQuote` : recopie exactement une des candidates (texte, auteur, œuvre, année, url), ou null.

## Schéma JSON d'une fiche
```json
{json.dumps(read_json(SCHEMA_PATH), ensure_ascii=False, indent=1)}
```

## Fiches validées, une par famille (le ton et le niveau de détail attendus)
```json
{json.dumps(list(examples.values()), ensure_ascii=False, indent=1)}
```
"""


def critic_instructions() -> str:
    return f"""# Relecture des fiches Sagace (étape 6, sans API)

{critic.PROMPT}

## Ce que tu fais, pour chaque fichier `in/<id>.json` qui t'est confié
1. Compare la fiche (`fiche`) aux extraits sources (`extracts`), point par point.
2. Écris le rapport JSON seul dans `out/<id>.json` : {json.dumps(critic.SCHEMA, ensure_ascii=False)}

Sois exigeant : en cas de doute sur un point de fond (sens, règle, verdict, bonne réponse d'un quiz), c'est « bloquant ».
"""


def export(step: str, work: Path = WORK, limit: int | None = None, seeds_path: Path = SEED_PATH) -> list[str]:
    root, inputs, outputs = folders(step, work)
    identifiers = []
    if step == "draft":
        (root / "CONSIGNES.md").write_text(draft_instructions(read_json(seeds_path)), encoding="utf-8")
        for identifier, raw, quotes in draft_pending(work, limit):
            extracts = {key: raw[key] for key in ("headword", "family", "note", "lexique", "wiktionary", "related", "littre", "lafaye")}
            write_json(inputs / f"{identifier}.json", {"id": identifier, "extracts": extracts, "quotes": quotes})
            identifiers.append(identifier)
    else:
        (root / "CONSIGNES.md").write_text(critic_instructions(), encoding="utf-8")
        for path in sorted((work / "checked").glob("*.json")):
            if (work / "critic" / path.name).exists():
                continue
            write_json(inputs / path.name, {"id": path.stem, "fiche": read_json(path), "extracts": read_json(work / "raw" / path.name)})
            identifiers.append(path.stem)
    pending = [identifier for identifier in identifiers if not (outputs / f"{identifier}.json").exists()]
    print(f"{len(pending)} fiches à traiter : consignes {root / 'CONSIGNES.md'}, entrées {inputs}, réponses attendues dans {outputs}")
    return pending


def import_outputs(step: str, work: Path = WORK) -> tuple[int, list[str]]:
    """Range les réponses des agents ; une réponse illisible est signalée et laissée en place pour être refaite."""
    _, inputs, outputs = folders(step, work)
    imported, failures = 0, []
    for path in sorted(outputs.glob("*.json")):
        source = inputs / path.name
        if not source.exists():
            failures.append(f"{path.stem} : pas d'entrée correspondante")
            continue
        try:
            answer = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            failures.append(f"{path.stem} : JSON illisible ({error})")
            continue
        entry = read_json(source)
        if step == "draft":
            if not isinstance(answer, dict):
                failures.append(f"{path.stem} : la réponse n'est pas un objet")
                continue
            raw = read_json(work / "raw" / path.name)
            write_json(stage_dir("drafts", work) / path.name, draft.finalize(answer, raw, entry["quotes"]))
        else:
            if not isinstance(answer, dict) or not isinstance(answer.get("ok"), bool) or not isinstance(answer.get("problems"), list):
                failures.append(f"{path.stem} : rapport incomplet (ok, problems)")
                continue
            write_json(stage_dir("critic", work) / path.name, answer)
        imported += 1
    print(f"{imported} réponses rangées ({'work/drafts' if step == 'draft' else 'work/critic'})")
    for failure in failures:
        print("  à refaire", failure)
    return imported, failures
