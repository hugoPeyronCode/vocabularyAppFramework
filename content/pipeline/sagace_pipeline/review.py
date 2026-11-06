"""Étape 7 : relecture par Hugo (`05_CONTENT.md` section 3.6). Page locale : la fiche rendue comme dans l'app,
les extraits sources à côté, boutons Valider, Corriger, Rejeter.

À relire : toutes les fiches signalées par critic, plus 10 % des autres tirées au hasard par lot de 200.
Les décisions vont dans `work/review/decisions.csv` ; une fiche validée ou corrigée devient `humanChecked`.
"""
from __future__ import annotations

import datetime
import html
import json
import random
import re
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any

from .common import (REVIEW_BATCH, REVIEW_MAX_ERROR_RATE, REVIEW_SAMPLE, SCHEMA_PATH, WORK, read_csv, read_json,
                     stage_dir, write_csv, write_json)
from .critic import is_flagged

DECISIONS = ["id", "action", "raison", "echantillon", "date"]


def queue(ids: list[str], flagged: set[str], seed: int = 4) -> list[dict[str, Any]]:
    """Signalées d'abord, puis l'échantillon aléatoire (10 % de chaque lot de 200 non signalées)."""
    rng = random.Random(seed)
    others = [identifier for identifier in sorted(ids) if identifier not in flagged]
    sample: list[str] = []
    for start in range(0, len(others), REVIEW_BATCH):
        batch = others[start:start + REVIEW_BATCH]
        sample += rng.sample(batch, max(1, round(len(batch) * REVIEW_SAMPLE))) if batch else []
    return [{"id": identifier, "sample": False} for identifier in sorted(flagged & set(ids))] + [{"id": identifier, "sample": True} for identifier in sorted(sample)]


def error_rate(decisions: list[dict[str, str]]) -> tuple[int, int, float]:
    """Taux d'erreur de l'échantillon aléatoire : fiches corrigées ou rejetées / fiches relues."""
    sampled = [row for row in decisions if row["echantillon"] == "oui"]
    errors = sum(row["action"] in ("corriger", "rejeter") for row in sampled)
    return errors, len(sampled), errors / len(sampled) if sampled else 0.0


