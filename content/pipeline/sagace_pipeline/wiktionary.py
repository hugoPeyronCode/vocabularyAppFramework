"""Extraits du Wiktionnaire (CC BY-SA 4.0) : sens, synonymes, paronymes, prononciation, étymologie, notes d'usage.

On ne garde que la section française d'une page, découpée par nature grammaticale.
"""
from __future__ import annotations

import re
from dataclasses import asdict, dataclass, field

# {{S|adjectif|fr}} → partOfSpeech du schéma.
POS = {"nom": "nom", "nom commun": "nom", "verbe": "verbe", "adjectif": "adjectif", "adverbe": "adverbe",
       "locution nominale": "locution", "locution verbale": "locution", "locution adverbiale": "locution",
       "locution adjectivale": "locution", "locution": "locution", "préposition": "preposition",
       "locution prépositive": "preposition", "interjection": "locution"}
# Marqueurs d'usage repérés dans les définitions et les notes (sélection des familles, verdict).
USAGE_MARKERS = {
    "critiqué": "critique", "critique": "critique", "pléonasme": "pleonasme", "anglicisme": "anglicisme",
    "barbarisme": "fautif", "impropre": "fautif", "à éviter": "critique", "abusivement": "critique",
    "par confusion": "fautif", "faux ami": "anglicisme",
}


@dataclass
class Sense:
    part_of_speech: str
    gender: str | None
    definitions: list[str] = field(default_factory=list)
    examples: list[str] = field(default_factory=list)
    markers: list[str] = field(default_factory=list)


@dataclass
class Entry:
    title: str
    phonetic: str | None = None
    etymology: str | None = None
    senses: list[Sense] = field(default_factory=list)
    synonyms: list[str] = field(default_factory=list)
    paronyms: list[str] = field(default_factory=list)
    antonyms: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)
    markers: list[str] = field(default_factory=list)

    def as_dict(self) -> dict:
        return asdict(self)


def french_section(wikitext: str) -> str:
    match = re.search(r"==\s*\{\{langue\|fr\}\}\s*==(.*?)(?=\n==\s*\{\{langue\||\Z)", wikitext, re.S)
    return match.group(1) if match else ""


def clean(text: str) -> str:
    """Wikicode → texte lisible (liens, modèles courants, gras/italique, références)."""
    text = re.sub(r"<ref[^>]*>.*?</ref>|<ref[^/]*/>", "", text, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", text)
    # Modèles de contexte ({{figuré|fr}}) → (figuré) ; modèles « lien » → leur texte.
    text = re.sub(r"\{\{(?:lien|l|w)\|([^|}]+)[^}]*\}\}", r"\1", text)
    # Étymologie : {{étyl|la|fr|mot=eminens}} → eminens.
    text = re.sub(r"\{\{étyl\|[^}]*?mot=([^|}]+)[^}]*\}\}", r"\1", text)
    text = re.sub(r"\{\{([^|}]+)\|fr\}\}", r"(\1)", text)
    text = re.sub(r"\{\{[^}]*\}\}", "", text)
    text = text.replace("'''", "").replace("''", "")
    return re.sub(r"\s+", " ", text).strip(" :")


def _links(block: str) -> list[str]:
    words = re.findall(r"\[\[([^|\]#]+)", block) + re.findall(r"\{\{lien\|([^|}]+)", block)
    return list(dict.fromkeys(word.strip() for word in words if word.strip()))


def _markers(text: str) -> list[str]:
    folded = text.lower()
    return sorted({value for key, value in USAGE_MARKERS.items() if key in folded})


def parse(title: str, wikitext: str) -> Entry:
    section = french_section(wikitext)
    entry = Entry(title=title)
    if not section:
        return entry
    pron = re.search(r"\{\{pron\|([^|}]+)\|fr\}\}", section)
    entry.phonetic = f"/{pron.group(1)}/" if pron else None
    parts = re.split(r"\n(={3,4}\s*\{\{S\|[^}]+\}\}[^\n]*)", "\n" + section)
    current: Sense | None = None
    for index in range(1, len(parts), 2):
        header, body = parts[index], parts[index + 1]
        name = re.search(r"\{\{S\|([^|}]+)", header).group(1).strip().lower()
        # Formes fléchies (« éminent » troisième personne de « éminer ») : pas un sens du mot.
        if "flexion" in header:
            current = None
            continue
        if name == "étymologie":
            lines = [clean(line.lstrip(": ")) for line in body.splitlines() if line.startswith(":")]
            entry.etymology = " ".join(line for line in lines if line) or None
        elif name in POS:
            gender = "masculin" if "{{m}}" in body else "feminin" if "{{f}}" in body else None
            if "{{mf}}" in body or "{{épicène}}" in body:
                gender = "epicene"
            current = Sense(POS[name], gender)
            for line in body.splitlines():
                if re.match(r"#[^*:#]", line):
                    definition = clean(line[1:])
                    if definition:
                        current.definitions.append(definition)
                        current.markers += _markers(line)
                elif line.startswith("#*") and "''" in line:
                    example = clean(line[2:])
                    if example:
                        current.examples.append(example)
            current.markers = sorted(set(current.markers))
            entry.senses.append(current)
        elif name == "synonymes":
            entry.synonyms += _links(body)
        elif name == "paronymes":
            entry.paronyms += _links(body)
        elif name == "antonymes":
            entry.antonyms += _links(body)
        elif name in ("notes", "note", "remarques", "note d’usage", "note d'usage", "usage"):
            notes = [clean(line.lstrip("*:# ")) for line in body.splitlines() if line.strip() and not line.startswith("{{")]
            entry.notes += [note for note in notes if note]
            entry.markers += _markers(body)
    entry.markers = sorted(set(entry.markers + [m for sense in entry.senses for m in sense.markers]))
    return entry
