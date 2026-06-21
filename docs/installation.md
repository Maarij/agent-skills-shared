# Installation

Run from the repository root (referred to below as `<repo>`).

## 1. Prerequisites

- **macOS / Linux:** `bash`. `jq` optional (recommended).
- **Windows:** **Git Bash** (provides `bash`, `cygpath`, and the bundled
  `powershell.exe`) and **Developer Mode** enabled (Settings → For developers) so
  symlinks can be created. The installer creates links with `cmd`'s `mklink`, which
  honors Developer Mode and needs **no elevation** — a normal Git Bash shell is enough.
  (PowerShell 5.1's `New-Item -ItemType SymbolicLink` is avoided because it demands admin
  even under Developer Mode.) Do **not** run from WSL — links made under `/mnt/c` are not
  reliably followed by Windows-native apps, and the installer hard-stops if it detects
  WSL.

## 2. Verify the managed skill list

Review `skills.manifest.json`. The installer only manages skills listed there.

## 3. Preview, then install

Dry run (changes nothing; prints the exact per-OS action for each skill):

```bash
./scripts/install-skills.sh --dry-run
```

Apply:

```bash
./scripts/install-skills.sh
```

The script runs two ordered passes and creates symlinks:

```text
~/.agents/skills/<skill-name>  ->  <repo>/skills/<skill-name>     (shared/Codex)
~/.claude/skills/<skill-name>  ->  ~/.agents/skills/<skill-name>  (Claude)
```

Because the links point back at the repo, editing a skill needs no re-run — only
adding, removing, or renaming a skill requires re-running the installer.

## Replacing existing real directories

If a managed skill path is a real directory (not the expected symlink), the installer
stops unless `--force` is supplied. With `--force` it moves the existing entry to a
timestamped backup beside it, then creates the symlink. Example:

```text
~/.claude/skills/prd.backup.20260621143000
```

Review dry-run output before using `--force`.

## Verification

After installing, restart the CLI that should discover the skills.

macOS / Linux:

```bash
readlink ~/.agents/skills/prd
readlink ~/.claude/skills/prd
```

Windows (PowerShell):

```powershell
Get-Item ~/.agents/skills/prd | Select-Object LinkType,Target
Get-Item ~/.claude/skills/prd | Select-Object LinkType,Target
```

Claude slash-style invocation such as `/prd {text}` depends on the skill directory
name under `~/.claude/skills`. The installer preserves that by creating a `prd`
symlink at that path.
