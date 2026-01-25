# Strategy Discussion Notes — 2025-01-25

## Context

Initial conversation after completing the v0.1 specification draft. Discussed market viability, adoption strategy, and implementation priorities.

---

## Is This Addressing a Real Need?

### The Technical Case (Necessary but Not Sufficient)

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

**Key insight:** Technical case is *necessary* but not *sufficient*. Without it, abandon immediately. With it, success depends on adoption strategy.

---

## Beachhead Strategy

### Primary: Academia

**Why it works:**

- Students experiment with new tech if it's genuinely better and open
- Lower switching costs (no enterprise contracts, IT approval chains)
- Acute pain points:
  - Citations as flat text, not linked data
  - Figures as inaccessible blobs
  - Supplementary materials as broken links
  - Text extraction for literature review unreliable
- Cultural alignment with open standards — "open format" is a feature, not a risk
- LaTeX users prove academics tolerate complexity for better output
- Natural integration points: Overleaf, Zotero, Pandoc, Jupyter

**The long game:** Grad student writes thesis in Codex → becomes professor who expects it → becomes journal editor who accepts it → becomes department that mandates it. 10-15 year arc, but patience is available.

### Secondary: Legal

**Why secondary, not primary:**

- High pain point (signature issues = real legal liability)
- But: adoption friction is high (entrenched tooling, tech-averse users)
- Better play: become "killer feature" for tooling vendor entering legal market
- "If lawyers trust it for contracts" = powerful social proof
- Don't need lawyers to adopt directly — need one e-signature vendor to see competitive differentiation

---

## Development Approach: OSS vs Solo

### The Tension

- Solo: Move faster, coherent vision, no consensus overhead
- OSS: Builds advocates, distributes maintenance, aligns with open format philosophy

### Recommended Approach

**Start solo, design for OSS:**

1. Begin implementation alone to move fast and establish patterns
2. Design for OSS from day one (clear architecture, good docs, contribution points)
3. Open it up once there's something functional to contribute to
4. Empty repos don't attract contributors; working code does

**Rationale:** Speed now, community later. Avoid "design by committee" early. The spec is already open — that's the legitimacy part. Implementations can follow.

---

## Implementation Priorities

### Highest Leverage: Pandoc Integration

**Key insight:** Academics don't adopt new editors, they adopt new export targets.

A Pandoc writer (Markdown → Codex) is the highest-leverage early move:
- Fits existing academic workflow
- Markdown → Codex means zero friction for authors
- Codex → LaTeX/PDF for round-tripping

### Recommended Build Order

1. **cdx-core** (Rust library)
   - Parse, validate, create Codex documents
   - Foundation everything else builds on
   - Rust benefits: excellent compression (zstd), crypto (ring), WASM compilation

2. **cdx-cli**
   - `cdx validate` — validate document structure
   - `cdx inspect` — examine document contents
   - `cdx sign` — add signatures
   - Dogfoods the core library
   - Essential for anyone building tooling

3. **Pandoc writer**
   - Markdown → Codex
   - Could be Lua filter initially (simpler) or shell out to cdx-cli
   - This is the academia unlock

4. **Web viewer**
   - cdx-core compiled to WASM + minimal JS
   - Proves format renders
   - Zero-install demonstration

### Language Choice

Rust is well-suited:
- Excellent crates for compression (zstd), crypto (ring)
- WASM compilation means core library powers web viewer
- CLI tooling ecosystem is mature (clap)
- Memory safety for document parsing

---

## Strategic Advantages

### "Patient Single Developer" Model

- No investor pressure or growth timelines
- Can optimize for getting it right vs getting it funded
- Precedent: SQLite (D. Richard Hipp), Markdown, many foundational tools started this way
- Can nurse the project indefinitely, waiting for adoption opportunities

### Goal Alignment

Core goal: Better format for storing knowledge, leveraging modern tech (encryption, compression, security).

Tooling is means to an end, not "my baby" — this naturally aligns with OSS approach and community building.

---

## Open Questions / Future Considerations

- Zotero integration for citation management?
- Overleaf partnership/plugin?
- What's the minimal "wow demo" that shows the format's value?
- When to approach academic publishers about acceptance?

---

## Action Items

1. ~~Write up these notes~~ ✓
2. Begin cdx-core Rust library
3. Design CLI interface
4. Research Pandoc custom writer API
5. Identify 2-3 academics to get early feedback on the spec
