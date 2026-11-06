"""Pack anglais historique (option A de `04_MIGRATION.md`, `05_CONTENT.md` section 5).

Lit `content/legacy/v3_words.json` (le `Data/words.json` de Words v3) et écrit `content/en/fiches.json` au format
`Fiche` : famille `motMalCompris`, un quiz Sens généré depuis les définitions des mots du même thème.
La v3 ne donne ni nature, ni prononciation, ni genre : `partOfSpeech = inconnu`, `phonetic` vide, rien n'est inventé.
"""
from __future__ import annotations

import random
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

import json

from .common import EN_PACK_PATH, LEGACY_EN, SHORT_DEFINITION_MAX, fiche_id, fold, read_json

SOURCE = {"name": "Words (v3)", "url": ""}


def short_definition(headword: str, definition: str) -> str:
    """« Otiose refers to something that is useless… » → « Something that is useless… », 90 caractères au plus."""
    text = re.sub(r"\s+", " ", definition).strip()
    text = re.sub(rf"^(?:the (?:word |term )?)?['\"]?{re.escape(headword)}['\"]?\s+(?:refers to|means|is|describes|denotes)\s+", "", text, flags=re.I)
    text = text.rstrip(". ")
    text = text[:1].upper() + text[1:]
    if len(text) > SHORT_DEFINITION_MAX:
        text = text[:SHORT_DEFINITION_MAX - 1].rsplit(" ", 1)[0].rstrip(",;:") + "…"
    return text


def marked_example(headword: str, sentence: str) -> str | None:
    """La phrase de contexte, le mot (ou une forme qui le prolonge : hemisphere → hemispheres) entre ** **."""
    sentence = sentence.strip()
    if not sentence:
        return None
    match = re.search(rf"\b{re.escape(headword)}\w*", sentence, flags=re.I)
    if match is None:
        return None
    return f"{sentence[:match.start()]}**{match.group(0)}**{sentence[match.end():]}"


def level(list_name: str) -> int:
    match = re.match(r"(\d+)k", list_name)
    if match is None:
        return 3
    thousands = int(match.group(1))
    for value, limit in ((1, 2), (2, 5), (3, 10), (4, 17)):
        if thousands <= limit:
            return value
    return 5


def words(text: str) -> list[str]:
    return [word.strip(" .").lower() for word in text.split(",") if word.strip(" .")]


def convert(entries: list[dict[str, str]], seed: int = 3) -> list[dict[str, Any]]:
    rng = random.Random(seed)
    used: set[str] = set()
    fiches = []
    for entry in entries:
        headword = entry["Headword"].strip()
        definition = re.sub(r"\s+", " ", entry["Definition"]).strip()
        if not headword or len(definition) < 5:
            continue
        identifier = base = fiche_id("en", headword)
        suffix = 2
        while identifier in used:
            identifier, suffix = f"{base}_{suffix}", suffix + 1
        used.add(identifier)
        example = marked_example(headword, entry.get("Context sentence", ""))
        fiches.append({
            "id": identifier, "language": "en", "headword": headword, "family": "motMalCompris",
            "themes": [entry["Topic"].strip()] if entry.get("Topic") else [], "partOfSpeech": "inconnu", "gender": None,
            "register": "courant", "phonetic": "", "shortDefinition": short_definition(headword, definition),
            "definition": definition if definition.endswith(".") else definition + ".", "confusions": [], "usage": None,
            "nuance": None, "examples": [example] if example else [], "authorQuote": None, "synonyms": words(entry.get("Synonyms", "")),
            "etymology": None, "level": level(entry.get("List", "")), "frequencyRank": int(entry["Rank"]) if entry.get("Rank", "").isdigit() else None,
            "quiz": [], "sources": [SOURCE], "reviewStatus": "autoChecked",
        })
    # Quiz : mauvaises réponses tirées du même thème (sinon de tout le pack), jamais un synonyme.
    by_theme: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for fiche in fiches:
        by_theme[(fiche["themes"] or [""])[0]].append(fiche)
    for fiche in fiches:
        pool = by_theme[(fiche["themes"] or [""])[0]]
        pool = pool if len(pool) > 10 else fiches
        forbidden = {fold(fiche["headword"]), *map(fold, fiche["synonyms"])}
        others: list[dict[str, Any]] = []
        while len(others) < 2:
            other = rng.choice(pool)
            if fold(other["headword"]) not in forbidden and other["shortDefinition"] != fiche["shortDefinition"] and other not in others:
                others.append(other)
        # Un quiz Sens suffit dans le pack : les autres questions sont générées par l'app (QuestionFactory).
        choices = [fiche["shortDefinition"], *(other["shortDefinition"] for other in others)]
        rng.shuffle(choices)
        fiche["quiz"].append({"game": "sens", "prompt": fiche["headword"], "choices": choices,
                              "answerIndex": choices.index(fiche["shortDefinition"]), "explanation": ""})
    return fiches


def run(source: Path = LEGACY_EN, out: Path = EN_PACK_PATH) -> Path:
    entries = read_json(source)
    fiches = convert(entries)
    # JSON compact : ~25 000 fiches embarquées dans l'app.
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(fiches, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    with_example = sum(bool(fiche["examples"]) for fiche in fiches)
    print(f"{len(fiches)}/{len(entries)} fiches anglaises → {out} ({with_example} avec exemple)")
    return out
