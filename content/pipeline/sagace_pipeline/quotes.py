"""Étape 3 : phrases d'auteur candidates (Wikisource) → `work/quotes/<id>.json`.

Textes antérieurs à 1955, auteurs morts depuis plus de 70 ans (Wikidata, P570), phrases de 8 à 35 mots
contenant le mot ou une de ses formes fléchies. L'étape critic vérifie ensuite le sens.
"""
from __future__ import annotations

import datetime
import html
import re
import urllib.parse
from pathlib import Path
from typing import Any, Callable

from . import web
from .common import WORK, contains_form, read_csv, read_json, stage_dir, word_forms, write_json

WIKISOURCE_SITE = "https://fr.wikisource.org"
MIN_WORDS, MAX_WORDS = 8, 35
MAX_YEAR = 1955
CANDIDATES_PER_FICHE = 3


def plain_text(wikitext: str) -> str:
    text = re.sub(r"<ref[^>]*>.*?</ref>|<(style|script)[^>]*>.*?</\1>|<sup[^>]*>.*?</sup>", "", wikitext, flags=re.S)
    text = re.sub(r"\{\{[^{}]*\}\}", "", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", text)
    text = text.replace("'''", "").replace("''", "")
    return html.unescape(re.sub(r"\s+", " ", text)).strip()


def sentences_with(text: str, forms: set[str]) -> list[str]:
    found = []
    for sentence in re.split(r"(?<=[.!?…])\s+(?=[A-ZÀÂÉÈÊÎÔÛÇ«—])", text):
        sentence = sentence.strip(" «»—-")
        if MIN_WORDS <= len(sentence.split()) <= MAX_WORDS and contains_form(sentence, forms) and not re.search(r"[|=\[\]{}]", sentence):
            found.append(sentence)
    return found


def metadata(wikitext: str, rendered: str = "", categories: list[str] | None = None, title: str = "") -> dict[str, Any]:
    """Auteur, œuvre et année : attributs `<pages ... auteur= titre= annee=>` du wikicode, sinon le lien `Auteur:`
    de l'en-tête rendu, le titre de la page racine et la catégorie « Romans parus en 1839 »."""
    def field(name: str) -> str | None:
        match = re.search(rf'{name}\s*=\s*(?:"([^"]+)"|([^|\n>]+))', wikitext)
        return (match.group(1) or match.group(2)).strip() if match else None
    unlink = lambda text: re.sub(r"\[\[(?:Auteur:)?(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", text).strip()
    author = unlink(field("auteur") or "")
    if not author and (link := re.search(r'href="/wiki/Auteur:([^"#]+)"', rendered)):
        author = urllib.parse.unquote(link.group(1)).replace("_", " ")
    work = unlink(field("titre") or "") or title.split("/")[0]
    year_text = field("annee") or field("date") or " ".join(categories or [])
    year = re.search(r"\b(1[0-9]{3})\b", year_text)
    return {"author": author or None, "work": work or None, "year": int(year.group(1)) if year else None}


def death_year(author: str) -> int | None:
    data = web.get_json(web.WIKISOURCE, {"action": "query", "prop": "pageprops", "titles": f"Auteur:{author}"})
    pages = data.get("query", {}).get("pages", [])
    item = pages[0].get("pageprops", {}).get("wikibase_item") if pages else None
    if not item:
        return None
    claims = web.get_json(web.WIKIDATA, {"action": "wbgetclaims", "entity": item, "property": "P570"}).get("claims", {}).get("P570", [])
    for claim in claims:
        time = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("time", "")
        match = re.match(r"[+-](\d{4})", time)
        if match:
            return int(match.group(1))
    return None


def public_domain(meta: dict[str, Any], died: int | None, today: datetime.date | None = None) -> bool:
    today = today or datetime.date.today()
    return bool(meta["author"] and meta["work"] and meta["year"] and meta["year"] < MAX_YEAR
                and died is not None and died < today.year - 70)


# Œuvres littéraires seulement : dictionnaires, index et textes religieux ou techniques sont écartés.
CATEGORIES = "Romans|Romans_français|Nouvelles|Contes|Théâtre|Essais|Mémoires|Poèmes"


def quotes_for(raw: dict[str, Any], search: Callable[[str], list[str]], page: Callable[[str], dict[str, Any] | None],
               died: Callable[[str], int | None]) -> list[dict[str, Any]]:
    forms = word_forms(raw["headword"], (raw.get("lexique") or {}).get("forms", []))
    found: list[dict[str, Any]] = []
    for title in search(raw["headword"]):
        content = page(title)
        if not content:
            continue
        meta = metadata(content["wikitext"], content["html"], content["categories"], title)
        if not public_domain(meta, died(meta["author"]) if meta["author"] else None):
            continue
        for sentence in sentences_with(plain_text(content["html"]), forms)[:1]:
            found.append({"text": sentence, "author": meta["author"], "work": meta["work"], "year": meta["year"],
                          "url": web.page_url(WIKISOURCE_SITE, title)})
        if len(found) >= CANDIDATES_PER_FICHE:
            break
    return found


def search_wikisource(word: str) -> list[str]:
    data = web.get_json(web.WIKISOURCE, {"action": "query", "list": "search", "srsearch": f'"{word}" incategory:{CATEGORIES}', "srnamespace": 0, "srlimit": 20})
    return [hit["title"] for hit in data.get("query", {}).get("search", [])]


def fetch_page(title: str) -> dict[str, Any] | None:
    """Texte rendu (les chapitres ne font que transclure les pages scannées), wikicode et catégories."""
    data = web.get_json(web.WIKISOURCE, {"action": "parse", "page": title, "prop": "text|categories"})
    if "parse" not in data:
        return None
    categories = [category.get("category", "").replace("_", " ") for category in data["parse"].get("categories", [])]
    return {"html": data["parse"]["text"], "wikitext": web.page_wikitext(web.WIKISOURCE, title) or "", "categories": categories}


def run(work: Path = WORK, limit: int | None = None) -> None:
    out = stage_dir("quotes", work)
    candidates = read_csv(work / "candidats.csv")[:limit]
    for candidate in candidates:
        path = out / f"{candidate['id']}.json"
        raw_path = work / "raw" / f"{candidate['id']}.json"
        if path.exists() or not raw_path.exists():
            continue
        write_json(path, quotes_for(read_json(raw_path), search_wikisource, fetch_page, death_year))
    print(f"phrases d'auteur → {out}")
