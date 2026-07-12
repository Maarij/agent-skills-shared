# Roadmap

The single tracking doc for this project's work: what's planned, what's
deferred, what shipped.

**Status:** 0 shipped · 0 planned · 0 deferred · 0 cancelled.

**Last shipped:** none yet.

**Next up:** nothing queued.

## Planned (0)

_The table is ordered; the top row is the commitment, not a wish list.
Next number: **1**._

| # | Type | Item | Summary |
|---|---|---|---|

## Deferred (0)

Still-valid work that is not on the active backlog. A deferred item returns
on real user signal: it re-enters through superpowers brainstorming with its
prior artifact as input, keeping its original number.

| # | Type | Item | Summary |
|---|---|---|---|

## Cancelled (0)

| # | Type | Item | Summary |
|---|---|---|---|

## Shipped

Rows are one line each, newest first; the narrative lives in the linked spec
or PR.

| # | Date | Type | Item | Summary |
|---|---|---|---|---|

## How tracking works

- **One door.** Anything needing a design conversation enters through
  superpowers brainstorming (spec → plan → implement). Trivial fixes (a typo,
  a one-line bug) skip the ritual: straight to a Planned row and a PR, no spec.
- **Numbers are stable and sequential.** New work takes the next number
  regardless of whether it produces a spec. A revived deferred item keeps its
  original number.
- **Planned** is ordered; the top row is the commitment. A row appears when
  work is committed to and links to its spec once one exists.
- **Shipping** = move the row to Shipped as one line (`# · date · type · item ·
  summary`, linking the spec, or the PR when there is no spec) and update the
  dashboard in the same edit.
- **Deferring / cancelling** = move the row to the matching section. Long-form
  rationale never goes in the tables. Deferred = still valid, awaiting signal;
  Cancelled = premise dissolved, not expected to return.
- **Type tags** (Bug / Feature / Research / Tech Debt) live on as a table
  column.
- **Reconcile rule:** the filesystem is the truth for what exists; this
  roadmap is the truth for priority and intent.
