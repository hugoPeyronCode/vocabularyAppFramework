"""`python -m sagace_pipeline <étape>` depuis `content/pipeline/` (voir README.md)."""
from __future__ import annotations

import argparse
from pathlib import Path

from .common import WORK


def main() -> None:
    parser = argparse.ArgumentParser(prog="sagace_pipeline", description="Pipeline de contenu de Sagace (05_CONTENT.md).")
    parser.add_argument("--work", type=Path, default=WORK, help="dossier de travail (défaut : content/pipeline/work)")
    steps = parser.add_subparsers(dest="step", required=True)
    select = steps.add_parser("select", help="1. candidats")
    select.add_argument("--lexique", type=Path, required=True, help="Lexique383.tsv")
    gather = steps.add_parser("gather", help="2. extraits bruts")
    gather.add_argument("--lexique", type=Path, required=True)
    gather.add_argument("--littre", type=Path, help="dossier XMLittré (*.xml)")
    gather.add_argument("--lafaye", type=Path, help="texte brut du Lafaye")
    gather.add_argument("--limit", type=int)
    quotes = steps.add_parser("quotes", help="3. phrases d'auteur (Wikisource)")
    quotes.add_argument("--limit", type=int)
    for name, text in (("draft", "4. rédaction (agents ou API Claude)"), ("critic", "6. relecture par l'IA (agents ou API Claude)")):
        step = steps.add_parser(name, help=text)
        step.add_argument("--agent", choices=["export", "import"],
                          help="sans clé API : exporter les entrées pour des agents Claude Code, puis importer leurs réponses")
        step.add_argument("--sync", action="store_true", help="une requête à la fois (petits essais) au lieu de la Batches API")
        step.add_argument("--confirm", action="store_true", help="envoyer réellement (sinon : estimation seule)")
        if name == "draft":
            step.add_argument("--limit", type=int, help="nombre de candidats (lot test : 200)")
    check = steps.add_parser("check", help="5. contrôles automatiques")
    check.add_argument("--lexique", type=Path, help="pour vérifier la nature des choix de quiz")
    review = steps.add_parser("review", help="7. interface de relecture")
    review.add_argument("--port", type=int, default=8765)
    steps.add_parser("build", help="8. pack de l'app")
    steps.add_parser("convert-en", help="pack anglais historique (v3)")
    args = parser.parse_args()
    args.work.mkdir(parents=True, exist_ok=True)

    if args.step == "select":
        from . import select as step
        step.run(args.lexique, args.work)
    elif args.step == "gather":
        from . import gather as step
        step.run(args.lexique, args.littre, args.lafaye, args.work, args.limit)
    elif args.step == "quotes":
        from . import quotes as step
        step.run(args.work, args.limit)
    elif args.step in ("draft", "critic") and args.agent:
        from . import agent
        if args.agent == "export":
            agent.export(args.step, args.work, getattr(args, "limit", None))
        else:
            agent.import_outputs(args.step, args.work)
            if args.step == "critic":
                from . import critic
                critic.write_report(args.work)
    elif args.step == "draft":
        from . import draft as step
        step.run(args.work, args.limit, args.sync, args.confirm)
    elif args.step == "check":
        from . import check as step
        step.run(args.work, args.lexique)
    elif args.step == "critic":
        from . import critic as step
        step.run(args.work, args.sync, args.confirm)
    elif args.step == "review":
        from . import review as step
        step.serve(args.work, args.port)
    elif args.step == "build":
        from . import build as step
        step.run(args.work)
    elif args.step == "convert-en":
        from . import convert_v3_en as step
        step.run()


if __name__ == "__main__":
    main()
