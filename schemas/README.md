# Codex JSON Schemas

This directory contains JSON Schema definitions for validating Codex document components.

## Schema Files

| Schema | Purpose | Validates |
|--------|---------|-----------|
| `manifest.schema.json` | Document manifest | `manifest.json` |
| `content.schema.json` | Semantic content blocks | `content/document.json` |
| `presentation.schema.json` | Presentation layer | `presentation/*.json` |
| `precise-layout.schema.json` | Precise layouts | `presentation/layouts/*.json` |
| `asset-index.schema.json` | Asset index | `assets/index.json` |
| `dublin-core.schema.json` | Dublin Core metadata | `metadata/dublin-core.json` |
| `provenance.schema.json` | Provenance records | `provenance/record.json` |
| `anchor.schema.json` | Content anchor definitions | (shared definitions) |
| `annotations.schema.json` | Core annotations | `security/annotations.json` |
| `phantoms.schema.json` | Phantom clusters | `phantoms/clusters.json` |

## Schema Dependencies

Some schemas reference definitions from other schema files:

```
annotations.schema.json
    └── $ref: anchor.schema.json#/$defs/contentAnchor

phantoms.schema.json
    └── $ref: anchor.schema.json#/$defs/contentAnchor
```

The `anchor.schema.json` file provides shared definitions for `ContentAnchor` and `ContentAnchorUri` that are used by core annotations, phantoms, collaboration, and other extensions.

## Using These Schemas

### With ajv (Node.js)

```bash
npm install -g ajv-cli

# Validate a manifest
ajv validate -s schemas/manifest.schema.json -d document.cdx/manifest.json

# Validate with referenced schemas (for phantoms)
ajv validate -s schemas/phantoms.schema.json -r schemas/anchor.schema.json -d document.cdx/phantoms/clusters.json
```

### With jsonschema (Python)

```python
import json
from jsonschema import validate, RefResolver

# Load schemas
with open('schemas/manifest.schema.json') as f:
    schema = json.load(f)

with open('document.cdx/manifest.json') as f:
    document = json.load(f)

validate(instance=document, schema=schema)
```

For schemas with references, use a RefResolver:

```python
from jsonschema import RefResolver

schema_store = {}
for schema_file in ['anchor.schema.json', 'phantoms.schema.json']:
    with open(f'schemas/{schema_file}') as f:
        schema = json.load(f)
        schema_store[schema['$id']] = schema

resolver = RefResolver.from_schema(schema_store['https://codex.document/schemas/phantoms.schema.json'], store=schema_store)
validate(instance=document, schema=phantoms_schema, resolver=resolver)
```

### With check-jsonschema (CLI)

```bash
pip install check-jsonschema

check-jsonschema --schemafile schemas/manifest.schema.json document.cdx/manifest.json
```

## Schema Version

All schemas are written for JSON Schema Draft 2020-12 (`https://json-schema.org/draft/2020-12/schema`).

## Validation Notes

- Schemas use `additionalProperties: false` on most objects to catch typos and invalid properties
- The `metadata` object in `phantoms.schema.json` intentionally allows additional properties for application-specific extensibility
- The `styles` object in `presentation.schema.json` allows arbitrary named styles, but each style definition is strictly validated
