"""Étape 3 : phrases d'auteur candidates (Wikisource) → `work/quotes/<id>.json`.

Textes antérieurs à 1955, auteurs morts depuis plus de 70 ans (Wikidata, P570), phrases de 8 à 35 mots
contenant le mot ou une de ses formes fléchies, prises dans le texte de l'œuvre (ni notes, ni sommaire, ni en-tête).
L'étape critic vérifie ensuite le sens.
"""
from __future__ import annotations

import datetime
import html
import re
import urllib.parse
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from typing import Any, Callable

from . import web
from .common import WORK, contains_form, read_csv, read_json, stage_dir, word_forms, write_json

WIKISOURCE_SITE = "https://fr.wikisource.org"
MIN_WORDS, MAX_WORDS = 8, 35
MAX_YEAR = 1955
CANDIDATES_PER_FICHE = 3
# Textes téléchargés au plus par mot (un chapitre rendu pèse souvent plusieurs centaines de Ko).
MAX_FETCHED = 6
# Phrases candidates au plus par œuvre sur tout le lot : un texte intégral sur une seule page répond à presque tous les mots.
MAX_PER_WORK = 3


class _Visible(HTMLParser):
    """Texte d'une page rendue, sans les sous-arbres qui ne sont pas l'œuvre : notes des éditeurs, sommaire, en-tête,
    titres, tableaux, appels de note."""
    SKIPPED_TAGS = {"style", "script", "sup", "table", "figure", "h1", "h2", "h3", "h4", "h5", "h6"}
    SKIPPED_CLASSES = {"references", "reference", "mw-cite-backlink", "ws-summary", "tableItem", "ws-noexport", "headertemplate", "ws-header", "noprint"}
    VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[bool] = []
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in self.VOID:
            if tag == "br" and not any(self.stack):
                self.parts.append(" ")
            return
        classes = set((dict(attrs).get("class") or "").split())
        self.stack.append(tag in self.SKIPPED_TAGS or bool(classes & self.SKIPPED_CLASSES) or dict(attrs).get("id") == "headertemplate")

    def handle_endtag(self, tag: str) -> None:
        if tag not in self.VOID and self.stack:
            self.stack.pop()
        if tag in ("p", "div", "li", "dd"):
            self.parts.append(" ")

    def handle_data(self, data: str) -> None:
        if not any(self.stack):
            self.parts.append(data)


def visible_text(rendered: str) -> str:
    parser = _Visible()
    parser.feed(rendered)
    return re.sub(r"\s+", " ", "".join(parser.parts)).strip()


def is_prose(sentence: str) -> bool:
    """Écarte ce qui reste de pages de titre et de sommaires (capitales, flèches de note, « Chapitre XI ») et l'orthographe
    ancienne en s longs (« ſucs ſucrés »)."""
    letters = [char for char in sentence if char.isalpha()]
    capitals = sum(char.isupper() for char in letters)
    return (bool(letters) and capitals <= 0.2 * len(letters) and "↑" not in sentence and "ſ" not in sentence
            and not re.search(r"\bchapitre\b", sentence, re.I))


def sentences_with(text: str, forms: set[str]) -> list[str]:
    found = []
    for sentence in re.split(r"(?<=[.!?…])\s+(?=[A-ZÀÂÉÈÊÎÔÛÇ«—])", text):
        sentence = sentence.strip(" «»—-")
        if (MIN_WORDS <= len(sentence.split()) <= MAX_WORDS and contains_form(sentence, forms) and is_prose(sentence)
                and not re.search(r"[|=\[\]{}]", sentence)):
            found.append(sentence)
    return found


def clean_work(work: str) -> str:
    """Nom de page Wikisource → titre : « Stendhal (Paul Valéry) » → « Stendhal », « Centenaire de Diafoirus (Le) » →
    « Le Centenaire de Diafoirus »."""
    article = re.match(r"(.+?)\s*\((Le|La|Les|L’|L')\)$", work)
    if article:
        separator = "" if article.group(2).startswith("L") and article.group(2) not in ("Le", "La", "Les") else " "
        return f"{article.group(2)}{separator}{article.group(1)}"
    return re.sub(r"\s*\([^()]*\)$", "", work) or work


