# Product Requirements Documents

Short, task-sized planning artifacts — one PRD ≈ one feature ≈ one focused PR.

**Status:** 0 shipped · 0 planned · 0 deferred · 0 cancelled · next up is **[PRD 01](planned/feature/01-your-first-prd.md)**.

## Type tags

Every PRD carries a `> **Type:** …` tag near the top, also reflected in its folder:

- **Bug** — a defect with broken or specified-but-unimplemented behavior. Lives under `bug/`.
- **Feature** — a new user-visible capability or structural change that enables one. Lives under `feature/`.
- **Research** — open-ended brainstorm; lands on a recommendation rather than a checklist of done-conditions. Lives under `research/`.
- **Tech Debt** — internal-quality work with no user-visible change: refactors, type cleanup, removing workarounds, code organization. Lives under `techdebt/`.

```
docs/prds/
├── README.md
├── TEMPLATE.md
├── planned/     bug/  feature/  research/  techdebt/
├── deferred/    bug/  feature/  research/  techdebt/
├── cancelled/   bug/  feature/  research/  techdebt/
├── shipped/     bug/  feature/  research/  techdebt/
└── reference/   (non-PRD planning notes, e.g. sequencing questions — no type subfolders)
```

The full status/type skeleton ships with the starter, so every lifecycle folder exists from day one. Each empty leaf holds a `.gitkeep` placeholder (git won't track an empty directory otherwise); drop it once the folder gets its first real PRD, or leave it — it's harmless.

## Planned (0)

Implement in table order — numbers are stable identifiers, not implementation order. Each PRD assumes the ones above it in this table have landed. Ordering rationale is folded into each summary where it matters; when a coherence pass reorders the table, date the rationale in a preamble above it.

| # | Type | PRD | Summary |
|---|---|---|---|

## Deferred (0)

PRDs that are documented but not on the active backlog. File a follow-up if real user signal arrives; otherwise they live here for the design thinking they capture, not as queued work.

| # | Type | PRD | Summary |
|---|---|---|---|

## Cancelled (0)

PRDs whose problem dissolved before they were built — kept for the design trail, not as queued work. Distinct from **Deferred** (still valid, just not competing on priority): a cancelled PRD's premise no longer holds.

| # | Type | PRD | Summary |
|---|---|---|---|

## Shipped (0)

Most recent at the bottom of each type group.

| # | Type | PRD | Summary |
|---|---|---|---|

**Notes:** When one PRD is absorbed into another, the absorbed PRD keeps its row (with an "Absorbed into #N" note) and is counted in the section header — absorption does not skew the count. When you ship a PRD, bump both the top-line **Status** count and the section header in the same edit.

## Filename convention

`NN-kebab-case-slug.md` — a 2-digit zero-padded prefix, then a descriptive slug. Numbers are **stable**: once assigned, a PRD keeps its number. New PRDs append at the next available slot.

## PRD skeleton

Each PRD is intentionally short — typically 50–80 lines — and follows the skeleton in [TEMPLATE.md](TEMPLATE.md):

1. **Problem Statement** — why this PRD exists
2. **Goals** — what success looks like
3. **Out of Scope** — what's deliberately excluded
4. **Who Does What and Why** — concrete user scenarios
5. **Functional Requirements** — numbered behaviors, each with a `✓` done-condition (Bug / Feature PRDs)
6. **UX / Design Notes** — interaction details, edge cases, styling notes
7. **UI/UX Mockups** — for PRDs with non-trivial UI changes: a self-contained HTML mockup in a per-PRD `designs/prdNN/` folder, linked from this section. Show BEFORE/AFTER where it clarifies the change, and treat the mockup as the spec for copy, layout, and colour. Skip for PRDs with no visible UI change.
8. **Technical Approach** — files, components, integration points
9. **Open Questions** — decisions still pending

Research PRDs may replace the Functional Requirements section with a "Candidate Approaches" brainstorm and a tentative recommendation. Mockups are usually premature for an unresolved research PRD — add the `designs/prdNN/` folder once it resolves into a buildable spec.

## Authoring a new PRD

1. Pick the next available number.
2. Decide its type (Bug / Feature / Research / Tech Debt) and add `> **Type:** X` as the first line of the file.
3. Write the file as `planned/<type>/NN-kebab-case-slug.md`.
4. Follow the skeleton. Keep done-conditions concrete enough that they can be checked off without re-reading the PRD.
5. For a PRD with non-trivial UI, create a `designs/prdNN/` folder with a self-contained HTML mockup and link it from the **UI/UX Mockups** section.
6. If your PRD references another, link it by relative path.
7. Add a row to the **Planned** table in this README so the index stays current.

Before implementing, run a grilling pass (`/grill-me` or `/grill-with-docs`) to resolve the Open Questions — move answers into a dated **Resolved Questions** section; decisions that set project direction become ADRs in `docs/adr/`.

## Marking a PRD as complete

When a PRD ships:

1. Add `> **Status: Shipped**` after the `> **Type:** X` line.
2. Move the file from `planned/<type>/` into `shipped/<type>/`.
3. Move its row from the **Planned** table to the **Shipped** table in this README, updating the link path to `shipped/<type>/NN-slug.md`.
4. Update the top-line **Status** counts and the next-up pointer in the same edit.

## Deferring a PRD

When a planned PRD is **still valid** but no longer competes on priority (no user signal, lower-value than the rest of the backlog) and the design thinking is worth keeping:

1. Add `> **Status: Deferred**` after the `> **Type:** X` line, with a one-line rationale.
2. Move the file from `planned/<type>/` into `deferred/<type>/`.
3. Move its row from the **Planned** table to the **Deferred** table, updating the link path.
4. Decrement the **Planned** count and bump the **Deferred** count in the top-line **Status**.

A deferred PRD can return to Planned later — reverse the steps above.

## Cancelling a PRD

When a planned PRD's **premise no longer holds** — the problem it set out to solve dissolved (e.g. another PRD shipped a fix, or the approach was superseded by one that pulls the opposite way) — but the design trail is worth preserving:

1. Add `> **Status: Cancelled**` after the `> **Type:** X` line, with a dated rationale and a link to whatever superseded it.
2. Move the file from `planned/<type>/` into `cancelled/<type>/`.
3. Move its row from the **Planned** table to the **Cancelled** table, updating the link path.
4. Decrement the **Planned** count and bump the **Cancelled** count in the top-line **Status**.

Unlike a deferred PRD, a cancelled one is not expected to return — if the problem resurfaces, write a fresh PRD that references this one for the history.
