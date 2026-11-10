"""Tests du pipeline de contenu : `python3 -m unittest discover tests` depuis `content/pipeline/` (sans réseau ni API)."""
from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sagace_pipeline import agent, build, check, convert_v3_en, draft, llm, quotes, review, schema, select, wiktionary
from sagace_pipeline.common import SCHEMA_PATH, SEED_PATH, contains_form, fiche_id, read_json, word_forms, write_json
from sagace_pipeline.lexique import Lexique

FIXTURES = Path(__file__).parent / "fixtures"


def seed(identifier: str = "fr.eminent") -> dict:
    return copy.deepcopy(next(fiche for fiche in read_json(SEED_PATH) if fiche["id"] == identifier))


def raw_for(fiche: dict) -> dict:
    return {"id": fiche["id"], "headword": fiche["headword"], "family": fiche["family"], "note": "",
            "lexique": {"partOfSpeech": fiche["partOfSpeech"], "gender": fiche.get("gender"), "rank": 9000, "level": 3,
                        "forms": [fiche["headword"], fiche["headword"] + "s"]},
            "wiktionary": {"senses": [{"part_of_speech": fiche["partOfSpeech"], "gender": fiche.get("gender"), "definitions": [fiche["definition"]], "examples": [], "markers": []}]},
            "related": {}, "littre": [], "lafaye": [], "sources": fiche["sources"]}


class Basics(unittest.TestCase):
    def test_ids_and_forms(self):
        self.assertEqual(fiche_id("fr", "au jour d'aujourd'hui"), "fr.au_jour_d_aujourd_hui")
        self.assertEqual(fiche_id("fr", "Œuvre"), "fr.oeuvre")
        self.assertTrue(contains_form("Les plus éminents chercheurs.", word_forms("éminent", ["éminents"])))
        self.assertFalse(contains_form("Un départ imminent.", word_forms("éminent")))
        self.assertTrue(contains_form("Je me rappelle bien.", word_forms("se rappeler", ["rappelle"])))

    def test_lexique(self):
        lexique = Lexique.load(FIXTURES / "lexique.tsv")
        self.assertEqual(lexique.best("maison").rank, 1)
        self.assertEqual(lexique.best("conjoncture").gender, "feminin")
        self.assertEqual(lexique.best("éminent").forms, {"éminent", "éminents"})
        self.assertEqual(lexique.level("maison"), 1)
        self.assertIsNone(lexique.best("inconnu"))


class Wiktionary(unittest.TestCase):
    def test_parse_french_section_only(self):
        entry = wiktionary.parse("éminent", (FIXTURES / "eminent.wikitext").read_text(encoding="utf-8"))
        self.assertEqual(entry.phonetic, "/e.mi.nɑ̃/")
        self.assertEqual(len(entry.senses), 1)
        sense = entry.senses[0]
        self.assertEqual(sense.part_of_speech, "adjectif")
        self.assertEqual(sense.definitions[0], "Qui s'élève au-dessus des autres par son mérite ou son rang.")
        self.assertEqual(sense.definitions[1], "(figuré) Qui domine.")
        self.assertEqual(sense.examples, ["Un éminent spécialiste."])
        self.assertEqual(entry.synonyms, ["remarquable", "illustre"])
        self.assertEqual(entry.paronyms, ["imminent"])
        self.assertIn("eminens", entry.etymology)


    def test_level_five_notes_and_sub_senses(self):
        wikitext = ("== {{langue|fr}} ==\n=== {{S|adverbe|fr}} ===\n'''au final''' {{pron|o fi.nal|fr}}\n"
                    "# Finalement.\n## {{critiqué|fr}} En fin de compte.\n"
                    "===== {{S|notes}} =====\n: L’Académie française considère « au final » comme une construction fautive.\n")
        entry = wiktionary.parse("au final", wikitext)
        self.assertEqual(entry.senses[0].definitions, ["Finalement.", "(critiqué) En fin de compte."])
        self.assertEqual(len(entry.notes), 1)


