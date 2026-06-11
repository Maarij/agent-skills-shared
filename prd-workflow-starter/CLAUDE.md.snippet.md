# CLAUDE.md snippet

Merge these sections into the new project's `CLAUDE.md` (typically created by `/init`). They wire the agent into the PRD workflow. Adapt the bracketed parts; keep the pointer discipline — CLAUDE.md owns conventions and gotchas, and *points* everywhere else (see ADR 0001).

---

Never run git commit or git push without an explicit instruction in the current message. A "commit and push" instruction authorizes exactly one commit+push for the changes just discussed — it does not carry forward to subsequent changes in the same session.

## Roadmap

Planned work lives in [docs/prds/](docs/prds/README.md) as short, task-sized PRDs. See the index for the current order — it is the sole source of what's next.

## Testing

The project follows the testing strategy in [ADR NNNN](docs/adr/NNNN-testing-strategy.md) — read it before adding tests or test infrastructure. [Write that ADR with your first test PRD; the proven shape: name the runner, co-locate tests next to source, test pure modules first through their public interface with no internal mocking, and — if the project has headline numbers — keep golden fixtures whose failure means "the headline shifted; verify intent before updating".]

**TDD workflow:** pick one PRD `✓` done-condition → write one failing test → minimal implementation → refactor. **Never write all tests up front.**

## Architecture

[Orientation only — a handful of entry-point files and what owns what. For anything that drifts (component lists, function inventories), point at the directory or the module's exports instead of enumerating. Include version pins and "read the vendored docs first" gotchas here; identity/stack facts live in README.]

## Copy voice

[Optional, for user-facing products: every user-visible string is written against a voice rubric at docs/copy-voice.md — a short list of numbered rules with examples and an avoid-list. Create it once copy starts mattering; an audit PRD can validate it later.]

## Agent skills

### Domain docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
