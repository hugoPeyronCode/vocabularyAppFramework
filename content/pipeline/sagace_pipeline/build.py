"""Étape 8 : pack de l'app → `content/fr/fiches.json` (fiches `autoChecked` et `humanChecked` seulement),
version incrémentée dans `content/fr/fiches.version`.

Une fiche signalée par critic n'entre que relue (validée ou corrigée) ; une fiche rejetée n'entre jamais.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

from .check import schema_errors
from .common import FAMILIES, LAUNCH_VOLUMES, LEVEL_SHARES, PACK_PATH, PACK_VERSION_PATH, SCHEMA_PATH, WORK, read_csv, read_json, write_json
from .critic import is_flagged


def assemble(work: Path) -> list[dict[str, Any]]:
    decisions = {row["id"]: row["action"] for row in read_csv(work / "review" / "decisions.csv")}
    fiches: dict[str, dict[str, Any]] = {}
    for path in sorted((work / "checked").glob("*.json")):
        identifier = path.stem
        critic_path = work / "critic" / path.name
        flagged = critic_path.exists() and is_flagged(read_json(critic_path))
        reviewed = work / "reviewed" / path.name
        if decisions.get(identifier) == "rejeter":
            continue
        if reviewed.exists():
            fiches[identifier] = read_json(reviewed)
        elif not flagged:
            fiches[identifier] = read_json(path)
    return sorted(fiches.values(), key=lambda fiche: (FAMILIES.index(fiche["family"]), fiche["id"]))


def run(work: Path = WORK, out: Path = PACK_PATH, version_path: Path = PACK_VERSION_PATH) -> Path:
    schema = read_json(SCHEMA_PATH)
    fiches = assemble(work)
    invalid = {fiche["id"]: errors for fiche in fiches if (errors := schema_errors(fiche, schema))}
    if invalid:
        for identifier, errors in invalid.items():
            print(f"  invalide {identifier} : {errors[0]}")
        raise SystemExit("Pack non écrit : fiches non conformes au schéma.")
    write_json(out, fiches)
    version = int(version_path.read_text().strip()) + 1 if version_path.exists() else 1
    version_path.write_text(f"{version}\n")
    statuses = Counter(fiche["reviewStatus"] for fiche in fiches)
    print(f"Pack v{version} : {len(fiches)} fiches ({statuses['humanChecked']} humanChecked, {statuses['autoChecked']} autoChecked) → {out}")
    families = Counter(fiche["family"] for fiche in fiches)
    for family in FAMILIES:
        print(f"  {family:14} {families[family]:5} / {LAUNCH_VOLUMES[family]}")
    levels = Counter(fiche["level"] for fiche in fiches)
    print("  niveaux : " + ", ".join(f"{level} : {levels[level]} ({levels[level] / max(len(fiches), 1):.0%}, visé {share:.0%})" for level, share in LEVEL_SHARES.items()))
    return out
