"""Étape 6 : seconde passe de Claude, en correcteur (`05_CONTENT.md` section 3.5) → `work/critic/<id>.json`
et `work/rapport_critic.csv`. Toute fiche avec un problème bloquant part en relecture humaine.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import llm
from .common import WORK, read_json, stage_dir, write_csv, write_json

PROMPT = """Tu es correcteur exigeant pour un dictionnaire d'usage du français.
Vérifie la fiche ci-dessous contre les extraits sources, point par point :
1. La définition est-elle fidèle aux sources ? 2. La règle d'usage et le verdict sont-ils justifiés par les sources ?
3. Chaque exemple est-il correct, naturel, et emploie-t-il le mot dans le bon sens ? 4. La phrase d'auteur emploie-t-elle le mot dans le sens de la fiche ?
5. Chaque question de quiz a-t-elle une seule bonne réponse indiscutable ? 6. Y a-t-il une faute de langue dans la fiche ?
Convention de Sagace, à ne pas signaler : dans les quiz, un emploi de verdict « critique » compte comme fautif (réponse « Fautif », ou mauvaise réponse), comme un emploi « fautif ». Signale en revanche un verdict que les sources ne justifient pas, ou une question Juste ou fautif sur un emploi « tolere ».
Réponds en JSON : { "ok": bool, "problems": [ { "field": "...", "issue": "...", "severity": "bloquant|mineur" } ] }."""

SCHEMA = {
    "type": "object", "additionalProperties": False, "required": ["ok", "problems"],
    "properties": {
        "ok": {"type": "boolean"},
        "problems": {"type": "array", "items": {
            "type": "object", "additionalProperties": False, "required": ["field", "issue", "severity"],
            "properties": {"field": {"type": "string"}, "issue": {"type": "string"}, "severity": {"enum": ["bloquant", "mineur"]}},
        }},
    },
}


def is_flagged(report: dict[str, Any]) -> bool:
    return not report["ok"] or any(problem["severity"] == "bloquant" for problem in report["problems"])


def run(work: Path = WORK, sync: bool = False, confirm: bool = False) -> None:
    out = stage_dir("critic", work)
    system = [{"type": "text", "text": PROMPT, "cache_control": {"type": "ephemeral"}}]
    requests = []
    for path in sorted((work / "checked").glob("*.json")):
        if (out / path.name).exists():
            continue
        fiche, raw = read_json(path), read_json(work / "raw" / path.name)
        user = f"Fiche : {json.dumps(fiche, ensure_ascii=False)}\nExtraits : {json.dumps(raw, ensure_ascii=False)}"
        requests.append({"custom_id": fiche["id"], "params": llm.params(system, user, SCHEMA)})
    print(llm.estimate(requests, batch=not sync))
    if confirm and requests:
        for result in llm.run_sync(requests) if sync else llm.run_batch(requests):
            report = json.loads(result.text) if result.text else {"ok": False, "problems": [{"field": "critic", "issue": result.error, "severity": "bloquant"}]}
            write_json(out / f"{result.custom_id}.json", report)
    elif not confirm:
        print("Rien n'est envoyé sans --confirm.")
    write_report(work)


def write_report(work: Path = WORK) -> None:
    out = stage_dir("critic", work)
    rows = []
    for path in sorted(out.glob("*.json")):
        report = read_json(path)
        rows.append({"id": path.stem, "ok": report["ok"],
                     "bloquants": sum(p["severity"] == "bloquant" for p in report["problems"]),
                     "mineurs": sum(p["severity"] == "mineur" for p in report["problems"]),
                     "details": " | ".join(f"[{p['severity']}] {p['field']} : {p['issue']}" for p in report["problems"])})
    write_csv(work / "rapport_critic.csv", rows, ["id", "ok", "bloquants", "mineurs", "details"])
    print(f"{sum(1 for row in rows if row['bloquants'] or not row['ok'])}/{len(rows)} fiches signalées (rapport_critic.csv)")
