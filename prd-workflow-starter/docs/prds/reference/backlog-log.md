# Backlog event log

Dated log of PRD-backlog events: insertions, reorderings, cancellations, grillings, supersessions, and repo moves. It exists to keep dated narrative out of the [PRD index](../README.md) header, which stays a fixed-shape status dashboard. Entries are chronological, newest appended at the bottom (matching the Shipped table's convention).

When a backlog event happens (a sequencing decision, a coherence-pass reorder, a grilling that changes scope, a cancellation, a supersession), append a dated `### YYYY-MM-DD: title` entry here. Never grow the README header with that narrative; the dashboard's shape is fixed.

This file starts empty, like CONTEXT.md. The first entry lands with the first backlog event. Example shape:

```markdown
### 2026-01-15: Coherence pass reordered PRDs 04 and 07
PRD 07 moved ahead of 04: both rewrite the same panel, and 07 settles the shape 04 depends on. Numbers are stable, only the table order changed.
```
