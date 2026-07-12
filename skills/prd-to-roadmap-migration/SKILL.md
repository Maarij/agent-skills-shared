---
name: prd-to-roadmap-migration
description: Use when a project wants to retire its numbered-PRD folder workflow, asks to migrate to the roadmap convention, or needs roadmap tracking bootstrapped without PRD history.
---

# PRD to Roadmap Migration

## Overview

The PRD convention tracks work as numbered files moving through
`docs/prds/{planned,deferred,cancelled,shipped}/` folders, indexed by a README
that inevitably grows into three documents at once: a roadmap dashboard, a
dense shipped changelog, and process documentation. This skill migrates such a
project to a single `docs/ROADMAP.md` where superpowers brainstorming
(spec → plan → implement) is the authoring path, and freezes the PRD tree as a
linked historical archive. Nothing is deleted; the roadmap stays
forward-looking because shipped entries are one-liners whose narrative lives
in the spec or PR.

**Announce at start:** "I'm using the prd-to-roadmap-migration skill to
migrate this project's tracking."

For the target file's anatomy, read `references/roadmap-template.md`. For the
step-by-step procedure, read `references/migration.md`. The first executed
migration (the reference example) is RetireRatio:
`docs/superpowers/specs/2026-07-12-prd-to-roadmap-tracking-design.md` in that
repo.

## Core decisions the target convention encodes

1. **Numbers continue.** The PRD sequence keeps going in ROADMAP.md — new work
   takes the next number whether or not it produces a spec. Numbers are the
   stable cross-reference currency; revived deferred items keep theirs.
2. **The PRD tracking tree freezes in place.** Numbered lifecycle artifacts
   do not move (the link graph into them is large); the index README is
   rewritten as the archive index. The hard invariant afterward: **no new
   tracking or PRD artifacts under `docs/prds/`, ever.** Existing owner docs
   under a reference folder may still be maintained, but new owner docs
   should live outside the archive.
3. **One door.** Anything needing a design conversation enters through
   superpowers brainstorming; a revived deferred PRD is *input* to that
   session, not a document to implement from. Trivial fixes go straight to a
   Planned row and a PR.
4. **One tracking doc with a weight cap.** Shipped rows after the migration
   point are strictly one line; PRD-era rows move verbatim to the archive
   index. Still-live deferred rows move (link-rebased) into ROADMAP.md.
5. **Process docs live in ROADMAP.md's footer** (~20 lines), next to the
   tables they govern.
6. **Reconcile rule:** the filesystem is the truth for what exists; the
   roadmap is the truth for priority and intent.

## Judgment points that vary per project

Resolve these by reading the project before editing (details in
`references/migration.md`):

- **What is still live vs frozen.** Deferred/planned PRDs are live (rows move
  to ROADMAP.md); shipped/cancelled are history (rows stay in the archive
  index). Reference folders may hold live owner docs — freezing applies to the
  lifecycle folders, not the directory.
- **Whether a backlog/event log exists.** If yes, move it next to ROADMAP.md
  and keep appending. If no, either create one for queue-event rationale or
  remove the log pointer and logging rule from the generated roadmap together.
- **The inbound link graph.** grep for the index README's path and the log's
  path before moving anything; only links to files that actually move need
  fixing. Historical documents (shipped PRDs, old specs/plans) keep stale
  prose references as record — fix only links that stop resolving.
- **Numbering continuation.** Find the highest assigned number, including
  moved-out or absorbed PRDs; the roadmap states the next free one.
- **Pointer surfaces.** CLAUDE.md / AGENTS.md, root README, and any ADR that
  names the index as the "what's next" source all need re-pointing.

## Fresh-project bootstrap

For a project with no PRD history, skip the migration procedure entirely:
instantiate the non-archive portions of `references/roadmap-template.md` as
`docs/ROADMAP.md`, set the counters to zero and the next number to 1, use
`Last shipped: none yet`, and add the Roadmap section from the template's
footer comment. Do not leave any `{archive: ...}` markers in the result.

## Rationalization table

| Rationalization | Reality |
| --- | --- |
| "The shipped table is useful context, keep it in the roadmap." | It is the archive index's job. Dense history in the roadmap is how the old README became unreadable. |
| "Renaming docs/prds/ to archive/ is cleaner." | It rewrites the whole inbound link graph for zero information gain. Freeze in place; say "archive" in the README. |
| "This project's PRDs are small, keep authoring them." | Two authoring formats for one queue means every item starts with "which format?". One door. |
| "I'll fix the links later." | Link sweeps are the migration. A moved log with dangling links is worse than an unmoved one. |
