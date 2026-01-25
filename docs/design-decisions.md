# Design Decisions

This document records key design decisions made during the Codex format specification development.

## DD-001: ZIP Container Format

**Decision**: Use ZIP archive as the container format.

**Alternatives Considered**:
1. Custom binary format
2. Single JSON file
3. Tar archive
4. SQLite database

**Rationale**:
- ZIP is universally supported across platforms
- Enables random access to individual files
- Familiar tooling for debugging and inspection
- Built-in compression support
- EPUB, DOCX, ODF all use ZIP successfully

**Consequences**:
- Slight overhead compared to custom format
- Must handle ZIP-specific edge cases (path traversal, etc.)

---

## DD-002: JSON as Primary Data Format

**Decision**: Use JSON for all structured data (manifest, content, metadata).

**Alternatives Considered**:
1. XML
2. YAML
3. Protocol Buffers
4. MessagePack/CBOR

**Rationale**:
- JSON is human-readable for debugging
- Universal parser support across languages
- Easy to version control (text diffs work)
- JSON Schema provides validation
- JCS (RFC 8785) enables deterministic hashing

**Consequences**:
- Larger file sizes than binary formats
- Some types require conventions (dates as ISO 8601 strings)
- Deep nesting can be verbose

---

## DD-003: Semantic-First Content Model

**Decision**: Store content as semantic blocks, not visual instructions.

**Alternatives Considered**:
1. PDF-style drawing operators
2. HTML-like tag soup
3. Markdown with extensions

**Rationale**:
- Separates meaning from presentation
- Enables multiple output formats from single source
- Machine extraction works reliably
- Accessibility is natural, not bolted on
- Aligns with modern editor architectures (ProseMirror, Slate)

**Consequences**:
- Requires presentation layer for visual rendering
- Some legacy documents harder to convert
- More complex than flat text

---

## DD-004: Content-Addressable Document Identity

**Decision**: Document ID is the hash of its canonical content.

**Alternatives Considered**:
1. UUID assigned at creation
2. Sequential version numbers
3. Timestamp-based IDs
4. No formal ID (filename only)

**Rationale**:
- Hash = identity enables integrity verification
- No central authority needed for ID assignment
- Identical content produces identical IDs (deduplication)
- Enables distributed storage and caching
- Git uses this model successfully

**Consequences**:
- Draft documents need special handling (pending ID)
- Hash must be recomputed on content change
- Canonical form must be precisely defined

---

## DD-005: Explicit Document State Machine

**Decision**: Documents have explicit states (draft, review, frozen, published).

**Alternatives Considered**:
1. Implicit state from signatures (PDF model)
2. No state concept
3. Continuous versioning only

**Rationale**:
- PDF's implicit model has proven confusing and exploitable
- Clear states communicate author intent
- Enables proper enforcement (frozen = no edits)
- Supports workflow integration

**Consequences**:
- State transitions must be validated
- Implementations must respect state semantics
- Adds complexity over simple version numbers

---

## DD-006: SHA-256 as Default Hash Algorithm

**Decision**: Use SHA-256 as the default hashing algorithm, with algorithm agility.

**Alternatives Considered**:
1. SHA-1 (legacy compatibility)
2. SHA-3 only (newest)
3. BLAKE3 (fastest)
4. Multiple required algorithms

**Rationale**:
- SHA-256 has excellent security margin
- Universally implemented
- Matches common certificate standards
- Algorithm agility allows future migration
- SHA-3 and BLAKE3 as options for those who want them

**Consequences**:
- Must specify algorithm in hash string
- Implementations must support migration path

---

## DD-007: ES256 as Required Signature Algorithm

**Decision**: ECDSA with P-256 (ES256) is the minimum required signature algorithm.

**Alternatives Considered**:
1. RSA only (legacy)
2. Ed25519 only (modern)
3. Multiple required algorithms

**Rationale**:
- ES256 balances security, performance, and compatibility
- Required by WebAuthn, widely deployed
- Ed25519 recommended but not required (support still growing)
- RSA optional for legacy integration

**Consequences**:
- Must support at least one ECDSA implementation
- Post-quantum algorithms as optional extension

---

## DD-008: Optional Presentation Layers

**Decision**: Presentation layers are optional; default rendering from semantics.

**Alternatives Considered**:
1. Required presentation layer
2. No presentation concept (pure semantic)
3. Inline styling only

**Rationale**:
- Simple documents don't need complex layouts
- Semantic content can be rendered with defaults
- Presentation is an optimization, not requirement
- Enables progressive enhancement

**Consequences**:
- Implementations must provide default styles
- Rendering may vary slightly across implementations
- Complex layouts require explicit presentation

---

## DD-009: Modular Extension Architecture

**Decision**: Core specification is minimal; features added via extensions.

**Alternatives Considered**:
1. Monolithic specification
2. Profiles (subsets)
3. Completely open extension model

**Rationale**:
- Keeps core simple and implementable
- Extensions can evolve independently
- Implementations can support what they need
- Prevents specification bloat

**Consequences**:
- Must define extension registration mechanism
- Required vs optional extensions need clear semantics
- Interoperability requires common extension support

---

## DD-010: No Scripting in Core

**Decision**: Core specification does not support executable content.

**Alternatives Considered**:
1. JavaScript support (like PDF)
2. Sandboxed scripting
3. Declarative interactivity only

**Rationale**:
- Security risks outweigh benefits
- PDF JavaScript is a major attack vector
- Interactivity can be achieved through forms extension
- Static documents are easier to preserve

**Consequences**:
- Some PDF features not directly portable
- Interactive features require extension or viewer support
- Clearer security model

---

## DD-011: Dublin Core as Required Metadata

**Decision**: Dublin Core metadata is required for all documents.

**Alternatives Considered**:
1. Custom metadata schema
2. XMP (Adobe)
3. No required metadata
4. Schema.org only

**Rationale**:
- Dublin Core is an established standard (ISO 15836)
- Minimal required set (title, creator)
- Extensible for domain-specific needs
- Compatible with library and archive systems

**Consequences**:
- All documents have basic discoverability
- Additional schemas as extensions
- Slight overhead for very simple documents

---

## DD-012: Annotation Layer Separate from Content

**Decision**: Annotations on frozen documents are stored separately, not affecting content hash.

**Alternatives Considered**:
1. Annotations as content (changes hash)
2. No annotations on frozen documents
3. Annotation versioning separate from content

**Rationale**:
- Frozen means content unchanged
- Annotations are commentary, not content
- Enables review workflows on final documents
- Maintains signature validity

**Consequences**:
- Annotations may not be portable
- Need clear boundary between content and annotation
- Annotation integrity separate concern

---

## Open Questions

### OQ-001: Binary Variant

Should there be an optimized binary serialization (CBOR/MessagePack)?

**Status**: Deferred to v1.x
**Considerations**: Performance vs complexity tradeoff

### OQ-002: Streaming Support

How should very large documents support streaming/chunked access?

**Status**: Under investigation
**Considerations**: ZIP supports range requests; content chunking TBD

### OQ-003: Collaborative Editing Protocol

Should the spec define a sync protocol or just data structures?

**Status**: Extension territory
**Considerations**: Many existing protocols; don't reinvent

### OQ-004: Digital Rights Management

Should the format support DRM?

**Status**: Explicitly out of scope
**Considerations**: Opens governance issues; encryption provides confidentiality
