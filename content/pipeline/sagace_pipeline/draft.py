"""Étape 4 : rédaction des fiches par Claude, ancrée sur les extraits → `work/drafts/<id>.json`.

Prompt de `05_CONTENT.md` section 3.3. Les champs sûrs (id, langue, mot, famille, sources, statut) viennent des
extraits, pas du modèle ; la phrase d'auteur n'est gardée que si elle est l'une des candidates.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import llm
from .common import SCHEMA_PATH, SEED_PATH, WORK, read_csv, read_json, stage_dir, write_json

RULES = """Tu rédiges une fiche pour Sagace, une app qui aide des francophones adultes à employer le mot juste au quotidien.
Règles :
- Tu n'utilises QUE les informations des extraits fournis (Wiktionnaire, Littré, Lafaye, Lexique). Tu n'inventes aucun sens, aucune règle, aucune étymologie. Si une information manque, mets null.
- Ton : clair, précis, bienveillant, jamais scolaire ni moralisateur.
- Verdict : "fautif" seulement si les sources parlent d'erreur ; "critique" si l'emploi est condamné par l'Académie ou des grammairiens mais répandu ; "tolere" si l'emploi est correct mais moins précis.
- shortDefinition : 90 caractères maximum, sans point final.
- examples : 2 phrases du quotidien moderne (travail, mails, vie courante), le mot entre ** **.
- quiz : 2 questions dont la bonne réponse est indiscutable selon les sources ; les mauvaises réponses ne doivent jamais être correctes dans la phrase ; mêmes nature et genre que la bonne réponse.
- Choisis la meilleure phrase d'auteur parmi les candidates fournies, ou null si aucune n'emploie le mot dans ce sens.
Réponds uniquement par un objet JSON conforme au schéma fourni."""


def system_blocks(family: str, seeds: list[dict[str, Any]], schema: dict[str, Any]) -> list[dict[str, Any]]:
    """Règles et schéma (communs), puis 3 fiches modèles de la famille : deux préfixes stables, mis en cache."""
    examples = [fiche for fiche in seeds if fiche["family"] == family][:3] or seeds[:3]
    return [
        {"type": "text", "text": f"{RULES}\n\nSchéma : {json.dumps(schema, ensure_ascii=False)}", "cache_control": {"type": "ephemeral"}},
        {"type": "text", "text": "Exemples de fiches validées : " + json.dumps(examples, ensure_ascii=False), "cache_control": {"type": "ephemeral"}},
    ]


def user_prompt(raw: dict[str, Any], quotes: list[dict[str, Any]]) -> str:
    extracts = {key: raw[key] for key in ("headword", "family", "note", "lexique", "wiktionary", "related", "littre", "lafaye")}
    return f"Extraits : {json.dumps(extracts, ensure_ascii=False)}\nPhrases candidates : {json.dumps(quotes, ensure_ascii=False)}"


def finalize(draft: dict[str, Any], raw: dict[str, Any], quotes: list[dict[str, Any]]) -> dict[str, Any]:
    fiche = {**draft, "id": raw["id"], "language": "fr", "headword": raw["headword"], "family": raw["family"],
             "sources": raw["sources"], "reviewStatus": "draft"}
    quote = fiche.get("authorQuote")
    candidates = {candidate["text"]: candidate for candidate in quotes}
    fiche["authorQuote"] = candidates.get(quote["text"]) if quote else None
    lexique = raw.get("lexique") or {}
    fiche["frequencyRank"] = lexique.get("rank")
    # Niveau de Lexique 3 (fréquence), comme l'identifiant : pas laissé au rédacteur.
    if lexique.get("level"):
        fiche["level"] = lexique["level"]
    return fiche


def run(work: Path = WORK, limit: int | None = None, sync: bool = False, confirm: bool = False, seeds_path: Path = SEED_PATH) -> None:
    schema = llm.structured_schema(read_json(SCHEMA_PATH))
    seeds = read_json(seeds_path)
    out = stage_dir("drafts", work)
    requests, context = [], {}
    for candidate in read_csv(work / "candidats.csv")[:limit]:
        identifier = candidate["id"]
        raw_path = work / "raw" / f"{identifier}.json"
        if (out / f"{identifier}.json").exists() or not raw_path.exists():
            continue
        raw = read_json(raw_path)
        if not raw["wiktionary"]["senses"]:
            continue
        quotes_path = work / "quotes" / f"{identifier}.json"
        quotes = read_json(quotes_path) if quotes_path.exists() else []
        context[identifier] = (raw, quotes)
        requests.append({"custom_id": identifier, "params": llm.params(system_blocks(raw["family"], seeds, schema), user_prompt(raw, quotes), schema)})
    print(llm.estimate(requests, batch=not sync))
    if not confirm or not requests:
        print("Rien n'est envoyé sans --confirm.")
        return
    results = llm.run_sync(requests) if sync else llm.run_batch(requests)
    failures = []
    for result in results:
        if result.text is None:
            failures.append(f"{result.custom_id} : {result.error}")
            continue
        raw, quotes = context[result.custom_id]
        write_json(out / f"{result.custom_id}.json", finalize(json.loads(result.text), raw, quotes))
    print(f"{len(results) - len(failures)} brouillons → {out}")
    for failure in failures:
        print("  échec", failure)
