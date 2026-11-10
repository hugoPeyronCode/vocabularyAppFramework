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
          lexique_pos: dict[str, str | set[str]] | None = None) -> list[str]:
    problems = schema_errors(fiche, schema)
    if problems:
        return problems
    lexique = raw.get("lexique") or {}
    senses = raw["wiktionary"]["senses"]
    # 2. Nature et genre identiques à Lexique et au Wiktionnaire.
    # Toutes les natures du mot dans Lexique (« car » : conjonction et nom), pas seulement la plus fréquente.
    natures = lexique_pos.get(fold(fiche["headword"])) if lexique_pos else None
    lexique_natures = ({natures} if isinstance(natures, str) else set(natures or ())) or ({lexique["partOfSpeech"]} if lexique else set())
    # Le schéma range conjonctions et pronoms avec les locutions : Lexique ne les décrit pas.
    if lexique_natures and fiche["partOfSpeech"] not in lexique_natures and fiche["partOfSpeech"] != "locution":
        problems.append(f"nature : {fiche['partOfSpeech']} ≠ Lexique {sorted(lexique_natures)}")
    # Une expression (plusieurs mots) est rangée en locution, quelle que soit sa nature au Wiktionnaire.
    is_phrase = " " in fiche["headword"].strip()
    if senses and not (is_phrase and fiche["partOfSpeech"] == "locution") \
            and fiche["partOfSpeech"] not in {sense["part_of_speech"] for sense in senses}:
        problems.append(f"nature : {fiche['partOfSpeech']} absente du Wiktionnaire")
    if fiche["partOfSpeech"] == "nom":
        genders = {lexique.get("gender")} | {sense["gender"] for sense in senses if sense["part_of_speech"] == "nom"}
        genders.discard(None)
        if genders and fiche.get("gender") not in genders | {"epicene"}:
            problems.append(f"genre : {fiche.get('gender')} ≠ sources {sorted(genders)}")
    # 3. Le mot (ou une forme fléchie) dans chaque exemple et dans la phrase d'auteur.
    forms = word_forms(fiche["headword"], lexique.get("forms", []))
    # Expression conjuguée (« fait florès », « à mon corps défendant ») : la moitié au moins de ses mots pleins. Le
    # possessif et le pronom réfléchi varient (« prendre son parti » → « j'en ai pris mon parti »), un verbe se conjugue
    # (« faire fi de » → « fait fi des », « se rappeler » → « rappelle ») : radical de trois lettres pour un mot de quatre.
    variable = {"se", "son", "sa", "ses", "leur", "leurs"}
    words = [word for word in re.findall(r"[\w-]+", fold(fiche["headword"])) if len(word) > 2 and word not in variable]
    def shows_phrase(part: str) -> bool:
        present = set(re.findall(r"[\w-]+", fold(part)))
        found = sum(word in present or (len(word) >= 4 and any(other.startswith(word[:3]) for other in present)) for word in words)
        return bool(words) and found * 2 >= len(words)
    # Tournure sans emploi correct (« suite à ») : les exemples montrent la forme recommandée, celle de usage.correct ou
    # un synonyme, fléchie (« anxieuse » → « anxieux ») : radical de quatre lettres (OPEN_QUESTIONS n° 91).
    usage = fiche.get("usage") or {}
    recommended = set()
    if fiche["family"] in ("impropriete", "anglicisme") and usage.get("verdict") in ("fautif", "critique"):
        recommended = {word[:4] for text in [usage.get("correct") or "", *fiche["synonyms"]]
                       for word in re.findall(r"[\w-]+", fold(text)) if len(word) >= 3}
    def shows_recommended(part: str) -> bool:
        # « vous porter candidat », « sont insupportables » : un mot plein suffit.
        return any(word[:4].startswith(prefix) or prefix.startswith(word[:4])
                   for word in re.findall(r"[\w-]+", fold(part)) if len(word) >= 3 for prefix in recommended)
    for example in fiche["examples"]:
        bold = re.findall(r"\*\*(.+?)\*\*", example)
        if not bold or not any(contains_form(part, forms) or fold(part).startswith(fold(fiche["headword"])[:4])
                               or (is_phrase and shows_phrase(part)) or shows_recommended(part)
                               for part in bold):
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
        # Paronymes : les choix diffèrent souvent de nature (différend, nom / différent, adjectif).
        if lexique_pos and item["game"] not in ("justeOuFautif", "paronymes"):
            right = item["choices"][item["answerIndex"]]
            # Une forme peut avoir plusieurs natures (« accompli » : verbe et adjectif) : il faut une nature commune.
            known = [lexique_pos[fold(choice)] for choice in [right, *wrong] if " " not in choice and fold(choice) in lexique_pos]
            sets = [{value} if isinstance(value, str) else set(value) for value in known]
            if len(sets) > 1 and not set.intersection(*sets):
                problems.append(f"quiz[{index}] : choix de natures différentes {sorted(set.union(*sets))}")
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
        for (word, pos), lemma in Lexique.load(lexique_path).lemmas.items():
            for form in {word, *lemma.forms}:
                lexique_pos.setdefault(fold(form), set()).add(pos)
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
