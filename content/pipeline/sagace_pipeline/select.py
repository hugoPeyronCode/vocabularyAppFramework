"""Étape 1 : sélection des candidats → `work/candidats.csv`.

Recherches du Wiktionnaire par famille (`content/fr/listes/selection.json`) et liste éditoriale d'Hugo
(`content/fr/listes/editorial.csv`), croisées avec Lexique 3 : mots courants seulement, quotas par famille.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Callable

from . import web
from .common import (CANDIDATE_RATIO, FAMILIES, LAUNCH_VOLUMES, LISTS, MAX_RANK, MAX_RANK_PARONYM, WORK, fiche_id,
                     read_csv, read_json, write_csv)
from .lexique import Lexique

FIELDS = ["id", "headword", "family", "partOfSpeech", "rank", "origin", "note"]
# Recherches automatiques : mots pleins d'au moins 4 lettres (« de », « ne », « à » ont aussi une section paronymes).
CONTENT_WORDS = {"nom", "verbe", "adjectif", "adverbe"}
MIN_LETTERS = 4


def search_titles(query: str, limit: int = 10_000) -> list[str]:
    titles: list[str] = []
    params: dict[str, Any] = {"action": "query", "list": "search", "srsearch": query, "srnamespace": 0, "srlimit": 500, "srwhat": "text"}
    while len(titles) < limit:
        data = web.get_json(web.WIKTIONARY, params)
        titles += [hit["title"] for hit in data.get("query", {}).get("search", [])]
        if "continue" not in data:
            break
        params = {**params, **data["continue"]}
    return titles


def annex_pairs(title: str) -> list[tuple[str, str]]:
    text = web.page_wikitext(web.WIKTIONARY, title) or ""
    pairs = []
    for line in text.splitlines():
        words = re.findall(r"\[\[([^|\]]+)", line)
        if line.startswith("*") and len(words) == 2:
            pairs.append((words[0], words[1]))
    return pairs


def select(lexique: Lexique, config: dict, editorial: list[dict[str, str]],
           search: Callable[[str], list[str]] = search_titles,
           annexes: Callable[[str], list[tuple[str, str]]] = annex_pairs) -> list[dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}

    def add(headword: str, family: str, origin: str, note: str = "", max_rank: int = MAX_RANK) -> None:
        lemma = lexique.best(headword)
        # Mot absent de Lexique (locution, mot rare ou récent) : retenu seulement si la liste éditoriale le donne.
        if lemma is None and origin != "editorial":
            return
        if lemma is not None and lemma.rank > max_rank:
            return
        if origin != "editorial" and (lemma is None or lemma.part_of_speech not in CONTENT_WORDS or len(headword) < MIN_LETTERS):
            return
        identifier = fiche_id("fr", headword)
        if identifier in rows:
            return
        rows[identifier] = {"id": identifier, "headword": headword, "family": family,
                            "partOfSpeech": lemma.part_of_speech if lemma else ("locution" if " " in headword else ""),
                            "rank": lemma.rank if lemma else "", "origin": origin, "note": note}

    for row in editorial:
        if row.get("family") in FAMILIES and row.get("headword"):
            add(row["headword"].strip(), row["family"], "editorial", row.get("note", ""), max_rank=10**9)
    for family in FAMILIES:
        settings = config.get(family, {})
        for title in settings.get("annexes", []):
            for first, second in annexes(title):
                if (lexique.rank(first) or 10**9) <= MAX_RANK_PARONYM and (lexique.rank(second) or 10**9) <= MAX_RANK_PARONYM:
                    add(first, family, f"annexe:{title}", f"paronyme de {second}", MAX_RANK_PARONYM)
        for verb in settings.get("verbs", []):
            add(verb, family, "verbes passe-partout")
        for query in settings.get("search", []):
            for title in search(query):
                add(title, family, f"recherche:{query}", max_rank=MAX_RANK_PARONYM if family == "paronyme" else MAX_RANK)

    # Quotas : 1,5 candidat par fiche visée, les plus fréquents d'abord, liste éditoriale toujours gardée.
    # La liste éditoriale passe en tête, toutes familles : un lot test (`--limit 200`) la prend en premier.
    selected: list[dict[str, Any]] = []
    for family in FAMILIES:
        quota = round(LAUNCH_VOLUMES[family] * CANDIDATE_RATIO)
        members = sorted((row for row in rows.values() if row["family"] == family),
                         key=lambda row: (row["origin"] != "editorial", row["rank"] or 0))
        selected += members[:max(quota, sum(row["origin"] == "editorial" for row in members))]
    return sorted(selected, key=lambda row: row["origin"] != "editorial")


def run(lexique_path: Path, work: Path = WORK) -> Path:
    lexique = Lexique.load(lexique_path)
    rows = select(lexique, read_json(LISTS / "selection.json"), read_csv(LISTS / "editorial.csv"))
    out = work / "candidats.csv"
    write_csv(out, rows, FIELDS)
    counts = {family: sum(row["family"] == family for row in rows) for family in FAMILIES}
    print(f"{len(rows)} candidats → {out}")
    for family, count in counts.items():
        print(f"  {family:14} {count:5} (quota {round(LAUNCH_VOLUMES[family] * CANDIDATE_RATIO)})")
    return out
