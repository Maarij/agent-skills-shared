# Migration procedure

Run these phases in order. Every phase ends with a verification command;
do not proceed past a failing one. Work on a branch if the project uses a
branch → PR flow. **Ask before committing** if the project's rules require
explicit commit approval.

Throughout, use the link checker for your current shell, run from the file's
own directory. It checks local inline-link targets, not anchors, reference-
style links, or non-file schemes; inventory those separately when present.

POSIX / Git Bash:

    grep -oE '\]\([^)#]+' FILE.md | sed 's/](//' | grep -v '^http' | \
      sort -u | while read -r p; do [ -e "$p" ] || echo "MISSING: $p"; done

PowerShell:

    $links = [regex]::Matches((Get-Content -Raw FILE.md), '\]\(([^)#]+)') |
      ForEach-Object { $_.Groups[1].Value } |
      Where-Object { $_ -notmatch '^[a-z]+:' } | Sort-Object -Unique
    $links | Where-Object { -not (Test-Path $_) } |
      ForEach-Object { "MISSING: $_" }

State expected results as *distinct missing paths*, never line counts —
`sort -u` collapses duplicate references to one line, so a file that links
a missing target twice still prints one MISSING line.

## Phase 0: Inventory (read-only)

1. Read the PRD index README end to end. Classify each section: dashboard,
   planned table, deferred table, cancelled table, shipped table, process
   docs, anything else (event logs, notes).
2. Find the highest assigned item number, counting absorbed, cancelled, and
   moved-to-other-repo PRDs. Next free number = highest + 1.
3. Map the inbound link graph:
   `grep -rn 'prds/README\|docs/prds' --include='*.md' .` — note which hits
   treat the index as *the roadmap* (must re-point) vs *the archive or
   history* (leave).
4. Locate any event/backlog log and any live reference docs inside the PRD
   tree (owner playbooks, runbooks). Live docs stay put; only the log moves.
5. Identify pointer surfaces: CLAUDE.md / AGENTS.md roadmap sections, root
   README, ADRs naming the index as the "what's next" source.
6. Confirm the target project has the brainstorming/spec/plan workflow that
   the new roadmap will name, and record its actual artifact paths. If it does
   not, stop and set that workflow up (or agree on a different authoring door)
   before writing the roadmap.
7. Reconcile dashboard counts against the actual unique table rows and
   lifecycle artifacts. Record discrepancies rather than copying stale counts.
   Capture any event-log heading count from the working tree before moving it.

## Phase 1: Create `docs/ROADMAP.md`

Instantiate `roadmap-template.md`. Use the reconciled counts from Phase 0:
Shipped and Cancelled are cumulative; Planned and Deferred are the live rows.
Move **deferred and still-planned** rows in content-verbatim, re-basing each
relative link from the old index's directory to `docs/` (typically: prefix
`prds/`). Planned starts empty only when no live planned rows exist.
Post-migration Shipped and Cancelled tables start empty; their headings point
at the archive index for PRD-era history while the dashboard remains
cumulative.

The verbatim rule wins over template cosmetics: if the old deferred table's
column header says `PRD` where the template says `Item`, keep the moved
header — a considered consequence, not an oversight.

Verify: link-check ROADMAP.md; every `prds/...` path resolves.

## Phase 2: Move the event log (if one exists)

`git mv` it next to ROADMAP.md. Re-base its internal links for the new
directory (deepest path prefixes first, e.g. `../../adr/` before `../`).
Update its header prose to name the roadmap instead of the index. Fix
inbound links to the log's old path (same-directory neighbors are the
common casualty).

Verify: link-check the log and each file whose links you touched; its event
heading count matches the working-tree count captured in Phase 0.

## Phase 3: Rewrite the index README as the archive index

New header: name it an archive with its known date range (or start date
through the migration date), state that tracking moved to `../ROADMAP.md`
and that no new tracking artifacts land in the folder, and link the moved
log when one exists. Keep verbatim: type-tag definitions, folder tree, the shipped
and cancelled tables with their notes, the filename convention (reworded to
say the number sequence continues in the roadmap). Delete: dashboard,
planned/deferred sections (moved), the PRD skeleton, authoring and
lifecycle rituals. Do not renumber, reorder, or reword table rows.

Verify: link-check; the numeric table-row count equals the shipped + cancelled
row count from Phase 0; every inbound fragment recorded in Phase 0 still
targets a surviving heading.

## Phase 4: Re-point the pointer surfaces

CLAUDE.md / AGENTS.md roadmap section, root README mentions and
project-structure tree, and any ADR that names the index as the next-up
source (amend with a dated parenthetical rather than erasing the history).
State explicitly that the PRD-authoring skill is retired for this repo and
new work enters through superpowers brainstorming.

Verify: `grep -rn 'prds/README' --include='*.md' .` returns only
archive-role or historical-record hits.

## Phase 5: Final sweep

1. Old-log-path sweep: `grep -rn '<old log path>' --include='*.md' .` —
   expected: only historical specs/plans (leave those). Agent scratch dirs
   (`.superpowers/`, task briefs/reports) may also hit; they are gitignored
   scaffolding — exclude or ignore them, don't "fix" them.
2. Link-check every file the migration touched.
3. Frozen-tree check: `git status --short docs/prds/` shows only the README
   rewrite and the log's rename half. No additions.

## What never changes

- No numbered lifecycle PRD artifact moves or receives prose edits. The README
  is rewritten in place; other files under `docs/prds/` may receive only the
  minimal relative-link repairs required by a moved log.
- Shipped/cancelled table rows move nowhere and change by zero bytes.
- Historical documents keep stale prose references; only links that stop
  resolving get fixed.
