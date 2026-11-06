"""Étape 5 : contrôles automatiques bloquants (`05_CONTENT.md` section 3.4) → `work/checked/<id>.json`
(statut `autoChecked`) et `work/rapport_check.csv`.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from . import schema as schema_module
from .common import (LISTS, SCHEMA_PATH, SHORT_DEFINITION_MAX, WORK, contains_form, fold, read_json, stage_dir,
                     word_forms, write_csv, write_json)


def sensitive_words(path: Path = LISTS / "sensibles.txt") -> set[str]:
    if not path.exists():
        return set()
    return {fold(line.strip()) for line in path.read_text(encoding="utf-8").splitlines() if line.strip() and not line.startswith("#")}


def schema_errors(fiche: dict[str, Any], schema: dict[str, Any]) -> list[str]:
    return [f"schéma : {error}" for error in schema_module.errors(fiche, schema)]


def check(fiche: dict[str, Any], raw: dict[str, Any], schema: dict[str, Any], sensitive: set[str],
          lexique_pos: dict[str, str] | None = None) -> list[str]:
    problems = schema_errors(fiche, schema)
    if problems:
        return problems
    lexique = raw.get("lexique") or {}
    senses = raw["wiktionary"]["senses"]
    # 2. Nature et genre identiques à Lexique et au Wiktionnaire.
    if lexique and fiche["partOfSpeech"] != lexique["partOfSpeech"]:
        problems.append(f"nature : {fiche['partOfSpeech']} ≠ Lexique {lexique['partOfSpeech']}")
    if senses and fiche["partOfSpeech"] not in {sense["part_of_speech"] for sense in senses}:
        problems.append(f"nature : {fiche['partOfSpeech']} absente du Wiktionnaire")
    if fiche["partOfSpeech"] == "nom":
        genders = {lexique.get("gender")} | {sense["gender"] for sense in senses if sense["part_of_speech"] == "nom"}
        genders.discard(None)
        if genders and fiche.get("gender") not in genders | {"epicene"}:
            problems.append(f"genre : {fiche.get('gender')} ≠ sources {sorted(genders)}")
    # 3. Le mot (ou une forme fléchie) dans chaque exemple et dans la phrase d'auteur.
    forms = word_forms(fiche["headword"], lexique.get("forms", []))
    for example in fiche["examples"]:
        bold = re.findall(r"\*\*(.+?)\*\*", example)
        if not bold or not any(contains_form(part, forms) or fold(part).startswith(fold(fiche["headword"])[:4]) for part in bold):
            problems.append(f"exemple sans le mot en gras : {example}")
    quote = fiche.get("authorQuote")
    if quote and not contains_form(quote["text"], forms):
        problems.append("phrase d'auteur sans le mot")
    # 4. Définition courte.
    short = fiche["shortDefinition"]
    if len(short) > SHORT_DEFINITION_MAX or short.endswith("."):
        problems.append("shortDefinition : 90 caractères au plus, sans point final")
    # 5. Quiz : jamais un synonyme en mauvaise réponse ; même nature (et genre pour un nom) que la bonne.
    synonyms = {fold(word) for word in fiche["synonyms"]}
    for index, item in enumerate(fiche["quiz"]):
        if item["answerIndex"] >= len(item["choices"]):
            problems.append(f"quiz[{index}] : answerIndex hors des choix")
            continue
        wrong = [choice for position, choice in enumerate(item["choices"]) if position != item["answerIndex"]]
        if any(fold(choice) in synonyms for choice in wrong):
            problems.append(f"quiz[{index}] : un synonyme est proposé comme mauvaise réponse")
        if lexique_pos and item["game"] != "justeOuFautif":
            right = item["choices"][item["answerIndex"]]
            natures = {lexique_pos.get(fold(choice)) for choice in [right, *wrong] if " " not in choice}
            natures.discard(None)
            if len(natures) > 1:
                problems.append(f"quiz[{index}] : choix de natures différentes {sorted(natures)}")
    # 7. Au moins une source avec URL.
    if not any(source.get("url", "").startswith("http") for source in fiche["sources"]):
        problems.append("aucune source avec URL")
    # 8. Mots sensibles (rejet pour la v4).
    texts = [fiche["headword"], *fiche["examples"], (quote or {}).get("text", "")]
    if sensitive and any(contains_form(text, {fold(word) for word in sensitive}) for text in texts):
        problems.append("mot sensible")
    return problems


def run(work: Path = WORK, lexique_path: Path | None = None) -> None:
    schema = read_json(SCHEMA_PATH)
    sensitive = sensitive_words()
    lexique_pos = None
    if lexique_path:
        from .lexique import Lexique
        lexique_pos = {}
        for (word, pos), _ in Lexique.load(lexique_path).lemmas.items():
            lexique_pos.setdefault(fold(word), pos)
    out = stage_dir("checked", work)
    rows, seen_ids, seen_words = [], set(), set()
    for path in sorted((work / "drafts").glob("*.json")):
        fiche = read_json(path)
        raw = read_json(work / "raw" / path.name)
        problems = check(fiche, raw, schema, sensitive, lexique_pos)
        # 6. Pas de doublon d'id ni de mot dans une même famille.
        key = (fiche.get("family"), fold(fiche.get("headword", "")))
        if fiche.get("id") in seen_ids or key in seen_words:
            problems.append("doublon")
        seen_ids.add(fiche.get("id"))
        seen_words.add(key)
        if problems:
            (out / path.name).unlink(missing_ok=True)
        else:
            write_json(out / path.name, {**fiche, "reviewStatus": "autoChecked"})
        rows.append({"id": fiche.get("id"), "statut": "rejet" if problems else "autoChecked", "raisons": " | ".join(problems)})
    write_csv(work / "rapport_check.csv", rows, ["id", "statut", "raisons"])
    passed = sum(row["statut"] == "autoChecked" for row in rows)
    print(f"{passed}/{len(rows)} fiches autoChecked → {out} (rapport : rapport_check.csv)")