class WiktionaryExamples(unittest.TestCase):
    def test_multiline_examples_with_source(self):
        body = ("# Faire des [[effort]]s.\n"
                "#* {{exemple| Sa mère '''tâchait''' de s’interposer. |source= {{w|Gustave Flaubert}}, ''L’Éducation sentimentale'', 1891|lang=fr}}\n"
                "#* {{exemple | lang=fr\n | Mais '''tâchons''' donc que tout se passe bien.\n | source=[[w:Émile Thirion|Émile Thirion]], ''La Politique au village'', 1896}}\n")
        self.assertEqual(wiktionary.examples_in(body), [
            "Sa mère tâchait de s’interposer. — Gustave Flaubert, L’Éducation sentimentale, 1891",
            "Mais tâchons donc que tout se passe bien. — Émile Thirion, La Politique au village, 1896",
        ])
        self.assertEqual(wiktionary.part_of_speech("locution conjonctive"), "locution")
        self.assertEqual(wiktionary.part_of_speech("adjectif indéfini"), "adjectif")
        self.assertEqual(wiktionary.clean("calque de l’{{calque|en|fr|mot=prioritize}}."), "calque de l’anglais prioritize.")
        self.assertEqual(wiktionary.clean("Du {{étyl|grc|fr|δηλητήριος|dêlêtêrios|nuisible}}."), "Du grec ancien δηλητήριος.")
        self.assertEqual(wiktionary.clean("L’{{W|Académie française}} pense"), "L’Académie française pense")
        self.assertEqual(wiktionary.phonetic("Cognat du corse {{pron|ˈdjɔr.nu|co}}.\n'''jour''' {{pron|ʒuʁ|fr}}"), "/ʒuʁ/")
        self.assertEqual(wiktionary.phonetic("{{pron|a|fr}} dans une note.\n'''soulager''' {{pron|su.la.ʒe|fr}}"), "/su.la.ʒe/")
        self.assertFalse(quotes.is_prose("Les ſucs ſucrés du fruit."))


class Selection(unittest.TestCase):
    def test_editorial_kept_frequent_words_only_quotas(self):
        lexique = Lexique.load(FIXTURES / "lexique.tsv")
        config = {"paronyme": {"search": ["q"], "annexes": ["a"]}, "passePartout": {"verbs": ["manger"]}}
        editorial = [{"headword": "monter en haut", "family": "pleonasme", "note": "redondance"}]
        rows = select.select(lexique, config, editorial, search=lambda query: ["éminent", "vocable", "absent"],
                             annexes=lambda title: [("conjoncture", "conjecture")])
        by_id = {row["id"]: row for row in rows}
        self.assertIn("fr.monter_en_haut", by_id)
        self.assertEqual(by_id["fr.monter_en_haut"]["partOfSpeech"], "locution")
        self.assertIn("fr.eminent", by_id)
        self.assertIn("fr.manger", by_id)
        self.assertNotIn("fr.absent", by_id)
        # « conjecture » n'est pas dans Lexique : la paire de l'annexe n'est pas retenue.
        self.assertNotIn("fr.conjoncture", by_id)