def metadata(wikitext: str, rendered: str = "", categories: list[str] | None = None, title: str = "") -> dict[str, Any]:
    """Auteur, œuvre et année : attributs `<pages ... auteur= titre= annee=>` du wikicode, sinon le lien `Auteur:`
    de l'en-tête rendu, le titre de la page racine et la catégorie « Romans parus en 1839 »."""
    def field(name: str) -> str | None:
        # titre="" (vide) ne doit pas déborder sur l'attribut suivant (« "" prev="[[Lysimaque »).
        match = re.search(rf'{name}\s*=\s*(?:"([^"]*)"|([^|\n>"]+))', wikitext)
        return ((match.group(1) if match.group(1) is not None else match.group(2)).strip() or None) if match else None
    unlink = lambda text: re.sub(r"\[\[(?:Auteur:)?(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", text).strip()
    author = unlink(field("auteur") or "")
    if not author and (link := re.search(r'href="/wiki/Auteur:([^"#]+)"', rendered)):
        author = urllib.parse.unquote(link.group(1)).replace("_", " ")
    # Titre absent ou modèle non développé ({{BASEPAGENAME}}) : page racine.
    work = unlink(field("titre") or "")
    work = clean_work(title.split("/")[0] if not work or "{{" in work else work)
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


def work_year(title: str) -> int | None:
    """Année de l'œuvre (Wikidata : P577 de l'œuvre dont la page est une édition, P629), pas celle de l'édition
    numérisée : Jacques le Fataliste date de 1796, l'édition Assézat de 1875."""
    data = web.get_json(web.WIKISOURCE, {"action": "query", "prop": "pageprops", "titles": title.split("/")[0]})
    pages = data.get("query", {}).get("pages", [])
    item = pages[0].get("pageprops", {}).get("wikibase_item") if pages else None
    if not item:
        return None
    claims = lambda entity: web.get_json(web.WIKIDATA, {"action": "wbgetentities", "ids": entity, "props": "claims"}).get("entities", {}).get(entity, {}).get("claims", {})
    edition = claims(item)
    works = [claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id") for claim in edition.get("P629", [])]
    years = []
    for work in filter(None, works[:1]):
        for claim in claims(work).get("P577", []) + claims(work).get("P571", []):
            match = re.match(r"[+-](\d{4})", claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("time", ""))
            if match:
                years.append(int(match.group(1)))
    return min(years) if years else None


def public_domain(meta: dict[str, Any], died: int | None, today: datetime.date | None = None) -> bool:
    today = today or datetime.date.today()
    return bool(meta["author"] and meta["work"] and meta["year"] and meta["year"] < MAX_YEAR
                and died is not None and died < today.year - 70)


# Œuvres littéraires seulement : dictionnaires, index et textes religieux ou techniques sont écartés.
CATEGORIES = "Romans|Romans_français|Nouvelles|Contes|Théâtre|Essais|Mémoires|Poèmes"


def quotes_for(raw: dict[str, Any], search: Callable[[str], list[str]], describe: Callable[[list[str]], dict[str, dict[str, Any]]],
               page: Callable[[str], str | None], died: Callable[[str], int | None],
               dated: Callable[[str], int | None] = lambda title: None, used: Counter[str] | None = None) -> list[dict[str, Any]]:
    """Métadonnées de tous les résultats d'un coup ; le texte n'est téléchargé que pour une œuvre du domaine public
    (auteur et traducteur morts depuis plus de 70 ans) qui n'a pas déjà fourni `MAX_PER_WORK` phrases au lot (`used`)."""
    forms = word_forms(raw["headword"], (raw.get("lexique") or {}).get("forms", []))
    found: list[dict[str, Any]] = []
    fetched = 0
    used = Counter() if used is None else used
    for title, described in describe(search(raw["headword"])).items():
        if fetched >= MAX_FETCHED:
            break
        root = title.split("/")[0]
        if used[root] >= MAX_PER_WORK:
            continue
        deaths = [died(author) for author in described["authors"]]
        provisional = metadata(described["wikitext"], "", described["categories"], title)
        if not public_domain({**provisional, "author": "?"}, None if not deaths or None in deaths else max(deaths)):
            continue
        rendered = page(title)
        fetched += 1
        if not rendered:
            continue
        # Auteur définitif : attribut du wikicode, sinon premier lien `Auteur:` de l'en-tête rendu (les liens de la page
        # arrivent par ordre alphabétique, pas dans l'ordre du texte).
        meta = metadata(described["wikitext"], rendered, described["categories"], title)
        if meta["author"] not in described["authors"]:
            continue
        original = dated(title)
        year = min(original, meta["year"]) if original and meta["year"] else original or meta["year"]
        for sentence in sentences_with(visible_text(rendered), forms)[:1]:
            found.append({"text": sentence, "author": meta["author"], "work": meta["work"], "year": year,
                          "url": web.page_url(WIKISOURCE_SITE, title)})
            used[root] += 1
        if len(found) >= CANDIDATES_PER_FICHE:
            break
    return found


def search_wikisource(word: str) -> list[str]:
    data = web.get_json(web.WIKISOURCE, {"action": "query", "list": "search", "srsearch": f'"{word}" incategory:{CATEGORIES}', "srnamespace": 0, "srlimit": 20})
    return [hit["title"] for hit in data.get("query", {}).get("search", [])]


def describe_pages(titles: list[str]) -> dict[str, dict[str, Any]]:
    """Une seule requête pour tous les résultats : wikicode d'en-tête, catégories et tous les auteurs liens `Auteur:`
    (traducteurs compris), dans l'ordre de la recherche."""
    if not titles:
        return {}
    data = web.get_json(web.WIKISOURCE, {"action": "query", "prop": "revisions|categories|links", "rvprop": "content", "rvslots": "main",
                                         "plnamespace": 102, "pllimit": "max", "cllimit": "max", "titles": "|".join(titles)})
    described = {}
    for item in data.get("query", {}).get("pages", []):
        if item.get("missing"):
            continue
        wikitext = item.get("revisions", [{}])[0].get("slots", {}).get("main", {}).get("content", "")
        authors = [link["title"].removeprefix("Auteur:") for link in item.get("links", [])]
        categories = [category["title"].removeprefix("Catégorie:") for category in item.get("categories", [])]
        named = metadata(wikitext)["author"]
        described[item["title"]] = {"wikitext": wikitext, "categories": categories,
                                    "authors": list(dict.fromkeys(([named] if named else []) + authors))}
    order = {title: index for index, title in enumerate(titles)}
    return dict(sorted(described.items(), key=lambda pair: order.get(pair[0], len(order))))


def fetch_page(title: str) -> str | None:
    """Texte rendu : les chapitres ne font que transclure les pages scannées."""
    data = web.get_json(web.WIKISOURCE, {"action": "parse", "page": title, "prop": "text"})
    return data["parse"]["text"] if "parse" in data else None


def run(work: Path = WORK, limit: int | None = None) -> None:
    out = stage_dir("quotes", work)
    candidates = read_csv(work / "candidats.csv")[:limit]
    # Œuvres déjà citées par les phrases trouvées aux passages précédents.
    used = Counter(urllib.parse.unquote(quote["url"].rsplit("/wiki/", 1)[-1]).replace("_", " ").split("/")[0]
                   for path in out.glob("*.json") for quote in read_json(path))
    for candidate in candidates:
        path = out / f"{candidate['id']}.json"
        raw_path = work / "raw" / f"{candidate['id']}.json"
        if path.exists() or not raw_path.exists():
            continue
        write_json(path, quotes_for(read_json(raw_path), search_wikisource, describe_pages, fetch_page, death_year, work_year, used))
    print(f"phrases d'auteur → {out}")
