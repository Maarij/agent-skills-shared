# PRD Workflow Starter

A portable copy of the planning/tracking system used in argetlahm. Drop this into a new project to get the same structure: short task-sized PRDs with a lifecycle, ADRs for direction-level decisions, a domain glossary, and a single-source-of-truth documentation convention.

## How to install in a new project

1. Copy the `docs/` and root files from this folder into the new repo:

   ```
   newproject/
   ├── CONTEXT.md                 ← seed glossary (fill in as terms crystallise; start near-empty)
   └── docs/
       ├── prds/
       │   ├── README.md          ← the index — the heart of the system
       │   └── TEMPLATE.md        ← PRD skeleton to copy when authoring
       ├── adr/
       │   ├── README.md
       │   └── TEMPLATE.md
       └── agents/
           └── domain.md          ← tells agent skills how to consume CONTEXT.md + ADRs
   ```

2. Merge `CLAUDE.md.snippet.md` into the new project's `CLAUDE.md` (adapt the bracketed parts).
3. Delete this file and `CLAUDE.md.snippet.md` from the copy — they're install instructions, not project docs.
4. The status folders (`planned/feature/` etc.) are created lazily when the first PRD of that type/status lands — don't pre-create empty directories.

The skills that drive the workflow (`/prd`, `/grill-me`, `/grill-with-docs`, `/implement`, `/tdd`) are user-level — they're already available in every project. This kit gives them the file structure they expect.

## The system in one page

**Unit of work: the PRD.** One PRD ≈ one feature ≈ one focused PR, typically 50–80 lines. Every PRD has a stable number, a type (Bug / Feature / Research / Tech Debt), and a status expressed as its folder (`planned/`, `shipped/`, `deferred/`, `cancelled/`). Functional requirements carry `✓` done-conditions concrete enough to check off without re-reading the PRD.

**The index is the spine.** `docs/prds/README.md` holds one table per status. The Planned table's *order* is the implementation order (numbers are identifiers, not sequence — never renumber). The index is the **sole** source of "what's next"; no other file hardcodes a next-up pointer.

**The lifecycle:**

```
idea ──/prd──▶ planned ──/grill-me──▶ planned (questions resolved)
                                          │
                            /implement or /tdd
                                          ▼
                                       shipped
planned ──no longer competes──▶ deferred   (still valid; can return)
planned ──premise dissolved──▶ cancelled   (kept for the design trail)
research ──resolves into──▶ a new buildable PRD (umbrella closes when children ship)
```

**Grill before you build.** A new PRD lands with an Open Questions section. Before implementation, a grilling pass (`/grill-me` or `/grill-with-docs`) resolves each question — answers move to a "Resolved Questions" section with the date and rationale, big ones become ADRs. An ungrilled PRD is not ready to build.

**ADRs are the why, PRDs are the what and when.** A decision that sets a *direction* (testing strategy, a data-model commitment, a legal posture) gets an ADR; the PRD that implements it links to it. ADRs are superseded, never edited — reversals get a new number.

**CONTEXT.md is the shared vocabulary.** Each entry: a canonical term, its precise definition, where it surfaces in the UI/code, and an `_Avoid_:` list of synonyms that caused confusion. UI copy, code, PRDs, and tests all use the glossary's words. It grows lazily — `/grill-with-docs` adds terms as they get resolved.

**One fact, one file (the anti-drift rule).** Each fact has exactly one owning file; everything else points to it. README owns project identity; CLAUDE.md owns agent conventions and stack gotchas; the PRD index owns ordering and next-up; directories and module exports own their own inventories (never maintain a per-item list in prose — it *will* drift). This is the single highest-leverage rule in the system: most documentation rot is the same fact living in N places.

## Habits that make it work (learned, not obvious)

- **When you ship, update the index in the same commit** — move the file, move the table row, bump both the top-line count and the section header. Half-done moves are how the index rots.
- **Research PRDs may replace Functional Requirements with "Candidate Approaches" + a tentative recommendation.** They close by resolving into one or more implementation PRDs, not by being implemented.
- **Absorption is normal.** When one PRD swallows another, the absorbed PRD keeps its row with a note ("Absorbed into #N") — don't delete history.
- **Periodic coherence passes.** Every so often (especially before a milestone), re-read the Planned table as a whole and reorder for dependencies; date the reordering rationale in the index preamble. Strict numeric order goes stale.
- **Golden fixtures + headline numbers** (if your project has a "the number" output): record it in a fixture; a failing fixture means the headline shifted — verify intent before updating.
- **Mockups when UI is non-trivial:** a self-contained HTML file in `designs/prdNN/`, linked from the PRD's Mockups section, treated as the spec for copy/layout/color.
- **Cross-link by relative path** between PRDs, ADRs, and CONTEXT.md, so every document is one hop from its context.