class Quotes(unittest.TestCase):
    def test_sentences_and_public_domain(self):
        text = ("Court. Le plus éminent des orateurs de la Chambre se leva lentement pour répondre à ses adversaires. "
                "Un éminent.")
        self.assertEqual(quotes.sentences_with(text, word_forms("éminent")),
                         ["Le plus éminent des orateurs de la Chambre se leva lentement pour répondre à ses adversaires."])
        meta = quotes.metadata('<pages index="x" header=1 auteur="[[Auteur:Victor Hugo|Victor Hugo]]" titre="[[Les Misérables]]" annee="1862" />')
        self.assertEqual(meta, {"author": "Victor Hugo", "work": "Les Misérables", "year": 1862})
        self.assertTrue(quotes.public_domain(meta, 1885))
        self.assertFalse(quotes.public_domain({**meta, "year": 1960}, 1885))
        self.assertFalse(quotes.public_domain(meta, None))
        # Chapitre transclus : auteur depuis l'en-tête rendu, année depuis la catégorie.
        rendered = quotes.metadata('<pages index="x" header=1 titre="[[Illusions perdues]]" />',
                                   '<a href="/wiki/Auteur:Honor%C3%A9_de_Balzac">Balzac</a>', ["Romans parus en 1839"], "Illusions perdues/Chapitre")
        self.assertEqual(rendered, {"author": "Honoré de Balzac", "work": "Illusions perdues", "year": 1839})
        self.assertEqual(quotes.clean_work("Stendhal (Paul Valéry)"), "Stendhal")
        self.assertEqual(quotes.clean_work("Centenaire de Diafoirus (Le)"), "Le Centenaire de Diafoirus")
        self.assertEqual(quotes.clean_work("Illusions perdues"), "Illusions perdues")
        # Titre vide : la page racine, pas l'attribut suivant.
        empty = quotes.metadata('<pages index="x" titre="" prev="[[Lysimaque]]" />', "", ["1734"], "Dissertation sur la politique des Romains/1")
        self.assertEqual(empty["work"], "Dissertation sur la politique des Romains")

    def test_text_fetched_only_for_public_domain_works(self):
        sentence = "Le plus éminent des orateurs de la Chambre se leva lentement pour répondre à ses adversaires."
        header = '<pages index="x" titre="[[Les Misérables]]" annee="1862" />'
        described = {
            "Traduction récente": {"wikitext": header, "categories": [], "authors": ["Victor Hugo", "Traducteur Vivant"]},
            "Les Misérables/Tome 1": {"wikitext": header, "categories": [], "authors": ["Armand Carrel", "Victor Hugo"]},
        }
        fetched = []
        def page(title):
            fetched.append(title)
            return f'<div><a href="/wiki/Auteur:Victor_Hugo">Victor Hugo</a>.</div><p>{sentence}</p>'
        deaths = {"Victor Hugo": 1885, "Armand Carrel": 1836}
        found = quotes.quotes_for({"headword": "éminent", "lexique": None}, lambda word: list(described), lambda titles: described,
                                  page, deaths.get)
        # Traducteur vivant : texte jamais téléchargé ; auteur pris dans l'en-tête, pas le premier lien alphabétique.
        self.assertEqual(fetched, ["Les Misérables/Tome 1"])
        self.assertEqual([(quote["text"], quote["author"], quote["work"]) for quote in found], [(sentence, "Victor Hugo", "Les Misérables")])

    def test_only_the_work_text_is_quoted(self):
        rendered = ('<div id="headertemplate"><a href="/wiki/Auteur:Denis_Diderot">Denis Diderot</a> Jacques le Fataliste.</div>'
                    '<div class="ws-summary"><h2>TABLE DES MATIÈRES</h2><div class="tableItem"><span>Où Jacques fait preuve de son habileté au jeu des cartes</span>'
                    '<div class="ws-noexport"><div class="tablePage">12</div></div></div></div>'
                    '<p>Le maître admirait en silence l’habileté avec laquelle Jacques menait son cheval sur la route.<sup class="reference">[1]</sup></p>'
                    '<ol class="references"><li><span class="reference-text">Tronchin n’évita pas l’accusation de charlatanisme malgré son habileté reconnue.</span></li></ol>'
                    '<p>RÉCITS D’UNE TANTE, MÉMOIRES DE LA COMTESSE, AVEC UNE HABILETÉ CONSOMMÉE ET RARE.</p>')
        self.assertEqual(quotes.sentences_with(quotes.visible_text(rendered), word_forms("habileté")),
                         ["Le maître admirait en silence l’habileté avec laquelle Jacques menait son cheval sur la route."])

    def test_work_year_and_quotes_per_work(self):
        sentence = "Le maître admirait en silence l’habileté avec laquelle Jacques menait son cheval sur la route."
        described = {"Jacques le Fataliste et son maître": {"wikitext": '<pages titre="[[Jacques le Fataliste et son maître]]" annee="1875" />',
                                                            "categories": [], "authors": ["Denis Diderot"]}}
        page = lambda title: f'<div><a href="/wiki/Auteur:Denis_Diderot">Denis Diderot</a></div><p>{sentence}</p>'
        used = Counter()
        found = quotes.quotes_for({"headword": "habileté", "lexique": None}, lambda word: list(described), lambda titles: described,
                                  page, lambda author: 1784, lambda title: 1796, used)
        # Année de l'œuvre (Wikidata), pas celle de l'édition numérisée.
        self.assertEqual([quote["year"] for quote in found], [1796])
        used["Jacques le Fataliste et son maître"] = quotes.MAX_PER_WORK
        self.assertEqual(quotes.quotes_for({"headword": "habileté", "lexique": None}, lambda word: list(described), lambda titles: described,
                                           page, lambda author: 1784, lambda title: 1796, used), [])


