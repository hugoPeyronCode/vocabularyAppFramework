"""Appels à l'API Claude des étapes draft et critic : Batches API par défaut (moitié prix), mode synchrone
pour les petits essais. Sortie JSON contrainte par schéma (structured outputs).
"""
from __future__ import annotations

import copy
import json
import time
from dataclasses import dataclass
from typing import Any

MODEL = "claude-opus-5-5"
# Prix publics par million de jetons (Batches API : moitié prix).
PRICE_INPUT, PRICE_OUTPUT = 4.00, 20.00
# Les sources longues tiennent dans le contexte ; la sortie (fiche ou rapport) reste courte.
MAX_TOKENS = 16_000
POLL_SECONDS = 60

# Mots-clés de validation non nécessaires à la génération : vérifiés ensuite par l'étape check.
_STRIPPED = {"$schema", "$id", "$comment", "title", "pattern", "minLength", "maxLength", "minimum", "maximum", "minItems", "maxItems",
             "format", "allOf", "if", "then", "not"}


def structured_schema(schema: dict[str, Any]) -> dict[str, Any]:
    """Schéma de fiche adapté aux structured outputs : contraintes de longueur retirées, types nullables en anyOf,
    toutes les propriétés requises."""
    def convert(node: Any) -> Any:
        if isinstance(node, list):
            return [convert(item) for item in node]
        if not isinstance(node, dict):
            return node
        node = {key: convert(value) for key, value in node.items() if key not in _STRIPPED}
        # Une fiche rédigée est française : la nature « inconnu » du pack anglais historique n'est pas proposée.
        if isinstance(node.get("enum"), list) and "inconnu" in node["enum"]:
            node["enum"] = [value for value in node["enum"] if value != "inconnu"]
        kind = node.get("type")
        if isinstance(kind, list) and "null" in kind:
            other = [item for item in kind if item != "null"][0]
            rest = {key: value for key, value in node.items() if key != "type"}
            return {"anyOf": [{"type": other, **rest}, {"type": "null"}]}
        if node.get("type") == "object" and "properties" in node:
            node["required"] = list(node["properties"])
            node["additionalProperties"] = False
        return node
    return convert(copy.deepcopy(schema))


def estimate(requests: list[dict[str, Any]], batch: bool) -> str:
    """Estimation grossière (≈ 3,5 caractères par jeton, réflexion comprise dans la sortie)."""
    chars = sum(len(json.dumps(request["params"]["system"], ensure_ascii=False)) + len(json.dumps(request["params"]["messages"], ensure_ascii=False)) for request in requests)
    input_tokens = chars / 3.5
    output_tokens = len(requests) * 4_000
    factor = 0.5 if batch else 1.0
    cost = factor * (input_tokens * PRICE_INPUT + output_tokens * PRICE_OUTPUT) / 1_000_000
    return f"{len(requests)} requêtes, ~{input_tokens / 1e6:.2f} M jetons d'entrée, ~{output_tokens / 1e6:.2f} M de sortie, ~{cost:.0f} $ (sans le gain du cache)"


@dataclass
class Result:
    custom_id: str
    text: str | None
    error: str | None = None


def params(system: list[dict[str, Any]], user: str, schema: dict[str, Any], effort: str = "high") -> dict[str, Any]:
    return {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "system": system,
        "messages": [{"role": "user", "content": user}],
        "output_config": {"effort": effort, "format": {"type": "json_schema", "schema": schema}},
    }


def _text(message: Any) -> tuple[str | None, str | None]:
    if message.stop_reason == "refusal":
        return None, f"refus ({getattr(message.stop_details, 'category', None)})"
    if message.stop_reason == "max_tokens":
        return None, "réponse tronquée (max_tokens)"
    text = next((block.text for block in message.content if block.type == "text"), None)
    return text, None if text else "aucun texte"


def run_batch(requests: list[dict[str, Any]]) -> list[Result]:
    import anthropic
    from anthropic.types.message_create_params import MessageCreateParamsNonStreaming
    from anthropic.types.messages.batch_create_params import Request

    client = anthropic.Anthropic()
    batch = client.messages.batches.create(requests=[
        Request(custom_id=request["custom_id"], params=MessageCreateParamsNonStreaming(**request["params"])) for request in requests
    ])
    print(f"lot {batch.id} envoyé ({len(requests)} requêtes)")
    while (batch := client.messages.batches.retrieve(batch.id)).processing_status != "ended":
        print(f"  en cours : {batch.request_counts.processing} restantes")
        time.sleep(POLL_SECONDS)
    results = []
    for item in client.messages.batches.results(batch.id):
        if item.result.type == "succeeded":
            text, error = _text(item.result.message)
            results.append(Result(item.custom_id, text, error))
        else:
            results.append(Result(item.custom_id, None, item.result.type))
    return results


def run_sync(requests: list[dict[str, Any]]) -> list[Result]:
    """Petits essais : requêtes une à une. En cas de refus, l'API rejoue la requête sur un modèle de repli
    (`fallbacks: "default"`), ce que la Batches API ne permet pas."""
    import anthropic

    client = anthropic.Anthropic()
    results = []
    for request in requests:
        try:
            message = client.beta.messages.create(**request["params"], betas=["server-side-fallback-2026-07-01"], fallbacks="default")
            text, error = _text(message)
        except anthropic.BadRequestError as error_:
            text, error = None, f"requête invalide : {error_.message}"
        except anthropic.RateLimitError:
            time.sleep(30)
            text, error = None, "limite de débit (relancer)"
        except anthropic.APIStatusError as error_:
            text, error = None, f"erreur API {error_.status_code}"
        except anthropic.APIConnectionError:
            text, error = None, "erreur réseau (relancer)"
        results.append(Result(request["custom_id"], text, error))
    return results
