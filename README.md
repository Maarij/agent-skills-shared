# agent-skills-shared

Canonical source for reusable agent skills used across Claude CLI, Codex CLI, and project repos.

## Layout

```text
skills/
  <skill-name>/
    SKILL.md
    ...
skills.manifest.json
scripts/
  install-codex-skills.ps1
  install-claude-skills.ps1
docs/
  installation.md
  provider-adapters.md
prd-workflow-starter/
```

`skills/` is the source of truth. Provider-specific skill locations are installed from this repo and should be treated as generated runtime entrypoints.

`skills.manifest.json` is the managed-skill list. Install scripts only touch names listed there.

`prd-workflow-starter/` is retained as a reusable project scaffold and is not part of the skill installer.

## Install

From this repo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-codex-skills.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-codex-skills.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-claude-skills.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-claude-skills.ps1
```

Use `-Force` only after reviewing the dry run. `-Force` backs up an existing real directory before replacing it with a junction.

See [docs/installation.md](docs/installation.md) for the full flow.
