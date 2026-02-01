# Semantic Extension

**Extension ID**: `codex.semantic`
**Version**: 0.1
**Status**: Draft

## 1. Overview

The Semantic Extension enhances documents with rich semantic markup:

- JSON-LD embedding for knowledge graph integration
- Citation and bibliography management
- Structured data annotations
- Entity linking

## 2. Extension Declaration

```json
{
  "extensions": [
    {
      "id": "codex.semantic",
      "version": "0.1",
      "required": false
    }
  ]
}
```

## 3. JSON-LD Integration

### 3.1 Document-Level Metadata

Location: `metadata/jsonld.json`

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "dcterms": "http://purl.org/dc/terms/"
  },
  "@type": "ScholarlyArticle",
  "name": "A Study on Document Formats",
  "author": {
    "@type": "Person",
    "name": "Jane Doe",
    "affiliation": {
      "@type": "Organization",
      "name": "University Research Lab"
    }
  },
  "datePublished": "2025-01-15",
  "keywords": ["document formats", "semantic web", "digital documents"]
}
```

### 3.2 Block-Level Annotations

```json
{
  "type": "paragraph",
  "id": "definition-1",
  "semantic": {
    "@type": "DefinedTerm",
    "name": "Semantic Document",
    "description": "A document with machine-readable meaning"
  },
  "children": [...]
}
```

## 4. Citations

### 4.1 Citation Mark

```json
{
  "type": "text",
  "value": "according to recent research",
  "marks": [
    {
      "type": "citation",
      "refs": ["smith2024", "jones2023"],
      "locator": "42-45",
      "prefix": "see",
      "suffix": "for details"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"citation"` |
| `refs` | array | Yes | Bibliography entry IDs to cite |
| `locator` | string | No | Page, chapter, section, or other location reference (CSL-compatible) |
| `prefix` | string | No | Text to display before the citation (e.g., "see", "cf.") |
| `suffix` | string | No | Text to display after the citation |
| `suppressAuthor` | boolean | No | If true, omit the author name from the rendered citation |

**Note:** The `pages` field is deprecated in favor of `locator`, which supports a wider range of locator types per CSL specifications. Implementations SHOULD accept both for backwards compatibility.

### 4.2 Bibliography Entry

Bibliography entries follow the [CSL JSON schema](https://citeproc-js.readthedocs.io/en/latest/csl-json/markup.html) for entry types, fields, and formatting conventions.

Location: `semantic/bibliography.json`

```json
{
  "version": "0.1",
  "style": "apa",
  "entries": [
    {
      "id": "smith2024",
      "type": "article-journal",
      "title": "Advances in Document Processing",
      "author": [
        { "family": "Smith", "given": "John" },
        { "family": "Johnson", "given": "Emily" }
      ],
      "issued": { "year": 2024 },
      "container-title": "Journal of Digital Documents",
      "volume": 15,
      "issue": 3,
      "page": "234-256",
      "DOI": "10.1234/jdd.2024.001"
    }
  ]
}
```

### 4.3 Citation Styles

Supported styles:
- APA (7th edition)
- MLA (9th edition)
- Chicago (17th edition)
- IEEE
- Harvard
- Vancouver

### 4.4 Bibliography Block

The bibliography block renders citations. It can reference an external bibliography file or include inline entries.

**External reference (recommended for reuse):**

```json
{
  "type": "semantic:bibliography",
  "style": "apa",
  "title": "References",
  "filter": null
}
```

**Inline entries (self-contained documents):**

```json
{
  "type": "semantic:bibliography",
  "style": "apa",
  "title": "References",
  "entries": [
    {
      "id": "smith2024",
      "type": "article-journal",
      "title": "Advances in Document Processing",
      "author": [
        { "family": "Smith", "given": "John" }
      ],
      "issued": { "date-parts": [[2024]] },
      "container-title": "Journal of Digital Documents",
      "volume": 15,
      "page": "234-256",
      "DOI": "10.1234/jdd.2024.001",
      "renderedText": "Smith, J. (2024). Advances in Document Processing. <i>Journal of Digital Documents</i>, 15, 234-256."
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"semantic:bibliography"` |
| `style` | string | No | Citation style (apa, mla, chicago, ieee, harvard, vancouver) |
| `title` | string | No | Section heading for the bibliography |
| `filter` | string\|null | No | Filter expression for selective bibliography |
| `entries` | array | No | Inline CSL JSON entries (alternative to external file) |

When `entries` is provided, each entry MAY include a `renderedText` field containing pre-rendered citation text from citeproc. This enables accurate display without requiring a CSL processor in the reader.

### 4.5 Footnotes

Footnotes provide numbered references to supplementary content. The semantic extension defines the footnote content; the presentation extension (section 10) controls footnote styling and positioning.

#### 4.5.1 Footnote Mark

Use a footnote mark on text to create a footnote reference:

```json
{
  "type": "text",
  "value": "important claim",
  "marks": [
    {
      "type": "footnote",
      "number": 1,
      "id": "fn1"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"footnote"` |
| `number` | integer | No | Sequential footnote number (required if `symbol` not used) |
| `symbol` | string | No | Symbol-based footnote marker (required if `number` not used) |
| `id` | string | No | Unique footnote identifier for cross-referencing |

Either `number` or `symbol` MUST be provided, but not both.

#### 4.5.1a Symbol Footnotes

For author footnotes on title pages and special contexts, symbol-based footnotes provide a non-numeric sequence:

```json
{
  "type": "text",
  "value": "Corresponding author",
  "marks": [
    {
      "type": "footnote",
      "symbol": "dagger",
      "id": "fn-corresponding"
    }
  ]
}
```

| Symbol Value | Display | Typical Use |
|--------------|---------|-------------|
| `asterisk` | * | First author note |
| `dagger` | † | Corresponding author, second note |
| `ddagger` | ‡ | Third note |
| `section` | § | Fourth note |
| `parallel` | ‖ | Fifth note |
| `paragraph` | ¶ | Sixth note |

Symbol footnotes are commonly used for:
- Author affiliations and correspondence information
- Acknowledgments and funding sources
- Equal contribution statements
- Disclaimers and conflicts of interest

For documents requiring more than six symbol footnotes, the sequence typically doubles (**, ††, ‡‡, etc.). Implementations MAY support this extended sequence.

#### 4.5.2 Footnote Block

Footnote content is stored as a block, typically at the end of a section or document:

```json
{
  "type": "semantic:footnote",
  "number": 1,
  "id": "fn1",
  "children": [
    {
      "type": "paragraph",
      "children": [
        { "type": "text", "value": "Source: Annual Report 2024, p. 42. See also " },
        {
          "type": "text",
          "value": "Smith (2023)",
          "marks": [{ "type": "citation", "refs": ["smith2023"] }]
        },
        { "type": "text", "value": " for additional context." }
      ]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"semantic:footnote"` |
| `number` | integer | Yes | Footnote number (must match mark) |
| `id` | string | No | Unique identifier (must match mark if present) |
| `children` | array | Yes | Footnote content (paragraph blocks) |

Footnote blocks support full rich text content including citations, links, and formatting. For simple text-only footnotes, a shorthand form is available:

```json
{
  "type": "semantic:footnote",
  "number": 1,
  "content": "Source: Annual Report 2024, p. 42."
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | string | No | Simple text content (alternative to `children`) |

Implementations MUST support either `children` (rich content) or `content` (plain text), but not both on the same footnote.

## 5. Entity Linking

### 5.1 Entity Annotation

```json
{
  "type": "text",
  "value": "Albert Einstein",
  "marks": [
    {
      "type": "entity",
      "uri": "https://www.wikidata.org/wiki/Q937",
      "entityType": "Person",
      "source": "wikidata"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"entity"` |
| `uri` | string | Yes | URI identifying the entity in a knowledge graph |
| `entityType` | string | No | Schema.org type of the entity |
| `source` | string | No | Knowledge graph origin (e.g., "wikidata", "dbpedia", "geonames") |

### 5.2 Entity Types

Based on Schema.org types:
- `Person`
- `Organization`
- `Place`
- `Event`
- `Product`
- `CreativeWork`

## 6. Structured Data

### 6.1 Data Tables

```json
{
  "type": "table",
  "semantic": {
    "@type": "Dataset",
    "name": "Quarterly Revenue",
    "description": "Revenue data for Q1-Q4 2024"
  },
  "children": [...]
}
```

### 6.2 Measurements

The semantic extension provides `semantic:measurement` for measurements with linked data integration:

```json
{
  "type": "semantic:measurement",
  "value": 42.5,
  "unit": "kg",
  "schema": {
    "@type": "QuantitativeValue",
    "value": 42.5,
    "unitCode": "KGM"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"semantic:measurement"` |
| `value` | number | Yes | Numeric measurement value |
| `unit` | string | Yes | Unit of measurement |
| `schema` | object | No | Schema.org QuantitativeValue for linked data |

#### 6.2.1 Core vs Semantic Measurements

The Codex format defines two measurement types for different use cases:

| Type | Location | Purpose |
|------|----------|---------|
| `measurement` | Core (content.schema.json) | Metrology/scientific data with uncertainty notation |
| `semantic:measurement` | Semantic extension | General measurements with linked data integration |

**Core `measurement`** is designed for scientific and metrology documents requiring:
- Measurement uncertainty (e.g., `7.677(9)`)
- Uncertainty notation styles (parenthetical, plusminus, range, percent)
- Scientific notation with exponents
- Required display string for accessibility

**Semantic `semantic:measurement`** is designed for:
- Schema.org integration via QuantitativeValue
- Machine-readable linked data
- E-commerce and general web content

For documents requiring both uncertainty notation AND linked data, use the core `measurement` block and add a `semantic` annotation with the JSON-LD representation.

## 7. Cross-References

### 7.1 Internal References

Internal references use Content Anchor URI syntax (see core Anchors and References specification) for the `target` field. Values beginning with `#` are internal document references:

```json
{
  "type": "semantic:ref",
  "target": "#section-3",
  "format": "Section {number}",
  "children": [{ "type": "text", "value": "Section 3" }]
}
```

### 7.2 External References

```json
{
  "type": "semantic:ref",
  "target": "https://example.com/doc#section",
  "external": true,
  "children": [{ "type": "text", "value": "external document" }]
}
```

## 8. Glossary

### 8.1 Term Definition

```json
{
  "type": "semantic:term",
  "id": "term-crdt",
  "term": "CRDT",
  "definition": "Conflict-free Replicated Data Type - a data structure that can be replicated across multiple computers and updated independently without coordination",
  "see": ["term-eventual-consistency"]
}
```

### 8.2 Term Usage

```json
{
  "type": "text",
  "value": "CRDT",
  "marks": [
    { "type": "glossary", "ref": "term-crdt" }
  ]
}
```

### 8.3 Glossary Block

```json
{
  "type": "semantic:glossary",
  "title": "Glossary of Terms",
  "sort": "alphabetical"
}
```

## 9. Provenance

### 9.1 Source Attribution

```json
{
  "type": "blockquote",
  "semantic": {
    "source": {
      "@type": "Book",
      "name": "The Art of Computer Programming",
      "author": "Donald Knuth",
      "datePublished": "1968"
    },
    "page": "42"
  },
  "children": [...]
}
```

### 9.2 Data Provenance

```json
{
  "semantic": {
    "provenance": {
      "source": "https://data.example.org/dataset/123",
      "retrieved": "2025-01-10",
      "license": "CC BY 4.0"
    }
  }
}
```

## 10. Examples

### 10.1 Academic Paper

```json
{
  "metadata": {
    "jsonld": "metadata/jsonld.json"
  },
  "semantic": {
    "bibliography": "semantic/bibliography.json",
    "glossary": "semantic/glossary.json"
  }
}
```

With JSON-LD:

```json
{
  "@context": "https://schema.org/",
  "@type": "ScholarlyArticle",
  "name": "A New Document Format for the Semantic Web",
  "author": [
    { "@type": "Person", "name": "Jane Doe", "identifier": "https://orcid.org/0000-0001-2345-6789" }
  ],
  "abstract": "This paper presents a new document format...",
  "datePublished": "2025-01-15",
  "publisher": {
    "@type": "Organization",
    "name": "ACM"
  },
  "citation": [
    { "@type": "ScholarlyArticle", "@id": "#smith2024" }
  ]
}
```
