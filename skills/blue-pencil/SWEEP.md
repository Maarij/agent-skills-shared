# Blue Pencil: sweep mode

The on-demand audit. Use this when asked to check a project's existing user-facing copy and product docs for AI tells, not while writing new copy.

## 1. Read the local rubric first

Find the project's voice rubric (`copy-voice.md`, a style guide, a `CONTEXT.md` glossary, brand docs). It overrides this skill. Note any terms it sanctions that appear on the [ban list](BANS.md) so you don't flag them. If there's no rubric, infer the register from the project's strongest existing copy before judging anything.

## 2. Enumerate the copy

Collect the in-scope text:

- **User-facing strings:** JSX/template text, button and label strings, error and empty-state messages, tooltips, placeholders, aria-labels, `<title>` and meta description and other metadata, email and notification copy.
- **User-facing docs:** README intro and marketing-facing sections, landing and marketing pages, help and onboarding docs, changelog entries written for users.

Skip internal engineering docs, code comments, and commit messages.

## 3. Scan for density

Run the [quick-scan table](BANS.md) across the collected text. Grep output is a starting point, not a finding. For each candidate, apply the accumulation test:

- How often does this pattern appear across the corpus, or within one screen or page?
- Is it the first use (often fine) or a repeated crutch?
- Does the local rubric sanction it?

A lone "robust" in one tooltip is not a finding. Five participial openers across a landing page is.

## 4. Report

Present findings grouped by file or surface, worst offenders first. For each:

- **Location:** file and the exact string.
- **Tell:** which pattern, and whether it's isolated or part of a cluster.
- **Suggested rewrite:** in the project's register, more specific and concrete.

Open with a one-line read on the corpus overall: broadly clean with a few hot spots, or slop-heavy throughout? Don't rewrite anything in place unless asked. Propose, and let the user choose. If the user wants fixes applied, do it as one reviewable batch.

## 5. Offer to record recurring tells

If the same tells keep recurring, suggest the user add them to the project's own rubric so the local layer catches them next time. Don't edit the rubric without asking.
