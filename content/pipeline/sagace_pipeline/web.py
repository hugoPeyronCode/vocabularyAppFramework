"""Accès aux API MediaWiki (Wiktionnaire, Wikisource, Wikidata) avec cache disque et débit limité."""
from __future__ import annotations

import hashlib
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

from .common import USER_AGENT, WORK

# Politesse envers les serveurs Wikimedia : une requête toutes les 0,5 s au plus.
MIN_INTERVAL = 0.5
_last_request = 0.0


def get_json(url: str, params: dict[str, Any], cache: Path | None = None) -> Any:
    query = urllib.parse.urlencode({**params, "format": "json", "formatversion": 2}, doseq=True)
    full = f"{url}?{query}"
    cache = cache or WORK / "cache"
    cached = cache / (hashlib.sha256(full.encode()).hexdigest() + ".json")
    if cached.exists():
        return json.loads(cached.read_text(encoding="utf-8"))
    global _last_request
    wait = MIN_INTERVAL - (time.monotonic() - _last_request)
    if wait > 0:
        time.sleep(wait)
    request = urllib.request.Request(full, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        data = json.loads(response.read().decode("utf-8"))
    _last_request = time.monotonic()
    cached.parent.mkdir(parents=True, exist_ok=True)
    cached.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    return data


WIKTIONARY = "https://fr.wiktionary.org/w/api.php"
WIKISOURCE = "https://fr.wikisource.org/w/api.php"
WIKIDATA = "https://www.wikidata.org/w/api.php"


def page_wikitext(api: str, title: str) -> str | None:
    # Redirections suivies : « à l'envi » renvoie à « à l’envi ».
    data = get_json(api, {"action": "query", "prop": "revisions", "rvprop": "content", "rvslots": "main", "titles": title, "redirects": 1})
    pages = data.get("query", {}).get("pages", [])
    if not pages or pages[0].get("missing"):
        return None
    return pages[0]["revisions"][0]["slots"]["main"]["content"]


def category_members(api: str, category: str, limit: int = 5_000) -> list[str]:
    titles: list[str] = []
    params: dict[str, Any] = {"action": "query", "list": "categorymembers", "cmtitle": category, "cmlimit": 500, "cmnamespace": 0}
    while len(titles) < limit:
        data = get_json(api, params)
        titles += [member["title"] for member in data.get("query", {}).get("categorymembers", [])]
        if "continue" not in data:
            break
        params = {**params, **data["continue"]}
    return titles[:limit]


def page_url(base: str, title: str) -> str:
    return f"{base}/wiki/{urllib.parse.quote(title.replace(' ', '_'))}"