def latest(decisions: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    return {row["id"]: row for row in decisions}


def render_fiche(fiche: dict[str, Any]) -> str:
    e = lambda value: html.escape(str(value or ""))
    bold = lambda text: re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", e(text))
    parts = [f"<p class=meta>{e(fiche.get('family'))} · niveau {e(fiche.get('level'))}</p>",
             f"<h1>{e(fiche.get('headword'))}</h1>",
             f"<p class=meta>{e(fiche.get('partOfSpeech'))} {e(fiche.get('gender') or '')} · {e(fiche.get('phonetic'))}</p>",
             f"<p class=def>{e(fiche.get('shortDefinition'))}</p><p>{e(fiche.get('definition'))}</p>"]
    for confusion in fiche.get("confusions", []):
        parts.append(f"<p><span class=chip>{e(confusion['word'])}</span> {e(confusion['meaning'])}<br><i>{e(confusion['example'])}</i></p>")
    if usage := fiche.get("usage"):
        parts.append(f"<p>✔︎ On dit : {e(usage['correct'])}<br>✘ On évite : {e(usage['avoid'])} <span class=chip>{e(usage['verdict'])}</span><br>{e(usage['explanation'])}</p>")
    if fiche.get("nuance"):
        parts.append(f"<p><b>Nuance</b> : {e(fiche['nuance'])}</p>")
    parts.append("<ul>" + "".join(f"<li>{bold(example)}</li>" for example in fiche.get("examples", [])) + "</ul>")
    if quote := fiche.get("authorQuote"):
        parts.append(f"<blockquote>« {e(quote['text'])} »<br>{e(quote['author'])}, <a href='{e(quote['url'])}'>{e(quote['work'])}</a> ({e(quote['year'])})</blockquote>")
    for item in fiche.get("quiz", []):
        choices = "".join(f"<li{' class=ok' if index == item['answerIndex'] else ''}>{e(choice)}</li>" for index, choice in enumerate(item["choices"]))
        parts.append(f"<div class=quiz><b>{e(item['game'])}</b> {e(item['prompt'])}<ol start=0>{choices}</ol><small>{e(item['explanation'])}</small></div>")
    parts.append("<p class=meta>Sources : " + ", ".join(f"<a href='{e(s['url'])}'>{e(s['name'])}</a>" for s in fiche.get("sources", [])) + "</p>")
    return "".join(parts)


STYLE = """body{font:15px -apple-system,system-ui;margin:0;background:#f2f2f2;color:#111}main{display:grid;grid-template-columns:420px 1fr;gap:16px;padding:16px}
.card{background:#fff;border-radius:24px;padding:20px}h1{font-size:34px;margin:4px 0}.meta{color:#777}.def{font-size:17px}
.chip{background:#eee;border-radius:12px;padding:2px 8px}.quiz{background:#f7f7f7;border-radius:12px;padding:8px;margin:8px 0}.ok{font-weight:bold;color:#1a7f37}
pre{white-space:pre-wrap;font-size:12px}textarea{width:100%;height:260px;font:12px ui-monospace}button{font-size:15px;padding:8px 14px;border-radius:18px;border:0;margin-right:6px}
.flag{color:#b42318}a{color:#2b5ce6}"""


def page(title: str, body: str) -> bytes:
    return f"<!doctype html><meta charset=utf-8><title>{html.escape(title)}</title><style>{STYLE}</style>{body}".encode()


class Review:
    def __init__(self, work: Path):
        self.work = work
        self.decisions_path = stage_dir("review", work) / "decisions.csv"
        checked = [path.stem for path in (work / "checked").glob("*.json")]
        flagged = {path.stem for path in (work / "critic").glob("*.json") if is_flagged(read_json(path))}
        self.items = queue(checked, flagged)
        self.flagged = flagged

    def decisions(self) -> list[dict[str, str]]:
        return read_csv(self.decisions_path)

    def decide(self, identifier: str, action: str, reason: str, edited: str | None) -> None:
        sample = next((item["sample"] for item in self.items if item["id"] == identifier), False)
        rows = self.decisions() + [{"id": identifier, "action": action, "raison": reason, "echantillon": "oui" if sample else "non",
                                    "date": datetime.datetime.now().isoformat(timespec="seconds")}]
        write_csv(self.decisions_path, rows, DECISIONS)
        reviewed = stage_dir("reviewed", self.work) / f"{identifier}.json"
        if action == "rejeter":
            reviewed.unlink(missing_ok=True)
            return
        fiche = json.loads(edited) if action == "corriger" and edited else read_json(self.work / "checked" / f"{identifier}.json")
        write_json(reviewed, {**fiche, "reviewStatus": "humanChecked"})

    def index(self) -> bytes:
        done = latest(self.decisions())
        errors, sampled, rate = error_rate(self.decisions())
        verdict = "au-dessus du seuil : le lot repasse par draft" if rate > REVIEW_MAX_ERROR_RATE else "sous le seuil de 2 %"
        rows = "".join(
            f"<li><a href='/fiche/{item['id']}'>{item['id']}</a> {'<span class=flag>signalée</span>' if not item['sample'] else 'échantillon'}"
            f" — {done[item['id']]['action'] if item['id'] in done else 'à relire'}</li>" for item in self.items)
        body = (f"<main style='display:block'><div class=card><h1>Relecture</h1><p>{len(done)}/{len(self.items)} relues · "
                f"échantillon : {errors} erreurs sur {sampled} ({rate:.1%}), {verdict}</p><ol>{rows}</ol></div></main>")
        return page("Relecture Sagace", body)

    def fiche(self, identifier: str) -> bytes:
        fiche = read_json(self.work / "checked" / f"{identifier}.json")
        raw = read_json(self.work / "raw" / f"{identifier}.json")
        critic_path = self.work / "critic" / f"{identifier}.json"
        report = read_json(critic_path) if critic_path.exists() else {"problems": []}
        problems = "".join(f"<li class={'flag' if p['severity'] == 'bloquant' else 'meta'}>{html.escape(p['field'])} : {html.escape(p['issue'])}</li>" for p in report["problems"])
        position = next((index for index, item in enumerate(self.items) if item["id"] == identifier), -1)
        following = self.items[position + 1]["id"] if 0 <= position < len(self.items) - 1 else ""
        form = (f"<form method=post action='/decision/{identifier}'><input type=hidden name=next value='{following}'>"
                f"<p><input name=raison placeholder='Raison (correction ou rejet)' style='width:100%'></p>"
                f"<textarea name=json>{html.escape(json.dumps(fiche, ensure_ascii=False, indent=2))}</textarea>"
                f"<p><button name=action value=valider>Valider</button><button name=action value=corriger>Corriger (JSON modifié)</button>"
                f"<button name=action value=rejeter>Rejeter</button> <a href='/'>Liste</a></p></form>")
        body = (f"<main><div class=card>{render_fiche(fiche)}<h3>Correcteur</h3><ul>{problems or '<li>RAS</li>'}</ul></div>"
                f"<div class=card><h3>Extraits sources</h3><pre>{html.escape(json.dumps(raw, ensure_ascii=False, indent=2))}</pre>{form}</div></main>")
        return page(identifier, body)


def serve(work: Path = WORK, port: int = 8765) -> None:
    review = Review(work)

    class Handler(BaseHTTPRequestHandler):
        def send(self, content: bytes, status: int = 200, location: str | None = None) -> None:
            self.send_response(status)
            if location:
                self.send_header("Location", location)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(content)

        def do_GET(self) -> None:
            if self.path.startswith("/fiche/"):
                self.send(review.fiche(urllib.parse.unquote(self.path.removeprefix("/fiche/"))))
            else:
                self.send(review.index())

        def do_POST(self) -> None:
            length = int(self.headers.get("Content-Length", 0))
            form = {key: values[0] for key, values in urllib.parse.parse_qs(self.rfile.read(length).decode()).items()}
            identifier = urllib.parse.unquote(self.path.removeprefix("/decision/"))
            review.decide(identifier, form.get("action", "valider"), form.get("raison", ""), form.get("json"))
            self.send(b"", 303, f"/fiche/{form['next']}" if form.get("next") else "/")

        def log_message(self, *args: Any) -> None:
            pass

    print(f"Relecture : http://localhost:{port} ({len(review.items)} fiches à relire, {len(review.flagged)} signalées)")
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
