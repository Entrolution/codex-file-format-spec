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
      "pages": "42-45"
    }
  ]
}
```

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

```json
{
  "type": "semantic:bibliography",
  "style": "apa",
  "title": "References",
  "filter": null
}
```

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
| `number` | integer | Yes | Sequential footnote number |
| `id` | string | No | Unique footnote identifier for cross-referencing |

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
      "entityType": "Person"
    }
  ]
}
```

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
