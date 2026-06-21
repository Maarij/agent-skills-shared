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

## Upgrading from the PowerShell installers

The Windows-only `install-codex-skills.ps1` and `install-claude-skills.ps1` have been
replaced by the single cross-platform `scripts/install-skills.sh` (Windows via Git
Bash, macOS, and Linux).

- **Your existing install keeps working.** The new script is idempotent: it recognizes
  any link already pointing at the right target — including the junctions the old
  PowerShell scripts created — and reports it as `Already linked` without touching it.
  Run `./scripts/install-skills.sh --dry-run` to confirm.
- **Re-run the new script** whenever you add, remove, or rename a managed skill — the
  same cases that needed a re-run before.
- **Optional — standardize on symlinks.** Junctions and symlinks both resolve correctly,
  so this is purely cosmetic. Note that `--force` alone will **not** convert them: the
  installer sees a correctly-pointing junction as `Already linked` and skips it before
  the `--force` path. To switch a skill to a symlink, remove its junction first (in both
  `~/.agents/skills/<name>` and `~/.claude/skills/<name>`), then re-run the installer to
  recreate it as a symlink. On Windows the installer creates symlinks with `mklink`,
  which needs only Developer Mode — no elevation.
