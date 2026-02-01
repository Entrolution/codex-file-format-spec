# Design Discussion Notes — 2025-01-28

## Context

Rubber-duck session about off-page annotations that expanded into three interconnected spec amendments. Started with "how would MarginNote-style annotations work?" and surfaced gaps in sub-block addressing, hashing boundary semantics, and signature scope.

---

## How the Discussion Evolved

The session moved through three phases:

1. **Conceptual exploration** — What are phantoms? Where do they live?
2. **Gap identification** — Anchoring phantoms to content exposed the lack of a unified addressing system, which pulled on collaboration, presentation, and semantic extension threads
3. **Detailed design** — Working through the anchor system surfaced the hashing boundary contradiction (DD-015) and the need for scoped signatures

Each problem led to the next. The phantom layer needed anchors. Anchors needed consistent sub-block addressing. Addressing needed block IDs to be non-optional. The hashing boundary question arose when asking what happens to phantoms when a document is frozen. The answer ("phantoms are outside the hash") led to "but then what protects the visual layout?" which led to scoped signatures.

---

## 1. Phantom Layer: From Flag to Separate Layer

### Initial Idea

The starting concept was simple: a flag on content blocks indicating whether they render on the page plane or an annotation plane. For frozen documents, phantoms would be stripped during freezing.

### Problems With the Flag Approach

Three issues killed it:

1. **Content hash contamination** — If phantoms live in `content/document.json`, adding a personal margin note changes the document's SHA-256 identity. My note shouldn't change your document's ID.

2. **Stripping creates a fork, not a freeze** — Removing phantoms during DRAFT→FROZEN changes the content, changes the hash, and orphans any references pointing at the draft hash. The state machine assumes content stabilizes at REVIEW, not that it undergoes lossy transformation at freeze time.

3. **Multi-user ambiguity** — MarginNote annotations are personal. If multiple users annotate the same draft, whose phantoms survive the freeze? Mixing per-user ephemeral data into the shared content layer forces awkward conflict resolution.

### The Pivot

Phantoms should be a dedicated spatial annotation layer outside the content hash boundary — conceptually similar to how `collaboration/comments.json` already sits outside the hash, but with coordinate semantics for spatial layouts.

### Coordinate System Debate

An early design had phantoms reference document layout coordinates (`layoutRef` pointing to `presentation/layouts/letter.json`). This was wrong for several reasons:

- Couples annotation layer to presentation layer, which the spec otherwise keeps cleanly separated
- Introduces staleness (phantoms become stale when layouts change)
- Breaks across page formats (same phantom needs different coordinates for letter vs. A4)
- Fundamentally incoherent: positioning something "outside the page" using the page's own coordinate system

**Resolution**: Phantoms only need:
1. An **anchor** to document content (which block/range they relate to)
2. **Relative coordinates among siblings** (so phantoms within a cluster can be laid out consistently)
3. Where the cluster appears relative to the rendered page is a **view concern** — the document has no business dictating this

### Fork Behavior

Raised the question: when a document is forked, what happens to phantoms?

- **Shared** phantoms carry over (collective knowledge about the document)
- **Private** phantoms carry over only for the author (don't leak personal notes)
- **Role-scoped** phantoms carry over (role enforcement is an app concern)
- Forked phantoms get new IDs to avoid collisions

---

## 2. Unified Anchor System: Pulling the Thread

### How It Was Discovered

A side question — "how does the spec support hyperlinking to other parts of the document?" — surfaced a significant gap. Three different places in the spec had invented their own sub-block addressing:

- **Core link mark**: `href` field but only external URL examples documented
- **Semantic extension**: `semantic:ref` with `target: "#section-3"` (an extension-specific convention)
- **Collaboration extension**: `blockRef` string + separate `range` object (`{start, end}`)

With phantoms also needing to anchor to content, having each extension reinvent addressing would create fragmentation.

### The `blockRef` + `range` Problem

The collaboration extension's pattern was particularly problematic:
- Extension-specific rather than shared vocabulary
- Two separate top-level fields instead of a unified object
- Not interoperable with the semantic extension's `#fragment` syntax
- Would need to be replicated in phantoms, creating two copies of the same concept

### Design: Two Representations of One Concept

The anchor system provides:

- **Content Anchor URI** (string form for marks): `#blockId`, `#blockId/15`, `#blockId/10-25`
- **ContentAnchor object** (structured form for JSON data): `{blockId, offset}` or `{blockId, start, end}`
- **Named anchor marks**: Stable anchor points within text that move with content during edits
- **Link mark amendment**: `href` accepts `#` prefix for internal references — no new field needed

### Block ID Requirements

The anchor system, collaboration, phantoms, and presentation all depend on blocks having IDs. But block IDs were "MAY be omitted for simple documents." This had to change:

- SHOULD be present on all blocks (upgraded from MAY)
- MUST be present when any referencing extension is active
- MUST be stable across edits for REVIEW or later states

### Anchor Stability

Character offsets are fragile under edits. Rather than trying to solve this comprehensively, the spec:
- Acknowledges the problem explicitly
- Notes it's a non-issue for FROZEN/PUBLISHED (content can't change)
- Recommends offset adjustment for mutable documents (same model as text editor cursors)
- Offers named anchor marks as the stable alternative for critical positions
- Provides optional `contentHash` for stale detection

