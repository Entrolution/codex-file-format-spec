# Codex Document Format

**An open specification for documents that unify viewing and editing, with modern security and machine readability.**

> Status: Draft Specification (v0.1)

## Problem Statement

The document landscape is fundamentally divided:

- **View-optimized formats** (PDF, DJVU) offer layout fidelity but poor editability
- **Edit-optimized formats** (DOCX, ODF, Markdown) enable rich editing but render inconsistently
- **No existing format** excels at both viewing and editing

This divide creates workflow friction, format conversion overhead, and lost fidelity. Additionally:

- **PDF's security model is broken**: 21 of 22 desktop viewers vulnerable to signature attacks
- **Machine readability is an afterthought**: 73-96% accuracy even with state-of-the-art extraction
- **Compression is outdated**: PDF uses 30-year-old DEFLATE, missing modern algorithms
- **No clear "frozen" semantics**: Signatures don't truly lock documents

## Design Goals

### Primary Goals

1. **Unified View/Edit Mode**: One format from draft to archive, no conversion step
2. **Semantic-First**: Content stored as meaning, presentation derived
3. **Modern Security**: Algorithm-agile cryptography, post-quantum ready
4. **Machine Readable**: AI/ML extraction works reliably by design
5. **Content-Addressable**: Document hash is its identity; modifications create new versions

### Secondary Goals

- Efficient compression using modern algorithms (Zstandard, AVIF)
- Clear document state machine (draft → review → frozen/signed)
- Native version control and lineage tracking
- Accessibility built-in (WCAG-aligned)

### Non-Goals

- Replacing PDF for legacy/archival use cases
- Supporting scripting/executable content (security risk)
- Achieving 100% PDF import fidelity

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DOCUMENT CONTAINER                        │
│  (ZIP archive, content-addressable hash = identifier)        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐  ┌──────────────────────────────────┐ │
│  │ MANIFEST         │  │ CONTENT STREAMS                  │ │
│  │ - Version        │  │ ┌────────────────────────────┐   │ │
│  │ - State          │  │ │ Semantic Document Layer    │   │ │
│  │ - Signatures[]   │  │ │ (JSON blocks)              │   │ │
│  │ - Metadata       │  │ └────────────────────────────┘   │ │
│  │ - Compression    │  │ ┌────────────────────────────┐   │ │
│  └──────────────────┘  │ │ Presentation Layer(s)      │   │ │
│                        │ │ (paginated, continuous,    │   │ │
│  ┌──────────────────┐  │ │  responsive)               │   │ │
│  │ SECURITY LAYER   │  │ └────────────────────────────┘   │ │
│  │ - Signatures     │  │ ┌────────────────────────────┐   │ │
│  │ - Encryption     │  │ │ Assets                     │   │ │
│  │ - Access control │  │ │ (images, fonts, embeds)    │   │ │
│  └──────────────────┘  │ └────────────────────────────┘   │ │
│                        └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Specification Structure

The specification is modular:

### Core Specification (Required)

- [Container Format](spec/core/01-container-format.md) - ZIP-based packaging
- [Manifest](spec/core/02-manifest.md) - Document metadata and structure
- [Content Blocks](spec/core/03-content-blocks.md) - Semantic content model
- [Presentation Layers](spec/core/04-presentation-layers.md) - Rendering instructions
- [Asset Embedding](spec/core/05-asset-embedding.md) - Images, fonts, files
- [Document Hashing](spec/core/06-document-hashing.md) - Content-addressable identity
- [State Machine](spec/core/07-state-machine.md) - Draft/frozen lifecycle
- [Metadata](spec/core/08-metadata.md) - Dublin Core and extensions

### Extension Specifications (Optional)

- [Security Extension](spec/extensions/security/) - Signatures, encryption, access control
- [Collaboration Extension](spec/extensions/collaboration/) - CRDT hooks, comments, change tracking
- [Presentation Extension](spec/extensions/presentation/) - Advanced layout, print styling
- [Forms Extension](spec/extensions/forms/) - Input fields, validation
- [Multimedia Extension](spec/extensions/multimedia/) - Video, audio, interactive elements
- [Semantic Extension](spec/extensions/semantic/) - JSON-LD, knowledge graphs, citations

## Quick Start

### Document Structure

A Codex document is a ZIP archive with this structure:

```
document.cdx
├── manifest.json          # Document manifest
├── content/
│   └── document.json      # Semantic content blocks
├── presentation/
│   ├── paginated.json     # Print/fixed layout
│   └── continuous.json    # Screen/reflow layout
├── assets/
│   ├── images/
│   ├── fonts/
│   └── embeds/
├── security/
│   └── signatures.json    # Digital signatures
└── metadata/
    └── dublin-core.json   # Standard metadata
```

### Minimal Example

```json
{
  "codex": "0.1",
  "id": "sha256:a1b2c3...",
  "state": "draft",
  "content": {
    "blocks": [
      {
        "type": "heading",
        "level": 1,
        "children": [{ "type": "text", "value": "Hello, World" }]
      },
      {
        "type": "paragraph",
        "children": [
          { "type": "text", "value": "This is a " },
          { "type": "text", "value": "Codex", "marks": ["bold"] },
          { "type": "text", "value": " document." }
        ]
      }
    ]
  }
}
```

## File Extension and MIME Type

- **Extension**: `.cdx`
- **MIME Type**: `application/vnd.codex+json` (canonical JSON form)
- **Alternative**: `application/vnd.codex` (binary/packed form)

## Roadmap

### Phase 1: Core Specification (Current)
- [ ] Complete core specification documents
- [ ] JSON Schema for validation
- [ ] Example documents

### Phase 2: Extensions
- [ ] Security extension (signatures, encryption)
- [ ] Collaboration extension (CRDT integration)
- [ ] Presentation extension (advanced layout)

### Phase 3: Reference Implementation
- [ ] TypeScript parser/writer library
- [ ] Web-based viewer
- [ ] Basic editor integration

### Phase 4: Ecosystem
- [ ] Conversion tools (PDF, DOCX import/export)
- [ ] CLI tools (validate, sign, verify)
- [ ] Standards body submission

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This specification and all associated code are licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Acknowledgments

This specification draws inspiration from:
- PDF (ISO 32000) for document packaging concepts
- Portable Text (Sanity) for semantic content modeling
- EPUB for reflowable document structure
- CRDTs (Yjs, Automerge) for collaboration patterns