class Prompts(unittest.TestCase):
    def test_structured_schema(self):
        converted = llm.structured_schema(read_json(SCHEMA_PATH))
        text = json.dumps(converted)
        for keyword in ("maxLength", "pattern", "minItems", "allOf", "inconnu"):
            self.assertNotIn(f'"{keyword}"', text)
        self.assertEqual(set(converted["required"]), set(converted["properties"]))
        self.assertEqual(converted["properties"]["usage"]["anyOf"][1], {"type": "null"})

    def test_finalize_keeps_only_candidate_quotes(self):
        fiche, raw = seed(), raw_for(seed())
        candidate = {"text": "Phrase candidate éminent.", "author": "A", "work": "B", "year": 1850, "url": "https://fr.wikisource.org/wiki/B"}
        written = {**fiche, "id": "x", "family": "nuance", "sources": [], "authorQuote": {**candidate, "url": "https://ailleurs"}}
        result = draft.finalize(written, raw, [candidate])
        self.assertEqual((result["id"], result["family"], result["reviewStatus"]), ("fr.eminent", "paronyme", "draft"))
        self.assertEqual(result["authorQuote"], candidate)
        self.assertIsNone(draft.finalize({**written, "authorQuote": {**candidate, "text": "Inventée."}}, raw, [candidate])["authorQuote"])
        blocks = draft.system_blocks("paronyme", read_json(SEED_PATH), {})
        self.assertTrue(all(block["cache_control"] == {"type": "ephemeral"} for block in blocks))


class Checks(unittest.TestCase):
    schema = read_json(SCHEMA_PATH)

    def problems(self, fiche: dict, sensitive: set[str] = frozenset()) -> list[str]:
        return check.check(fiche, raw_for(seed()), self.schema, set(sensitive), {"eminent": "adjectif", "imminent": "adjectif", "maison": "nom"})

    def test_seed_passes(self):
        self.assertEqual(self.problems(seed()), [])

    def test_failures(self):
        fiche = seed()
        fiche["shortDefinition"] = "Qui se distingue."
        self.assertTrue(any("shortDefinition" in p for p in self.problems(fiche)))
        fiche = seed()
        fiche["examples"][0] = "Un **imminent** départ."
        self.assertTrue(any("exemple" in p for p in self.problems(fiche)))
        fiche = seed()
        fiche["quiz"][0]["choices"] = ["éminent", "remarquable"]
        self.assertTrue(any("synonyme" in p for p in self.problems(fiche)))
        fiche = seed()
        fiche["quiz"][0]["choices"] = ["éminent", "maison"]
        fiche["quiz"][0]["game"] = "motJuste"
        self.assertTrue(any("natures" in p for p in self.problems(fiche)))
        # Paronymes : des natures différentes sont normales (différend / différent).
        fiche["quiz"][0]["game"] = "paronymes"
        self.assertFalse(any("natures" in p for p in self.problems(fiche)))
        fiche = seed()
        fiche["partOfSpeech"] = "verbe"
        self.assertTrue(any("nature" in p for p in self.problems(fiche)))
        self.assertEqual(self.problems(seed(), {"spécialistes"}), ["mot sensible"])
        fiche = seed()
        fiche["phonetic"] = ""
        self.assertTrue(any("phonetic" in p for p in self.problems(fiche)))

    def test_conjugated_phrase_in_examples(self):
        for headword, examples in [("prendre son parti", ["J'en ai **pris mon parti**.", "Elle en **prend son parti**."]),
                                   ("faire fi de", ["Il a **fait fi des** consignes.", "Elle **fait fi de** tout."]),
                                   ("se rappeler", ["Je me **rappelle** ce jour.", "Tu te **rappelles** le code ?"])]:
            fiche = {**seed(), "headword": headword, "examples": examples}
            self.assertFalse(any("exemple" in p for p in self.problems(fiche)), headword)
        fiche = {**seed(), "headword": "faire fi de", "examples": ["Il **ignore** les consignes.", "Elle **fait fi de** tout."]}
        self.assertTrue(any("exemple" in p for p in self.problems(fiche)))
        # Tournure critiquée sans emploi correct : les exemples montrent la forme recommandée (OPEN_QUESTIONS n° 91).
        usage = {"correct": "Elle a personnalisé son téléphone.", "avoid": "Elle a customisé son téléphone.", "verdict": "critique", "explanation": "x"}
        fiche = {**seed(), "headword": "customiser", "family": "anglicisme", "usage": usage,
                 "examples": ["Il a **personnalisé** son vélo.", "Elle a **personnalisé** son téléphone."]}
        self.assertFalse(any("exemple" in p for p in self.problems(fiche)))
        self.assertTrue(any("exemple" in p for p in self.problems({**fiche, "usage": {**usage, "verdict": "tolere"}})))

    def test_english_legacy_fiche_is_valid(self):
        fiche = convert_v3_en.convert([{"Rank": "1", "List": "1k", "Headword": "otiose", "Definition": "Otiose refers to something useless.",
                                        "Context sentence": "His efforts were otiose.", "Synonyms": "useless, idle", "Topic": "other"}] +
                                       [{"Rank": str(n), "List": "2k", "Headword": f"word{n}", "Definition": f"Meaning number {n}.",
                                         "Context sentence": "", "Synonyms": "", "Topic": "other"} for n in range(2, 6)])[0]
        self.assertEqual(schema.errors(fiche, self.schema), [])


