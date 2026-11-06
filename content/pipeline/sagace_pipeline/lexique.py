"""Lexique 3 (lexique.org, CC BY-SA 4.0) : fréquence, nature et genre des lemmes français.

Fichier attendu : `Lexique383.tsv` (colonnes `ortho`, `lemme`, `cgram`, `genre`, `freqlemfilms2`, `freqlemlivres`).
"""
from __future__ import annotations

import csv
from dataclasses import dataclass, field
from pathlib import Path

# cgram de Lexique → partOfSpeech du schéma.
CGRAM = {"NOM": "nom", "VER": "verbe", "AUX": "verbe", "ADJ": "adjectif", "ADV": "adverbe", "PRE": "preposition"}
GENRE = {"m": "masculin", "f": "feminin"}


@dataclass
class Lemma:
    lemma: str
    part_of_speech: str
    gender: str | None
    frequency: float
    rank: int = 0
    forms: set[str] = field(default_factory=set)


class Lexique:
    def __init__(self, lemmas: dict[tuple[str, str], Lemma]):
        self.lemmas = lemmas
        ranked = sorted(lemmas.values(), key=lambda item: -item.frequency)
        for rank, lemma in enumerate(ranked, start=1):
            lemma.rank = rank

    @classmethod
    def load(cls, path: Path) -> "Lexique":
        lemmas: dict[tuple[str, str], Lemma] = {}
        with path.open(encoding="utf-8", newline="") as file:
            for row in csv.DictReader(file, delimiter="\t"):
                pos = CGRAM.get(row["cgram"].split(":")[0])
                if pos is None:
                    continue
                key = (row["lemme"], pos)
                frequency = float(row.get("freqlemfilms2") or 0) + float(row.get("freqlemlivres") or 0)
                lemma = lemmas.get(key)
                if lemma is None:
                    lemma = lemmas[key] = Lemma(row["lemme"], pos, GENRE.get(row.get("genre", "")), frequency)
                # Fréquence de lemme : identique sur chaque ligne de forme, on garde la plus haute.
                lemma.frequency = max(lemma.frequency, frequency)
                if lemma.gender is None and pos == "nom":
                    lemma.gender = GENRE.get(row.get("genre", ""))
                lemma.forms.add(row["ortho"])
        return cls(lemmas)

    def entries(self, word: str) -> list[Lemma]:
        return sorted((lemma for (lemma_word, _), lemma in self.lemmas.items() if lemma_word == word), key=lambda item: item.rank)

    def best(self, word: str, part_of_speech: str | None = None) -> Lemma | None:
        candidates = [item for item in self.entries(word) if part_of_speech in (None, item.part_of_speech)]
        return candidates[0] if candidates else None

    def rank(self, word: str) -> int | None:
        best = self.best(word)
        return best.rank if best else None

    def level(self, word: str) -> int:
        """Niveau 1 à 5 selon le rang de fréquence (les plus fréquents en niveau 1)."""
        rank = self.rank(word) or 30_000
        for level, limit in ((1, 2_000), (2, 5_000), (3, 10_000), (4, 20_000)):
            if rank <= limit:
                return level
        return 5
