# Changelog

All notable changes to the Codex file format specification.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1] - 2025-01 (Draft)

### Added

#### Core Specification
- Document manifest with state machine (draft → review → frozen → published)
- Content block model with 22 block types
- Dublin Core metadata support
- Asset embedding and management
- Provenance and lineage tracking
- Anchors and references system
- Presentation layers (paginated, continuous, responsive, precise)
- Highlight annotation documentation in collaboration extension (Section 4.7)

#### Extensions
- **Academic** (`codex.academic`) - Theorems, proofs, exercises, algorithms, equation groups
- **Collaboration** (`codex.collaboration` v0.2) - CRDT integration, comments, change tracking, presence
- **Forms** (`codex.forms`) - Interactive form fields with validation
- **Legal** (`codex.legal`) - Citations, Table of Authorities, court captions, signature blocks
- **Phantoms** (`codex.phantoms`) - Invisible structural elements for complex layouts
- **Presentation** (`codex.presentation`) - Advanced typography, master pages, print features
- **Security** (`codex.security`) - Digital signatures, encryption, redaction, scoped signatures
- **Semantic** (`codex.semantic`) - Bibliography, footnotes, glossary, entity markup, JSON-LD

#### Profiles
- Simple Documents profile for recreational reading

#### Examples
- Legal extension example document (`examples/legal-document/`)
- Precise layout example (`examples/presentation-document/presentation/layouts/letter.json`)

#### Tooling
- JSON Schema validation for all specification components
- Example document validation
- Cross-reference validation
- Spec-schema synchronization checking
- Example coverage checking capability in sync checker
- Template generation script

### Fixed
- Broken cross-reference in presentation layers spec (Section 5.1.2 → 5.4)
- Sync checker false positives for MIME types, token types, and enum values

### Changed
- Content schema now references legal extension marks (`legal:cite`)

### Notes
- This is an initial draft specification
- The collaboration extension migrated from v0.1 to v0.2 (anchor-based addressing)
- Feedback welcome via GitHub issues