---

## 3. Hashing Boundary and Scoped Signatures

### The Contradiction

A tangential discussion about visual obfuscation surfaced a contradiction:

- `06-document-hashing.md` explicitly **excludes** presentation from the hash
- DD-015 claims "When frozen, the hash covers exact appearance, not just content"

These can't both be true. The hashing spec is normative — the hash is content-only. DD-015's claim was aspirational text that didn't match the actual algorithm.

### Why Content-Only Hashing Is Correct

- Document identity should be "what it says," not "how it looks"
- Letter and A4 layouts of the same content are renderings of the same document — shouldn't produce different IDs
- Adding a precise layout shouldn't change identity
- Tweaking a margin by 0.5mm is not a new document
- Consistent with the spec's semantic-first philosophy

### The Remaining Problem

If presentation is outside the hash, and signatures bind to the hash, what protects visual appearance from tampering on a frozen document? Someone could swap a layout file and the signature would still validate.

### Alternatives Considered

1. **Separate `attestations` array** — Parallel structure, adds complexity
2. **`bindings` object on each signature** — Direct but changes how all signatures compute
3. **Optional `bindings` without signing them** — Binding data that isn't actually signed is useless
4. **Concatenation approach** (`Sign(key, docId + ":" + hash1 + ":" + ...)`) — Messy
5. **Structured signed payload with JCS** — Clean, extensible, backward compatible (**selected**)

### Scoped Signatures Design

An optional `scope` object on each signature entry:

- **Without scope** (default, backward compatible): `Sign(key, documentId)` — covers content only
- **With scope**: `Sign(key, JCS(scope))` — scope contains `documentId` plus optional `layouts` map

Key insight: scope is **per-signature**, not file-wide. Different signers attest different things. A notary signs content + letter layout. A reviewer signs content only. This naturally models real-world signing workflows where different parties have different responsibilities.

The scope object is extensible — future fields can be added without breaking existing signatures.

---

## Annotation Layer Clarity

The spec now has three annotation locations, and their relationships needed documentation:

| Layer | Location | Purpose |
|-------|----------|---------|
| Core annotations | `security/annotations.json` | Minimal fallback for implementations without extensions |
| Collaboration | `collaboration/comments.json` | Full-featured comments, suggestions, change tracking |
| Phantoms | `phantoms/clusters.json` | Spatially-organized off-page annotation clusters |

Core annotations are the lightweight fallback. Collaboration supersedes them when active. Phantoms are orthogonal — spatial off-page content, not inline comments.

---

## Key Takeaways

1. **Specs accumulate ad-hoc solutions.** Three extensions had independently invented sub-block addressing. Catching this early (pre-v1.0) and unifying is much cheaper than fixing it later.

2. **"Where does this live?" is the critical question for new features.** The phantom discussion was really about what's inside vs. outside the hashing boundary. Getting this wrong would have corrupted the document identity model.

3. **Contradictions hide in prose.** DD-015's claim about hashing appearance contradicted the actual hashing algorithm. The prose was aspirational; the algorithm was normative. This kind of inconsistency erodes spec credibility.

4. **Each fix pulls on connected threads.** Phantoms needed anchors, anchors needed block IDs, block IDs needed strengthening, hashing needed clarification, clarification revealed the need for scoped signatures. The changes are individually clean but interdependent.

---

## What Was Produced

- 3 new design decisions (DD-016, DD-017, DD-018)
- 1 corrected design decision (DD-015)
- 4 new spec files (anchors spec, phantom extension, 2 schemas)
- 13 amended files across core spec, extensions, and schemas
- Collaboration extension bumped to v0.2 with migration note
