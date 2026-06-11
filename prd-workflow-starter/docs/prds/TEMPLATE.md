> **Type:** Feature <!-- Bug | Feature | Research | Tech Debt -->

## PRD NN: Title

> One-line provenance note: where this PRD came from (a review, a user report, a grilling session that surfaced it), with a link if it has a source document.

### Problem Statement

Why this PRD exists — the defect, gap, or opportunity, stated concretely. Name the files/components involved. If a previous PRD or ADR created the situation, link it.

### Goals

- What success looks like, as observable outcomes (2–4 bullets).

### Out of Scope

- What's deliberately excluded, each with a one-line reason or a pointer to the PRD that owns it instead.

### Who Does What and Why

Concrete user scenarios: "A user with X does Y and expects Z." Skip for pure tech-debt PRDs.

### Functional Requirements

<!-- Bug/Feature PRDs. Research PRDs replace this section with "Candidate Approaches"
     (lettered options A/B/C with trade-offs) + a "Tentative Recommendation". -->

1. First numbered behavior, stated as the end state, not the work. ✓ Done-condition concrete enough to check off without re-reading this PRD.
2. Second behavior. ✓ Done-condition.

### UX / Design Notes

Interaction details, edge cases, empty/error states, copy notes. Reference the domain glossary (CONTEXT.md) terms — don't invent synonyms.

### UI/UX Mockups

<!-- Only for non-trivial UI changes. -->
Self-contained HTML mockup at [`designs/prdNN/index.html`](../../designs/prdNN/index.html). The mockup is the spec for copy, layout, and colour; show BEFORE/AFTER where it clarifies the change.

### Technical Approach

Files, components, integration points. Which modules change, which stay untouched, what new exports appear. Note test expectations (e.g. "no golden-fixture change" or "fixture will move — intent: …").

### Open Questions

1. Decisions still pending. Resolve these in a grilling pass before implementation — move answers to a dated **Resolved Questions** section above this one, and promote direction-setting decisions to an ADR.
