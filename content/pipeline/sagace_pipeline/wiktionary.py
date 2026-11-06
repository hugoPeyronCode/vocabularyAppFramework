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


def part_of_speech(name: str) -> str | None:
    """Nature d'une section : exacte (`POS`), puis par famille (« adjectif indéfini », « locution conjonctive »,
    « locution-phrase ») ; le schéma n'a pas de conjonction ni de pronom, rangés avec les locutions."""
    if name in POS:
        return POS[name]
    for prefix, value in (("locution prépositi", "preposition"), ("adjectif", "adjectif"), ("adverbe", "adverbe"),
                          ("verbe", "verbe"), ("nom ", "nom"), ("locution", "locution"), ("conjonction", "locution"),
                          ("pronom", "locution")):
        if name.startswith(prefix):
            return value
    return None


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


def phonetic(section: str) -> str | None:
    """Première prononciation française : {{pron|nwe|nu.e|fr}}, sinon le modèle de flexion {{fr-rég|nwe}}."""
    for template in re.findall(r"\{\{(?:pron|fr-rég|fr-inv)\|([^}]*)\}\}", section):
        values = [value.strip() for value in template.split("|") if value.strip() and "=" not in value and value.strip() != "fr"]
        if values:
            return f"/{values[0]}/"
    return None


def french_section(wikitext: str) -> str:
    match = re.search(r"==\s*\{\{langue\|fr\}\}\s*==(.*?)(?=\n==\s*\{\{langue\||\Z)", wikitext, re.S)
    return match.group(1) if match else ""


# Langues d'origine les plus courantes des modèles {{étyl}} ; un code inconnu est gardé tel quel.
LANGUAGES = {
    "la": "latin", "grc": "grec ancien", "el": "grec", "en": "anglais", "it": "italien", "de": "allemand", "es": "espagnol",
    "pt": "portugais", "nl": "néerlandais", "ar": "arabe", "frk": "francique", "fro": "ancien français", "frm": "moyen français",
    "pro": "ancien occitan", "oc": "occitan", "gaul": "gaulois", "la-cla": "latin classique", "la-ecc": "latin ecclésiastique",
    "la-med": "latin médiéval", "bas-latin": "bas latin", "gem": "germanique", "hbo": "hébreu ancien", "tr": "turc",
}


def _etymon(match: re.Match[str]) -> str:
    """{{étyl|la|fr|mot=eminens}} → « latin eminens » ; sans mot, la langue seule."""
    parts = match.group(1).split("|")
    language = LANGUAGES.get(parts[0].strip(), parts[0].strip()) if parts else ""
    word = next((part.split("=", 1)[1] for part in parts if part.startswith("mot=")), "")
    return f"{language} {word}".strip()


def clean(text: str) -> str:
    """Wikicode → texte lisible (liens, modèles courants, gras/italique, références)."""
    text = re.sub(r"<ref[^>]*>.*?</ref>|<ref[^/]*/>", "", text, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)
    # Images (« [[Fichier:x.jpg|thumb|Faire à manger.]] ») : retirées, légende comprise.
    text = re.sub(r"\[\[(?:Fichier|Image|File):(?:[^\[\]]|\[\[[^\]]*\]\])*\]\]", "", text)
    text = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", text)
    # Modèles de contexte ({{figuré|fr}}) → (figuré) ; modèles « lien » → leur texte.
    text = re.sub(r"\{\{(?:lien|l|w)\|([^|}]+)[^}]*\}\}", r"\1", text)
    # Renvoi d'orthographe : {{variante ortho de|évènement|fr}} → Variante orthographique de évènement.
    text = re.sub(r"\{\{variante(?: ortho| orthographique)? de\|([^|}]+)[^}]*\}\}", r"Variante orthographique de \1", text)
    # {{composé de|prolonger|-ment|lang=fr}} → Composé de prolonger et -ment.
    text = re.sub(r"\{\{composé de\|([^}]*)\}\}",
                  lambda match: "Composé de " + " et ".join(part for part in match.group(1).split("|") if "=" not in part), text)
    text = re.sub(r"\{\{(?:dénominal|déverbal)\|[^}]*?de=([^|}]+)[^}]*\}\}", r"Dérivé de \1", text)
    # Étymologie : {{étyl|la|fr|mot=eminens}} → latin eminens.
    text = re.sub(r"\{\{étyl\|([^}]*)\}\}", _etymon, text)
    text = re.sub(r"\{\{([^|}]+)\|fr\}\}", r"(\1)", text)
    text = re.sub(r"\{\{[^}]*\}\}", "", text)
    text = text.replace("'''", "").replace("''", "")
    return re.sub(r"\s+", " ", text).strip(" :")


def _split_template(inner: str) -> list[str]:
    """Paramètres d'un modèle, sans couper les modèles et liens imbriqués."""
    params, depth, current = [], 0, ""
    for index, char in enumerate(inner):
        pair = inner[index:index + 2]
        if pair in ("{{", "[["):
            depth += 1
        elif pair in ("}}", "]]") and depth > 0:
            depth -= 1
        if char == "|" and depth == 0:
            params.append(current)
            current = ""
        else:
            current += char
    return params + [current]


def examples_in(body: str) -> list[str]:
    """Exemples `{{exemple|texte|source=...}}` (sur une ou plusieurs lignes) : « texte — source »."""
    found = []
    for match in re.finditer(r"\{\{exemple", body):
        depth, end = 0, None
        for index in range(match.start(), len(body) - 1):
            if body[index:index + 2] == "{{":
                depth += 1
            elif body[index:index + 2] == "}}":
                depth -= 1
                if depth == 0:
                    end = index
                    break
        if end is None:
            continue
        params = _split_template(body[match.start() + 2:end])[1:]
        positional = [param for param in params if not re.match(r"\s*\w+\s*=", param)]
        named = {key.strip(): value for key, _, value in (param.partition("=") for param in params if re.match(r"\s*\w+\s*=", param))}
        text = clean(positional[0]) if positional else ""
        if text:
            source = clean(named.get("source", ""))
            found.append(f"{text} — {source}" if source else text)
    return found


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
    entry.phonetic = phonetic(section)
    # Niveaux 3 à 5 : les notes d'usage sont souvent rangées sous la nature (« ===== {{S|notes}} ===== »).
    parts = re.split(r"\n(={3,5}\s*\{\{S\|[^}]+\}\}[^\n]*)", "\n" + section)
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
        elif part_of_speech(name):
            gender = "masculin" if "{{m}}" in body else "feminin" if "{{f}}" in body else None
            if "{{mf}}" in body or "{{épicène}}" in body:
                gender = "epicene"
            current = Sense(part_of_speech(name), gender)
            current.examples = examples_in(body)[:6]
            for line in body.splitlines():
                # Sens et sous-sens (« ## ») : la critique d'un emploi figure souvent dans le sous-sens.
                if re.match(r"##?[^*:#]", line):
                    definition = clean(line.lstrip("#"))
                    # Définition pas encore rédigée sur le Wiktionnaire : « (figuré) … ».
                    if re.sub(r"\([^)]*\)", "", definition).strip(" .…"):
                        current.definitions.append(definition)
                        current.markers += _markers(line)
                elif line.startswith("#*") and "''" in line and "{{exemple" not in line:
                    example = clean(line[2:])
                    if example and len(current.examples) < 6:
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
