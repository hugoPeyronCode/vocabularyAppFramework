"""Validation JSON Schema du sous-ensemble utilisé par `content/schema/fiche.schema.json`
(type, enum, const, not, required, properties, additionalProperties, items, longueurs, motifs, bornes, allOf, if/then).
Bibliothèque standard seulement : le pipeline tourne sans dépendance hors des étapes IA.
"""
from __future__ import annotations

import re
from typing import Any

TYPES = {"object": dict, "array": list, "string": str, "integer": int, "boolean": bool, "null": type(None)}


def _is(value: Any, kind: str) -> bool:
    if kind == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    return isinstance(value, TYPES[kind])


def errors(value: Any, schema: dict[str, Any], path: str = "") -> list[str]:
    found: list[str] = []
    where = path or "fiche"
    if "type" in schema:
        kinds = schema["type"] if isinstance(schema["type"], list) else [schema["type"]]
        if not any(_is(value, kind) for kind in kinds):
            return [f"{where} : type attendu {'/'.join(kinds)}"]
    if "enum" in schema and value not in schema["enum"]:
        found.append(f"{where} : {value!r} hors de {schema['enum']}")
    if "const" in schema and value != schema["const"]:
        found.append(f"{where} : {value!r} ≠ {schema['const']!r}")
    if "not" in schema and not errors(value, schema["not"], path):
        found.append(f"{where} : valeur interdite {value!r}")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            found.append(f"{where} : trop court")
        if "maxLength" in schema and len(value) > schema["maxLength"]:
            found.append(f"{where} : plus de {schema['maxLength']} caractères")
        if "pattern" in schema and re.search(schema["pattern"], value) is None:
            found.append(f"{where} : ne respecte pas {schema['pattern']}")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            found.append(f"{where} : inférieur à {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            found.append(f"{where} : supérieur à {schema['maximum']}")
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            found.append(f"{where} : au moins {schema['minItems']} éléments")
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            found.append(f"{where} : au plus {schema['maxItems']} éléments")
        if "items" in schema:
            for index, item in enumerate(value):
                found += errors(item, schema["items"], f"{path}[{index}]")
    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                found.append(f"{where} : champ {key} manquant")
        properties = schema.get("properties", {})
        for key, item in value.items():
            if key in properties:
                found += errors(item, properties[key], f"{path}.{key}" if path else key)
            elif schema.get("additionalProperties") is False:
                found.append(f"{where} : champ inattendu {key}")
    for part in schema.get("allOf", []):
        found += errors(value, part, path)
    if "if" in schema and not errors(value, schema["if"], path) and "then" in schema:
        found += errors(value, schema["then"], path)
    return found