class EnglishLegacy(unittest.TestCase):
    def test_helpers(self):
        self.assertEqual(convert_v3_en.short_definition("otiose", "Otiose refers to something that is useless."), "Something that is useless")
        long = convert_v3_en.short_definition("x", "A " + "very " * 40 + "long definition.")
        self.assertLessEqual(len(long), 90)
        self.assertTrue(long.endswith("…"))
        self.assertEqual(convert_v3_en.marked_example("hemisphere", "Two hemispheres."), "Two **hemispheres**.")
        self.assertIsNone(convert_v3_en.marked_example("cat", "No match here."))
        self.assertEqual([convert_v3_en.level(name) for name in ("1k", "3k", "10k", "15k", "25k", "digital marketing")], [1, 2, 3, 4, 5, 3])

    def test_quiz_never_offers_a_synonym(self):
        entries = [{"Rank": str(n), "List": "1k", "Headword": f"w{n}", "Definition": f"Definition {n}.", "Context sentence": f"Use w{n} now.",
                    "Synonyms": "w1, w2" if n == 0 else "", "Topic": "other"} for n in range(30)]
        fiches = convert_v3_en.convert(entries)
        first = fiches[0]
        self.assertEqual(len(first["quiz"]), 1)
        wrong = [choice for index, choice in enumerate(first["quiz"][0]["choices"]) if index != first["quiz"][0]["answerIndex"]]
        self.assertNotIn("Definition 1", wrong)
        self.assertNotIn("Definition 2", wrong)
        self.assertEqual(len({fiche["id"] for fiche in fiches}), 30)


class ReviewAndBuild(unittest.TestCase):
    def test_queue_and_error_rate(self):
        ids = [f"fr.m{n:03d}" for n in range(450)]
        items = review.queue(ids, {"fr.m001", "fr.m002"})
        self.assertEqual([item["id"] for item in items[:2]], ["fr.m001", "fr.m002"])
        sampled = [item for item in items if item["sample"]]
        self.assertEqual(len(sampled), 20 + 20 + 5)  # 10 % de 200, 200 et 48
        decisions = [{"id": "a", "action": "valider", "echantillon": "oui"}, {"id": "b", "action": "corriger", "echantillon": "oui"},
                     {"id": "c", "action": "rejeter", "echantillon": "non"}]
        self.assertEqual(review.error_rate(decisions)[:2], (1, 2))

    def test_build_excludes_rejected_and_unreviewed_flagged(self):
        with tempfile.TemporaryDirectory() as folder:
            work = Path(folder)
            for name in ("fr.ok", "fr.flagged", "fr.fixed", "fr.rejected"):
                write_json(work / "checked" / f"{name}.json", {**seed(), "id": name, "reviewStatus": "autoChecked"})
            for name in ("fr.flagged", "fr.fixed"):
                write_json(work / "critic" / f"{name}.json", {"ok": False, "problems": [{"field": "x", "issue": "y", "severity": "bloquant"}]})
            write_json(work / "reviewed" / "fr.fixed.json", {**seed(), "id": "fr.fixed", "reviewStatus": "humanChecked"})
            (work / "review").mkdir()
            (work / "review" / "decisions.csv").write_text("id,action,raison,echantillon,date\nfr.fixed,corriger,,non,\nfr.rejected,rejeter,,oui,\n", encoding="utf-8")
            fiches = build.assemble(work)
            self.assertEqual({fiche["id"]: fiche["reviewStatus"] for fiche in fiches}, {"fr.ok": "autoChecked", "fr.fixed": "humanChecked"})
            out, version = work / "pack.json", work / "pack.version"
            build.run(work, out, version)
            build.run(work, out, version)
            self.assertEqual(version.read_text().strip(), "2")


