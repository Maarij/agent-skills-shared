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
  install-skills.sh
docs/
  installation.md
  provider-adapters.md
prd-workflow-starter/
```

`skills/` is the source of truth. Provider-specific skill locations are installed from this repo and should be treated as generated runtime entrypoints.

`skills.manifest.json` is the managed-skill list. The install script only touches names listed there.

`prd-workflow-starter/` is retained as a reusable project scaffold and is not part of the skill installer.

## Install (new setup)

From a fresh clone of this repo:

```bash
./scripts/install-skills.sh --dry-run   # preview — changes nothing
./scripts/install-skills.sh             # apply
```

The script builds both layers in one run: `~/.agents/skills/<name>` (shared/Codex)
then `~/.claude/skills/<name>` (Claude), each a symlink back toward
`<repo>/skills/<name>`. Because the links point at the repo, **editing a skill needs no
re-run** — only adding, removing, or renaming one does. Use `--force` only after
reviewing the dry run; it backs up an existing entry to `<dest>.backup.<timestamp>`
before replacing it.

**Prerequisites:** On Windows, run from **Git Bash** (provides `bash`, `cygpath`, and
the bundled `powershell.exe`) with **Developer Mode** enabled (Settings → For
developers) so symlinks can be created. The installer links with `mklink`, so Developer
Mode is enough — no admin/elevated shell required. Do **not** run from WSL. `jq` is
optional but recommended. macOS/Linux need only `bash`.

After installing, restart the CLI that should discover the skills. See
[docs/installation.md](docs/installation.md) for the full flow and verification steps.
