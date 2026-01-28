# Codex Pandoc Writer

A Pandoc custom writer that converts documents to Codex Document Format (.cdx).

## Overview

This writer enables conversion from any Pandoc-supported format (Markdown, LaTeX, Word, etc.) to Codex Document Format. The conversion happens in two phases:

1. **Lua Writer** (`codex.lua`) - Converts Pandoc AST to Codex JSON structures
2. **Packaging** - Shell wrapper creates the final .cdx ZIP archive

## Requirements

- Pandoc 2.11+ (with Lua support)
- jq (for JSON processing)
- sha256sum or shasum (for hashing)
- zip (for archive creation)

## Usage

### Direct JSON Output

Generate the intermediate JSON structure:

```bash
pandoc input.md -t codex.lua -o output.json
```

### Full Pipeline (Recommended)

Create a complete .cdx archive:

```bash
./scripts/pandoc-to-cdx.sh input.md output.cdx
```

### Supported Input Formats

Any format Pandoc can read:
- Markdown (.md)
- LaTeX (.tex)
- Microsoft Word (.docx)
- EPUB (.epub)
- HTML (.html)
- reStructuredText (.rst)
- And many more...

## Features

### Block Types Supported

| Pandoc | Codex | Notes |
|--------|-------|-------|
| Para | paragraph | Text content |
| Header | heading | Levels 1-6, preserves IDs |
| BulletList | list (ordered=false) | Nested lists supported |
| OrderedList | list (ordered=true) | Start number preserved |
| CodeBlock | codeBlock | Language preserved |
| BlockQuote | blockquote | Nested content |
| HorizontalRule | horizontalRule | Thematic break |
| Table | table | Headers and cells |
| Math (display) | math | LaTeX format, display=true |
| Math (inline) | math | LaTeX format, display=false; splits paragraph |
| Cite | semantic:citation | ref, prefix, suffix, suppressAuthor |
| Note | semantic:footnote | Superscript ref + block content |
| Image | image | src, alt, title, width, height |
| Figure | image | Extracts image with caption |
| Div | (unwrapped) | Contents extracted |
| Div#refs | semantic:bibliography | Citeproc bibliography entries |

### Inline Formatting

| Pandoc | Codex Mark |
|--------|------------|
| Strong | bold |
| Emph | italic |
| Code | code |
| Link | link (with href, title) |
| Strikeout | strikethrough |
| Underline | underline |
| Superscript | superscript |
| Subscript | subscript |

### Metadata Mapping

The writer extracts Dublin Core metadata from Pandoc YAML front matter:

| Pandoc | Dublin Core |
|--------|-------------|
| title | title |
| author | creator |
| date | date |
| abstract | description |
| keywords | subject |
| lang | language |
| publisher | publisher |
| rights | rights |

## Output Structure

The writer produces a JSON structure with three sections:

```json
{
  "manifest": {
    "codex": "0.1",
    "id": "pending",
    "state": "draft",
    "created": "2025-01-28T10:00:00Z",
    "modified": "2025-01-28T10:00:00Z",
    "content": {
      "path": "content/document.json",
      "hash": "sha256:..."
    },
    "metadata": {
      "dublinCore": "metadata/dublin-core.json"
    }
  },
  "content": {
    "version": "0.1",
    "blocks": [...]
  },
  "dublin_core": {
    "version": "1.1",
    "terms": {...}
  }
}
```

The packaging script extracts these into the proper Codex directory structure.

## Development

### Running Tests

```bash
make test          # Run JSON output tests
make validate      # Validate JSON structure
make test-cdx      # Run full pipeline tests
```

### Project Structure

```
cdx-pandoc/
├── codex.lua           # Main Pandoc custom writer
├── lib/
│   ├── blocks.lua      # Block type converters
│   ├── inlines.lua     # Inline/text node converters
│   ├── metadata.lua    # Dublin Core extraction
│   └── json.lua        # JSON encoding utilities
├── scripts/
│   └── pandoc-to-cdx.sh  # Full pipeline wrapper
├── tests/
│   ├── inputs/         # Test input files
│   └── outputs/        # Generated test outputs
├── Makefile
└── README.md
```

## Examples

### Basic Markdown

Input (`document.md`):
```markdown
---
title: My Document
author: Jane Doe
date: 2025-01-28
---

# Introduction

This is a **simple** example with *formatting*.

## Code Example

```python
print("Hello, Codex!")
```
```

Convert:
```bash
./scripts/pandoc-to-cdx.sh document.md document.cdx
```

### From LaTeX

```bash
./scripts/pandoc-to-cdx.sh paper.tex paper.cdx
```

### From Word

```bash
./scripts/pandoc-to-cdx.sh report.docx report.cdx
```

## Limitations

- Images are referenced by path but not embedded in the archive (future enhancement)
- Complex table formatting may be simplified
- Citations require `--citeproc` flag for bibliography generation; without it, only inline citation blocks are emitted
- Footnote content is appended as blocks at the end of the document

## License

Part of the Codex Document Format specification.