if __name__ == "__main__":
    unittest.main()


class AgentMode(unittest.TestCase):
    """Sans clé API : export des entrées, réponse d'un agent, import avec les mêmes règles d'ancrage que l'API."""

    def test_draft_and_critic_round_trip(self):
        fiche = seed()
        raw = raw_for(fiche)
        with tempfile.TemporaryDirectory() as folder:
            work = Path(folder)
            (work / "candidats.csv").write_text(f"id,headword,family\n{fiche['id']},{fiche['headword']},{fiche['family']}\n", encoding="utf-8")
            write_json(work / "raw" / f"{fiche['id']}.json", raw)
            self.assertEqual(agent.export("draft", work), [fiche["id"]])
            self.assertIn(draft.RULES, (work / "agent" / "draft" / "CONSIGNES.md").read_text(encoding="utf-8"))

            answer = {**fiche, "id": "fr.autre", "reviewStatus": "humanChecked",
                      "authorQuote": {"text": "Phrase inventée", "author": "X", "work": "Y", "year": 1850, "url": "https://fr.wikisource.org/x"}}
            write_json(work / "agent" / "draft" / "out" / f"{fiche['id']}.json", answer)
            (work / "agent" / "draft" / "out" / "fr.casse.json").write_text("{", encoding="utf-8")
            imported, failures = agent.import_outputs("draft", work)
            self.assertEqual(imported, 1)
            self.assertEqual(len(failures), 1)
            drafted = read_json(work / "drafts" / f"{fiche['id']}.json")
            self.assertEqual((drafted["id"], drafted["reviewStatus"], drafted["authorQuote"]), (fiche["id"], "draft", None))
            # Déjà rédigée : plus rien à exporter.
            self.assertEqual(agent.export("draft", work), [])

            write_json(work / "checked" / f"{fiche['id']}.json", drafted)
            self.assertEqual(agent.export("critic", work), [fiche["id"]])
            write_json(work / "agent" / "critic" / "out" / f"{fiche['id']}.json", {"ok": True, "problems": []})
            self.assertEqual(agent.import_outputs("critic", work)[0], 1)
            self.assertTrue((work / "critic" / f"{fiche['id']}.json").exists())

    def test_usage_pitfall_must_be_sourced(self):
        fiche = seed()
        with tempfile.TemporaryDirectory() as folder:
            work = Path(folder)
            rows = ["id,headword,family"]
            for identifier, note in (("fr.excuser", None), ("fr.solutionner", "Dupré juge l'emploi critiqué : préférer résoudre.")):
                raw = {**raw_for(fiche), "id": identifier, "family": "impropriete"}
                raw["wiktionary"] = {**raw["wiktionary"], "notes": [note] if note else [], "markers": []}
                write_json(work / "raw" / f"{identifier}.json", raw)
                rows.append(f"{identifier},{identifier[3:]},impropriete")
            (work / "candidats.csv").write_text("\n".join(rows) + "\n", encoding="utf-8")
            # Impropriété que le Wiktionnaire ne confirme pas : pas rédigée, listée pour Hugo.
            self.assertEqual([identifier for identifier, _, _ in draft.pending(work, None)], ["fr.solutionner"])
            self.assertIn("fr.excuser", (work / "sans_source.csv").read_text(encoding="utf-8"))
