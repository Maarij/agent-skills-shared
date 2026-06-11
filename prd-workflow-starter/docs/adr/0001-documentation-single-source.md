# ADR 0001 — Documentation Is Single-Source-of-Truth, by Pointer

- **Status:** Accepted
- **Date:** YYYY-MM-DD <!-- set on install -->
- **Supersedes:** —

## Context

Adopted at project start, from a convention proven in a prior project. There, agent-facing and public docs drifted into mutually-contradictory copies of the same facts: a "next up" pointer in three states across three files, the infra story stated three different ways, and component inventories listing dead code. The root cause was never any single stale line — it was that the **same fact lived in multiple files**, so every edit had to be applied N times and inevitably wasn't.

## Decision

Documentation does not duplicate prose. Each fact has **one owning file**; every other file that needs it **points** rather than copies.

- **README.md** owns **project identity** — purpose, tech stack, and infra/hosting status. It is the public front door and the canonical source for "what this is built with."
- **CLAUDE.md** owns **agent working-conventions** — commands, testing strategy, architecture orientation, and stack *gotchas* (version pins, "read the vendored docs first"). It points to README for identity rather than restating it.
- **AGENTS.md** (if present) is a **thin cross-tool shim**: a pointer to README (identity) and CLAUDE.md (conventions). It is intentionally hollow.
- **The PRD index** (`docs/prds/README.md`) is the **sole** source of the "next up" pointer and implementation order. No other file names a specific next-up PRD number; they say "see the index."
- **Inventories that drift are pointers, not lists.** Component and function inventories defer to the directory / the module's own exports, rather than enumerating per-item.
- **ADR/doc references to code use stable symbols, not line numbers.** Cite a symbol or anchor, never `File.tsx:217–223`.

## Consequences

- A future "tidy the docs" pass must **not** re-inflate the shim files, copy the infra line into CLAUDE.md, or hardcode a next-up number "for convenience" — those reintroduce exactly the drift this ADR removes. The duplication looks helpful and is the trap.
- Reading a single file sometimes requires one hop to the owning file. Accepted: one bounce is cheaper than N-way drift.
- **Reversible?** Cheaply, per file — but the reversal *is* the regression, which is why it's recorded.
