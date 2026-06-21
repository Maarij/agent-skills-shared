# OS-agnostic skill installer — design

Date: 2026-06-21
Status: Approved (pending implementation plan)

## Problem

The skill installer is Windows-only. The two PowerShell scripts
(`scripts/install-codex-skills.ps1`, `scripts/install-claude-skills.ps1`) rely on
Windows-specific constructs that do not work on macOS or Linux:

- `$env:USERPROFILE` — empty on macOS/Linux.
- `New-Item -ItemType Junction` — NTFS junctions are a Windows-only filesystem
  concept; they do not exist on macOS/Linux.
- `LinkType -eq "Junction"` idempotency check — never matches off Windows.
- Docs hardcode one machine's literal user/home and repo paths.

Goal: make installation work on **Windows, macOS, and Linux**, for **any user**,
with no machine- or user-specific values baked into the script or docs.

## How the system works (unchanged)

`skills/<name>/` in this repo is the source of truth. Nothing reads skills from the
repo directly. The installer creates links into the two locations the CLIs read from,
forming a chain:

```
~/.claude/skills/<name>  ->  ~/.agents/skills/<name>  ->  <repo>/skills/<name>
   (Claude reads here)        (Codex/shared hub)            (source of truth)
```

`skills.manifest.json` is the gate — the installer only manages names listed there.
Because links point back at the repo, editing a skill needs no re-run; only
adding/removing/renaming a skill requires re-running the installer.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Target Windows + macOS + Linux | macOS and Linux share the Unix linking path, so all three is barely more than Mac-only. |
| 2 | Symlinks on every OS (not junctions) | Uniform behavior; preserves "edit = instantly live". Accepts that Windows needs Developer Mode / elevation. |
| 3 | Single `scripts/install-skills.sh` (bash), shelling out to PowerShell on Windows only for the link line | One codebase; bash can't reliably create native NTFS symlinks, so the link line delegates to Windows-native tooling. |
| 4 | Retire the two `.ps1` scripts | The bash script subsumes both; the inline PowerShell call needs only one command, not the full old scripts. |
| 5 | Parse the manifest with `jq`, fall back to `grep`/`sed` with a warning if `jq` is absent | Clean when `jq` is present; no hard dependency. |
| 6 | Hard-stop when run inside WSL | In WSL `uname` reports `Linux`, so the script would wrongly `ln -s` on `/mnt/c/...` and may produce a link Windows does not follow. Safer to refuse with guidance. |
| 7 | No hardcoded user or machine paths anywhere | Portability requirement. Script uses `$HOME` and paths relative to its own location; docs use `~` / `<repo>` placeholders. |

## Architecture

A single script: `scripts/install-skills.sh`.

### Entry flow

1. Parse flags: `--dry-run`, `--force`.
2. Detect environment (see OS detection). Hard-stop on WSL.
3. Resolve `repo_root` from the script's own location (no hardcoded path).
4. Read managed skill names from `skills.manifest.json`.
5. **Pass 1 — shared/Codex layer:** for each skill, `ensure_link <name>
   <repo>/skills/<name>  $HOME/.agents/skills/<name>`.
6. **Pass 2 — Claude layer:** for each skill, `ensure_link <name>
   $HOME/.agents/skills/<name>  $HOME/.claude/skills/<name>`.

Running both passes in order (shared then Claude) inside one script removes the
current footgun where the Codex installer must be run before the Claude installer.

### `ensure_link <name> <src> <dest>`

One function, used by both passes. All `src`/`dest` values are **absolute** paths
(resolved before linking) so the links are valid regardless of the caller's working
directory. Behavior:

- If `dest` already resolves to `src` → print "already linked", skip (idempotent).
- If `dest` exists but differs:
  - without `--force` → refuse with a clear message and stop.
  - with `--force` → move existing to `<dest>.backup.<timestamp>`, then link.
- If `dest` is absent → create the parent dir if needed, then create the link.
- `--dry-run` prints exactly what each step *would* do and changes nothing.

### OS detection and the link primitive

Branch on `uname -s`:

- `Darwin` / `Linux` (genuine) → `ln -s "$src" "$dest"`.
- `MINGW*` / `MSYS*` / `CYGWIN*` (Git Bash on Windows) → convert paths with
  `cygpath -w`, then:
  `powershell.exe -NoProfile -Command "New-Item -ItemType SymbolicLink -Path '<win_dest>' -Target '<win_src>'"`.

WSL is detected separately (see below) and stops before this branch.

### Windows path translation

Inside Git Bash, `$HOME` is a POSIX path (e.g. `/c/Users/<user>`), but PowerShell
needs a Windows path (e.g. `C:\Users\<user>`). Before each Windows shell-out, convert
both source and destination with `cygpath -w`. `cygpath` ships with Git Bash, so this
adds no dependency. This conversion is the most error-prone step and must be covered
by the dry-run output.

### Manifest parsing

`jq -r '.skills[].name'` when `jq` is available. If `jq` is not found, fall back to a
`grep`/`sed` extraction of the `"name"` values and print a warning recommending `jq`.

## Windows guards (fail loudly)

- **Missing symlink privilege:** if the PowerShell `New-Item` call fails (Developer
  Mode off and not elevated), catch the failure and print: enable Developer Mode
  (Settings → For developers) or run from an elevated shell, then re-run. Never fall
  back to a silent copy.
- **WSL:** detect via `microsoft` in `/proc/version`. If detected, stop and instruct
  the user to run from Git Bash or PowerShell on Windows (not WSL), because links made
  from WSL on `/mnt/c` are not reliably followed by Windows-native apps.

## Portability invariants (must not regress)

- No literal usernames or absolute machine paths in the script. Use `$HOME` and paths
  derived from the script's own location.
- Docs use `~` / `$HOME` and `<repo>` placeholders, never `C:\Users\<name>` or
  `C:\Git\...`.

## Docs changes

- `README.md` and `docs/installation.md`: replace PowerShell invocations and literal
  paths with `./scripts/install-skills.sh [--dry-run] [--force]` and `~`-based paths.
- Add a **Prerequisites** note: Git Bash on Windows (provides `bash`, `cygpath`, and
  the bundled `powershell.exe`); Developer Mode enabled on Windows for symlink
  creation; `jq` optional (recommended).
- Update the layout section if it references the removed `.ps1` files.

## Testing / verification

No single machine has all three OSes, so:

1. `shellcheck scripts/install-skills.sh` for portability and quoting bugs.
2. `--dry-run` on Windows (Git Bash): confirm the `cygpath`-converted paths and the
   PowerShell command string are correct.
3. Real run on Windows: verify the chain resolves
   (`Get-Item ~/.claude/skills/<name> | Select LinkType,Target`).
4. Same dry-run-then-verify on macOS/Linux when available
   (`readlink ~/.claude/skills/<name>`).

The script's `--dry-run` doubles as the primary cross-OS self-check by printing the
exact per-OS actions.

## Out of scope

- Changing the link chain topology (two-hop shared hub stays as-is).
- Changing `skills.manifest.json` format.
- An uninstall command (can be a later addition).
- Auto-installing `jq`, `pwsh`, or enabling Developer Mode for the user.
