# ROADMAP.md template

Copy the skeleton below to `docs/ROADMAP.md`. Replace every `{...}`
placeholder; delete the archive-pointer sentences (marked `{archive}`) for a
fresh project with no PRD history. Keep the footer verbatim unless the
project genuinely deviates — it is the process documentation.

---

# Roadmap

The single tracking doc for this project's work: what's planned, what's
deferred, what shipped. {archive: PRD-era items through NN are preserved in
the [PRD archive](prds/README.md).}

**Status:** {N} shipped · {N} planned · {N} deferred · {N} cancelled.

**Last shipped:** {item link} ({date}).

**Next up:** {top Planned row, or "nothing queued."}

Backlog events (insertions, reorderings, cancellations) are logged in
[backlog-log.md](backlog-log.md). {omit if the project keeps no event log}

## Planned ({N})

_The table is ordered; the top row is the commitment, not a wish list.
Next number: **{N}**._

| # | Type | Item | Summary |
|---|---|---|---|

## Deferred ({N})

Still-valid work that is not on the active backlog. A deferred item returns
on real user signal: it re-enters through superpowers brainstorming with its
prior artifact as input, keeping its original number.

| # | Type | Item | Summary |
|---|---|---|---|

## Cancelled ({N})

_{archive: PRD-era cancellations are recorded in the
[PRD archive](prds/README.md).}_

| # | Type | Item | Summary |
|---|---|---|---|

## Shipped {archive: (since NN)}

{archive: Shipped PRD-era items are listed in the
[archive index](prds/README.md).} Rows are one line each, newest first; the
narrative lives in the linked spec or PR.

| # | Date | Type | Item | Summary |
|---|---|---|---|---|

## How tracking works

- **One door.** {archive: The hard invariant is **no new files under
  `docs/prds/`, ever**.} Anything needing a design conversation enters
  through superpowers brainstorming (spec → plan → implement). Trivial fixes
  (a typo, a one-line bug) skip the ritual: straight to a Planned row and a
  PR, no spec.
- **Numbers are stable and sequential.** New work takes the next number
  regardless of whether it produces a spec. A revived deferred item keeps its
  original number.
- **Planned** is ordered; the top row is the commitment. A row appears when
  work is committed to and links to its spec once one exists.
- **Shipping** = move the row to Shipped as one line (`# · date · type ·
  item · summary`, linking the spec, or the PR when there is no spec) and
  update the dashboard in the same edit.
- **Deferring / cancelling** = move the row to the matching section and
  {if a backlog log exists: append a dated entry to it.} Long-form rationale goes in the
  log, never in the tables. Deferred = still valid, awaiting signal;
  Cancelled = premise dissolved, not expected to return.
- **Type tags** (Bug / Feature / Research / Tech Debt) live on as a table
  column.
- **Reconcile rule:** the filesystem is the truth for what exists; this
  roadmap is the truth for priority and intent.

---

Suggested CLAUDE.md / AGENTS.md Roadmap section for the project:

> Work is tracked in [docs/ROADMAP.md](docs/ROADMAP.md) — the sole source of
> what's next. All new work enters through superpowers brainstorming
> (spec → plan → implement); the `/prd` skill is retired for this repo
> {archive: and no new tracking artifacts land under `docs/prds/`.
> PRD-era items through NN are archived in
> [docs/prds/](docs/prds/README.md)}.
