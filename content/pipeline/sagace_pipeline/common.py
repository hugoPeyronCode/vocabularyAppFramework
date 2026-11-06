"""Chemins, constantes et utilitaires partagés par les étapes du pipeline."""
from __future__ import annotations

import csv
import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Iterable

PIPELINE = Path(__file__).resolve().parent.parent
REPO = PIPELINE.parent.parent
CONTENT = REPO / "content"
SCHEMA_PATH = CONTENT / "schema" / "fiche.schema.json"
SEED_PATH = CONTENT / "fr" / "seed_fiches.json"
TOPICS_PATH = CONTENT / "fr" / "topics.json"
LISTS = CONTENT / "fr" / "listes"
PACK_PATH = CONTENT / "fr" / "fiches.json"
PACK_VERSION_PATH = CONTENT / "fr" / "fiches.version"
EN_PACK_PATH = CONTENT / "en" / "fiches.json"
LEGACY_EN = CONTENT / "legacy" / "v3_words.json"

# Données de travail : dumps téléchargés, caches réseau, sorties de chaque étape (non versionnées).
WORK = PIPELINE / "work"

FAMILIES = ["paronyme", "impropriete", "passePartout", "nuance", "pleonasme", "anglicisme", "motMalCompris", "expression"]

# 05_CONTENT.md section 4 : volumes de lancement et répartition des niveaux.
LAUNCH_VOLUMES = {
    "paronyme": 180, "impropriete": 150, "passePartout": 120, "nuance": 150,
    "pleonasme": 80, "anglicisme": 100, "motMalCompris": 120, "expression": 100,
}
LEVEL_SHARES = {1: 0.15, 2: 0.25, 3: 0.30, 4: 0.20, 5: 0.10}
# 1 500 candidats pour viser 1 000 fiches validées.
CANDIDATE_RATIO = 1.5
# Sélection : mots dans les 15 000 plus fréquents (30 000 pour les deux mots d'une paire de paronymes).
MAX_RANK = 15_000
MAX_RANK_PARONYM = 30_000
# Relecture : 10 % tirés au hasard par lot de 200 ; seuil d'erreur de l'échantillon.
REVIEW_BATCH = 200
REVIEW_SAMPLE = 0.10
REVIEW_MAX_ERROR_RATE = 0.02
SHORT_DEFINITION_MAX = 90

USER_AGENT = "SagacePipeline/1.0 (https://github.com/hugoPeyronCode/vocabularyAppFramework)"


def fold(text: str) -> str:
    """Minuscules sans accents ni ligatures."""
    text = text.replace("œ", "oe").replace("Œ", "OE").replace("æ", "ae").replace("Æ", "AE")
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(c for c in decomposed if not unicodedata.combining(c)).lower()


def fiche_id(language: str, headword: str) -> str:
    """Identifiant `fr.mot_compose` conforme au schéma."""
    slug = re.sub(r"[^a-z0-9]+", "_", fold(headword)).strip("_")
    return f"{language}.{slug or 'mot'}"


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8", newline="") as file:
        return list(csv.DictReader(file))


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def stage_dir(name: str, work: Path | None = None) -> Path:
    path = (work or WORK) / name
    path.mkdir(parents=True, exist_ok=True)
    return path


def word_forms(headword: str, extra: Iterable[str] = ()) -> set[str]:
    """Formes repliées acceptées pour retrouver le mot dans une phrase (le mot, ses formes fléchies connues)."""
    forms = {fold(headword)}
    forms.update(fold(form) for form in extra)
    # Pronominal : « se rappeler » se retrouve aussi par « rappeler ».
    forms.add(fold(headword).removeprefix("se ").removeprefix("s'"))
    return {form for form in forms if form}


def contains_form(sentence: str, forms: set[str]) -> bool:
    folded = f" {re.sub(r'[^a-z0-9 ]+', ' ', fold(sentence))} "
    return any(f" {re.sub(r'[^a-z0-9 ]+', ' ', form)} " in folded for form in forms)
