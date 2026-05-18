If $ARGUMENTS is empty, ask the user to describe the feature they want to build before proceeding.

Before writing the PRD, ask clarifying questions in rounds — up to 2 rounds total, stopping as soon as you have enough to write a concrete PRD. Each round should ask only what genuinely blocks you from proceeding. Skip questions already answered by $ARGUMENTS.

Examples of clarifying questions include but are not limited to the following:
1. What problem does this solve, and who specifically has that problem?
2. What is the single most important thing this feature must do?
3. What is explicitly out of scope?

Once you have enough clarity, create a Product Requirements Document (PRD) for: $ARGUMENTS

Use the project context from CLAUDE.md and the current codebase state to make the PRD grounded and specific. Write the PRD using this structure:

---

## PRD: [Feature Name]

### Problem Statement
What user problem does this solve? Why does it matter for a retirement planning app?

### Goals
- What does success look like? (2–4 bullet points)

### Out of Scope
- What is explicitly not included in this feature, now or later?

### Who Does What and Why
Who uses this feature, what do they do with it, and what outcome do they get? (2–4 concrete scenarios — no rigid format required)

### Functional Requirements
Numbered list of concrete behaviors the feature must exhibit. Each requirement must include a brief verifiable done-condition.

Example format:
1. User can input a monthly contribution amount. ✓ Input accepts numeric values; non-numeric input shows an inline error.

### UX / Design Notes
Key interaction decisions, edge cases to handle in the UI, or constraints from the existing design.

### Technical Approach
Derive from the current codebase state. Call out any new components, state, data shapes, or architectural changes needed.

### Open Questions
Anything that needs a decision before or during implementation.

---

Keep the PRD concise — prioritize clarity over completeness.

After writing the PRD, save it as a markdown file in `docs/prds/`. Name the file using kebab-case derived from the feature name (e.g., `savings-goal-tracker.md`). Confirm the file path to the user when done.

Do NOT begin implementing. The PRD is for planning only.
