"""Étape 2 : extraits bruts par candidat → `work/raw/<id>.json`.

Wiktionnaire (API, mis en cache), Lexique 3, et si fournis : Littré (XMLittré, dossier de fichiers XML)
et Lafaye (texte brut du *Dictionnaire des synonymes*, Wikisource ou Internet Archive).
"""
from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Callable

from . import web, wiktionary
from .common import MAX_RANK_PARONYM, WORK, fold, read_csv, read_json, stage_dir, write_json
from .lexique import Lexique

WIKTIONARY_SITE = "https://fr.wiktionary.org"


class Littre:
    """Index terme → texte des articles de XMLittré (`<entree terme="...">`)."""

    def __init__(self, folder: Path | None):
        self.index: dict[str, list[str]] = {}
        if folder is None:
            return
        for path in sorted(folder.glob("*.xml")):
            for _, element in ET.iterparse(path, events=("end",)):
                if element.tag == "entree" and element.get("terme"):
                    text = re.sub(r"\s+", " ", "".join(element.itertext())).strip()
                    self.index.setdefault(fold(element.get("terme")), []).append(text[:4_000])
                    element.clear()

    def lookup(self, headword: str) -> list[str]:
        return self.index.get(fold(headword), [])


class Lafaye:
    """Articles du Lafaye : paragraphes dont l'en-tête (en capitales) cite le mot."""

    def __init__(self, path: Path | None):
        self.paragraphs = [] if path is None else [p.strip() for p in path.read_text(encoding="utf-8").split("\n\n") if p.strip()]

    def lookup(self, headword: str) -> list[str]:
        target = fold(headword)
        found = []
        for paragraph in self.paragraphs:
            header = fold(paragraph[:120])
            if re.search(rf"\b{re.escape(target)}\b", header) and paragraph[:40].upper() == paragraph[:40]:
                found.append(paragraph[:3_000])
        return found[:3]


def gather_one(candidate: dict[str, str], lexique: Lexique, littre: Littre, lafaye: Lafaye,
               fetch: Callable[[str], str | None]) -> dict[str, Any]:
    headword = candidate["headword"]
    entry = wiktionary.parse(headword, fetch(headword) or "")
    lemma = lexique.best(headword, candidate.get("partOfSpeech") or None) or lexique.best(headword)
    related = {}
    # Paronymes et synonymes courants : leurs sens servent aux confusions, aux nuances et aux quiz.
    for word in (entry.paronyms + entry.synonyms)[:8]:
        if (lexique.rank(word) or 10**9) > MAX_RANK_PARONYM:
            continue
        other = wiktionary.parse(word, fetch(word) or "")
        if other.senses:
            related[word] = {"definitions": [d for s in other.senses for d in s.definitions][:3],
                             "partOfSpeech": other.senses[0].part_of_speech, "gender": other.senses[0].gender,
                             "url": web.page_url(WIKTIONARY_SITE, word)}
    sources = [{"name": "Wiktionnaire", "url": web.page_url(WIKTIONARY_SITE, headword)}]
    if lemma:
        sources.append({"name": "Lexique 3", "url": "http://www.lexique.org"})
    littre_text, lafaye_text = littre.lookup(headword), lafaye.lookup(headword)
    if littre_text:
        sources.append({"name": "Littré", "url": "https://www.littre.org/definition/" + headword})
    if lafaye_text:
        sources.append({"name": "Lafaye, Dictionnaire des synonymes (1858)", "url": "https://fr.wikisource.org/wiki/Dictionnaire_des_synonymes_de_la_langue_française"})
    return {
        "id": candidate["id"], "headword": headword, "family": candidate["family"], "note": candidate.get("note", ""),
        "lexique": None if lemma is None else {"partOfSpeech": lemma.part_of_speech, "gender": lemma.gender, "rank": lemma.rank,
                                               "level": lexique.level(headword), "forms": sorted(lemma.forms)},
        "wiktionary": {**entry.as_dict(), "url": web.page_url(WIKTIONARY_SITE, headword)},
        "related": related, "littre": littre_text, "lafaye": lafaye_text, "sources": sources,
    }


def run(lexique_path: Path, littre: Path | None = None, lafaye: Path | None = None, work: Path = WORK, limit: int | None = None) -> None:
    lexique = Lexique.load(lexique_path)
    littre_index, lafaye_index = Littre(littre), Lafaye(lafaye)
    out = stage_dir("raw", work)
    candidates = read_csv(work / "candidats.csv")[:limit]
    fetch = lambda title: web.page_wikitext(web.WIKTIONARY, title)
    for number, candidate in enumerate(candidates, start=1):
        path = out / f"{candidate['id']}.json"
        if path.exists():
            continue
        write_json(path, gather_one(candidate, lexique, littre_index, lafaye_index, fetch))
        if number % 25 == 0:
            print(f"  {number}/{len(candidates)}")
    print(f"{len(candidates)} extraits → {out}")


def load_raw(identifier: str, work: Path = WORK) -> dict[str, Any]:
    return read_json(work / "raw" / f"{identifier}.json")
