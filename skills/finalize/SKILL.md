---
name: finalize
description: Run the closing ritual that ships a finished idea to the main branch — re-verify, update every impacted doc, commit, then merge with branch cleanup. Use when the user invokes /finalize or asks to finalize, wrap up, mark complete/shipped, or merge finished work (a PRD or any named idea) into main.
argument-hint: "Which PRD or idea to finalize?"
---

This is a **closing ritual**, not an implementation step. You verify, do documentation bookkeeping, and run the git ship sequence. You do **not** write feature code, design, or diagnose. If the work looks unfinished or verification fails, stop and report — never paper over it by editing code.

Prefer the project's own documented process. If the repo describes how it marks work complete / ships (in a PRD index, CONTRIBUTING, CLAUDE.md/AGENTS.md, etc.), follow that over these defaults.

## 1. Resolve the idea

Figure out what is being finalized, in this order:
1. **A PRD or doc reference** (`prd 05`, a path) → do the full bookkeeping in step 3.
2. **Free text** (`the contact form`) → use it as a label only.
3. **Empty** → infer from the current branch, diff, and recent commits, then **echo back** what you concluded before any irreversible action.

## 2. Verification gate (hard stop)

Find the project's checks from its conventions — the "Commands" section of CLAUDE.md/AGENTS.md, `package.json` scripts, `Makefile`, etc. — and run them: build, tests, and any lint/synth. If they fail, **stop, show the output, hand back.** Never commit, merge, or push red. If you can't find any checks, say so and ask before continuing. Skip this only on an explicit "skip verification" instruction, and note in the summary that it was skipped.

## 3. Documentation bookkeeping

Update **every doc the idea may have touched** — not just the obvious one. Walk these candidates and apply only the ones that exist; report the ones you skip and why:
- the idea's own **status marker** (e.g. `Status: Shipped`, a checkbox, a moved file);
- the **roadmap / index / backlog** entry, including ordering and the "next up" pointer;
- a **CHANGELOG** or release notes;
- the **top-level README** status line (it goes stale silently when several items ship without it);
- **cross-reference integrity** — links and counts that move when a file is renamed or relocated, and tests/docs that assert totals.

## 4. Commit & push the branch

Commit the reviewed changes on the feature branch. Write any multi-line message to a temp file and `git commit -F <file>`, then delete it — never pass a multi-line message inline (one `-m` is fine for a trivial one-liner). Push the branch. This is all recoverable, so do it without pausing.

## 5. Confirm, then ship

Print a **preview** and wait for **one** confirmation before the irreversible tail: the resolved label, the doc edits you made, the target branch, the merge style, whether a CI gate applies, and the exact prune commands. Then ship, **CI-aware**:

- **No CI** (no `.github/workflows`, `.gitlab-ci.yml`, `.circleci`, `azure-pipelines.yml`, `Jenkinsfile`, or required checks): `git checkout main` → pull fast-forward → `git merge --ff-only <branch>` → push main.
- **CI present:** open a PR, **wait for checks to go green** (`gh pr checks --watch`, or poll the run on the pushed commit), then merge once green. This is the only way to gate on CI before main.

Then **prune** the merged branch locally (`git branch -d`) and on the remote (`git push origin --delete`).

Guards: never force-push and never create a merge commit — if `--ff-only` can't fast-forward, **stop** (main moved; report it). If the work was committed directly on `main` with no feature branch, skip merge/prune and just push. If pushing to `main` is rejected (branch protection), stop and offer a PR. **Red CI is a hard stop**, same as a failed gate; bounded wait — if checks never start or stall, report rather than hang.

## 6. Report

End with a short table: each step done / skipped and why, plus the merge or PR link, the resulting commit, and the pruned branches.
