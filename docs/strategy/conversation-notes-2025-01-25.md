# Discussion Notes — 2025-01-25

## Context

First working session after the feasibility study. Built out the complete v0.1 specification draft, set up the repository, and discussed market viability, adoption strategy, and implementation priorities.

---

## What Was Built

### Complete v0.1 Specification

Built the full Codex Document Format specification from the feasibility study:

- **Core Specification (9 documents)** — Introduction, container format, manifest, content blocks, presentation layers, asset embedding, document hashing, state machine, metadata, provenance and lineage
- **Extension Specifications (5 modules)** — Security (signatures, encryption, access control), Collaboration (CRDTs, comments, change tracking, presence), Presentation (advanced layout, print features, master pages), Forms (input fields, validation), Semantic (JSON-LD, citations, entity linking, glossaries)
- **JSON Schemas (6 files)** — manifest, content, dublin-core, asset-index, presentation, provenance
- **Examples** — Minimal draft document, frozen document with two signatures
- **Documentation** — README, CONTRIBUTING, design decisions (14 recorded), use cases (10 scenarios)

### Repository Setup

- Pushed to GitHub: `gvonness-apolitical/codex-file-format-spec`
- File extension: `.cdx`, MIME type: `application/vnd.codex+json`
- Key design choices: ZIP container, content-addressable hashing (SHA-256), explicit state machine (draft → review → frozen → published), ES256 required for signatures, no scripting

---

## 1. Is This Addressing a Real Need?

### The Technical Case

The technical problems are real and documented:

- **PDF signature vulnerabilities** — Published security research shows 21 of 22 desktop viewers vulnerable to signature attacks. This isn't theoretical.
- **View/edit divide** — Universal friction. Draft in Word/Docs, finalize to PDF, any edit requires round-trip to source.
- **AI extraction market** — Multi-billion dollar industry exists *because* PDF structure is unreliable. Semantic-first format largely eliminates this problem.
- **"What was signed?" ambiguity** — PDF's incremental update model creates genuine legal/compliance uncertainty.
- **Outdated compression** — AVIF, Zstandard, etc. exist and aren't being used. PDF's DEFLATE-only approach is 30 years old.

### The 80/20 Reality

Technical merit is ~20% of what determines format success. The other 80% is ecosystem, timing, and adoption strategy.

- Network effects are brutal — PDF opens everywhere, immediately
- "Good enough" often wins
- Implementation burden is massive — a spec without robust tooling is just documentation

Technical case is *necessary* but not *sufficient*. Without it, abandon immediately. With it, success depends on adoption strategy.

---

## 2. Beachhead Strategy

### Primary: Academia

Why it works:

- Students experiment with new tech if it's genuinely better and open
- Lower switching costs (no enterprise contracts, IT approval chains)
- Acute pain points: citations as flat text, figures as inaccessible blobs, supplementary materials as broken links, text extraction for literature review unreliable
- Cultural alignment with open standards — "open format" is a feature, not a risk
- LaTeX users prove academics tolerate complexity for better output
- Natural integration points: Overleaf, Zotero, Pandoc, Jupyter

**The long game:** Grad student writes thesis in Codex → becomes professor who expects it → becomes journal editor who accepts it → becomes department that mandates it. 10-15 year arc, but patience is available.

### Secondary: Legal

Why secondary, not primary:

- High pain point (signature issues = real legal liability)
- But adoption friction is high (entrenched tooling, tech-averse users)
- Better play: become "killer feature" for tooling vendor entering legal market
- "If lawyers trust it for contracts" = powerful social proof
- Don't need lawyers to adopt directly — need one e-signature vendor to see competitive differentiation

---

## 3. Development Approach

### The Tension

- Solo: Move faster, coherent vision, no consensus overhead
- OSS: Builds advocates, distributes maintenance, aligns with open format philosophy

### Resolution: Start Solo, Design for OSS

1. Begin implementation alone to move fast and establish patterns
2. Design for OSS from day one (clear architecture, good docs, contribution points)
3. Open it up once there's something functional to contribute to
4. Empty repos don't attract contributors; working code does

Speed now, community later. Avoid "design by committee" early. The spec is already open — that's the legitimacy part. Implementations can follow.

---

## 4. Implementation Priorities

### Highest Leverage: Pandoc Integration

Academics don't adopt new editors, they adopt new export targets. A Pandoc writer (Markdown → Codex) is the highest-leverage early move — fits existing workflow, zero friction for authors.

### Build Order

1. **cdx-core** (Rust library) — Parse, validate, create Codex documents. Foundation everything else builds on. Rust benefits: compression (zstd), crypto (ring), WASM compilation.
2. **cdx-cli** — `cdx validate`, `cdx inspect`, `cdx sign`. Dogfoods the core library. Essential for anyone building tooling.
3. **Pandoc writer** — Markdown → Codex. Could be Lua filter initially or shell out to cdx-cli. This is the academia unlock.
4. **Web viewer** — cdx-core compiled to WASM + minimal JS. Proves format renders. Zero-install demonstration.

### Why Rust

- Excellent crates for compression (zstd) and crypto (ring)
- WASM compilation means core library powers the web viewer too
- CLI tooling ecosystem is mature (clap)
- Memory safety for document parsing

---

## 5. Strategic Advantages

### Patient Single Developer Model

- No investor pressure or growth timelines
- Can optimize for getting it right vs getting it funded
- Precedent: SQLite (D. Richard Hipp), Markdown, many foundational tools started this way
- Can nurse the project indefinitely, waiting for adoption opportunities

### Provenance as Differentiator

Hash chains + Merkle trees for tamper-evident history, block-level proofs, selective disclosure. This is something no existing document format offers.

---

## Key Takeaways

1. **Technical case is necessary but not sufficient.** The problems are real — PDF signatures are broken, extraction is unreliable, there's no verifiable history. But format success is mostly ecosystem and adoption strategy.

2. **Academia is the right beachhead.** Lower switching costs, cultural alignment with open standards, and a natural 10-15 year adoption arc through the academic career pipeline.

3. **Pandoc integration is the highest-leverage move.** It turns Codex into a new export target rather than requiring anyone to adopt a new editor.

4. **Start solo, design for OSS.** Move fast to establish patterns. The spec is already open — that's the legitimacy. Working code attracts contributors; empty repos don't.

---

## Open Questions

- Zotero integration for citation management?
- Overleaf partnership/plugin?
- What's the minimal "wow demo" that shows the format's value?
- When to approach academic publishers about acceptance?
- Separate repos for implementations or monorepo?
