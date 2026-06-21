# OS-agnostic Skill Installer Implementation Plan

> **Status: Shipped (2026-06-21)** on branch `os-agnostic-installer`. One deviation from the snippets below: the Windows link primitive ships as `cmd /c mklink /D`, not the `powershell.exe New-Item -ItemType SymbolicLink` shown in Tasks 4–5 — Windows PowerShell 5.1 demands elevation even under Developer Mode, while `mklink` honors Developer Mode unprivileged. See the [design spec](../specs/2026-06-21-os-agnostic-skill-install-design.md). The task snippets are kept verbatim as the historical TDD record.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two Windows-only PowerShell installers with a single `scripts/install-skills.sh` that installs the managed skills on Windows (Git Bash), macOS, and Linux for any user, with no machine- or user-specific values baked in.

**Architecture:** One bash script with small, individually-testable functions and a sourcing guard so a bash test runner can `source` it and call functions directly. OS detection branches the link primitive: genuine `ln -s` on macOS/Linux, a `powershell.exe New-Item -ItemType SymbolicLink` shell-out (with `cygpath -w` path translation) on Git Bash/Windows. The script runs two ordered passes (shared/Codex layer, then Claude layer) so the chain `~/.claude/skills/<n> -> ~/.agents/skills/<n> -> <repo>/skills/<n>` is built in one invocation. WSL is detected and hard-stopped.

**Tech Stack:** Bash, `jq` (optional, with `grep`/`sed` fallback), `cygpath` + `powershell.exe` (Git Bash on Windows only). A hand-rolled bash test runner (no `bats` dependency). `shellcheck` for static analysis when available.

## Global Constraints

These apply to **every** task. Values are copied verbatim from the spec.

- **Target OSes:** Windows + macOS + Linux. macOS/Linux use `ln -s`; Windows (Git Bash) shells out to PowerShell.
- **Symlinks on every OS** — never junctions, never a silent copy fallback.
- **No literal usernames or absolute machine paths in the script.** Use `$HOME` and paths derived from the script's own location (`${BASH_SOURCE[0]}`).
- **Docs use `~` / `$HOME` and `<repo>` placeholders** — never `C:\Users\<name>` or `C:\Git\...`.
- **Single script:** `scripts/install-skills.sh`. The two `.ps1` scripts are retired.
- **Manifest gate unchanged:** only names in `skills.manifest.json` are managed; manifest format is unchanged.
- **Hard-stop in WSL** with guidance (links from WSL `/mnt/c` are not reliably followed by Windows apps).
- **Flags:** `--dry-run` (print actions, change nothing) and `--force` (back up an existing entry to `<dest>.backup.<timestamp>` then link).
- **Idempotent:** a `dest` that already resolves to `src` is left alone.

### Test-environment facts (verified on the dev machine — do not re-discover)

- `uname -s` → `MINGW64_NT-10.0-26200` (matches the `MINGW*` branch).
- `jq`, `cygpath`, and `powershell.exe` are installed and on `PATH`.
- `shellcheck` and `bats` are **not** installed — the test suite must not depend on them.
- `ln -s` in Git Bash does **not** reliably create a native NTFS symlink. Therefore **link-creating tests are gated to non-Windows OSes**; on Windows the real link path is verified manually (Task 10). Pure-function tests, dry-run output tests, and "existing plain directory" tests run everywhere.

---

## File Structure

- `scripts/install-skills.sh` — **new.** The entire installer. Functions + a `main` + a `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` guard. No top-level side effects (so it is safe to `source`).
- `tests/install-skills.tests.sh` — **new.** Hand-rolled bash test runner. Auto-discovers `test_*` functions, runs each in its own temp sandbox, prints a pass/fail/skip summary, exits non-zero on any failure.
- `scripts/install-codex-skills.ps1` — **deleted** (Task 8).
- `scripts/install-claude-skills.ps1` — **deleted** (Task 8).
- `tests/install-scripts.tests.ps1` — **deleted** (Task 8; it tests the deleted `.ps1` scripts).
- `README.md` — **modified** (Task 9): layout block + install block.
- `docs/installation.md` — **modified** (Task 9): full rewrite of the flow for one bash command.
- `docs/provider-adapters.md` — **modified** (Task 9): replace hardcoded paths with placeholders.

### Function inventory for `scripts/install-skills.sh`

These are built across Tasks 1–7. Signatures are fixed here so tasks stay consistent.

- `print_usage()` — prints usage text.
- `detect_os(uname_s, proc_version)` → echoes one of `darwin | linux | windows | wsl | unknown`.
- `parse_manifest_names_jq(manifest_path)` → skill names, one per line (uses `jq`).
- `parse_manifest_names_fallback(manifest_path)` → skill names, one per line (uses `grep`/`sed`).
- `read_manifest_skills(manifest_path)` → skill names; picks `jq` if present, else fallback + a stderr warning.
- `to_windows_path(posix_path)` → echoes `cygpath -w` of the path.
- `link_command_string(os, src, dest)` → echoes the exact command `make_link` would run (for `--dry-run` display and tests).
- `make_link(os, src, dest)` → creates the symlink natively; returns non-zero on failure.
- `is_link_to(os, dest, src)` → returns 0 iff `dest` is a symlink whose target is `src`.
- `ensure_link(name, src, dest)` → orchestration: missing-source handling, idempotency, force/backup, parent-dir creation, dry-run printing. Reads globals `OS`, `DRY_RUN`, `FORCE`.
- `main(args...)` → flag parsing, OS/WSL guards, repo-root resolution, manifest read, two passes.

---

### Task 1: Bootstrap — script skeleton, sourcing guard, test runner

**Files:**
- Create: `scripts/install-skills.sh`
- Create: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `print_usage()`; a sourceable script (no top-level side effects); a test runner that auto-discovers `test_*` functions, provides `assert_eq`, `assert_contains`, `assert_not_contains`, `skip`, `new_sandbox`, and exits non-zero on failure. Defines globals `SCRIPT`, `TMPROOT`.

- [ ] **Step 1: Write the failing test**

Create `tests/install-skills.tests.sh` with the full harness and one trivial test:

```bash
#!/usr/bin/env bash
# Test runner for scripts/install-skills.sh — no external deps (no bats/shellcheck).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../scripts/install-skills.sh"

PASS=0
FAIL=0
SKIP=0

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# new_sandbox -> echoes a fresh empty directory under TMPROOT.
new_sandbox() {
  local d
  d="$(mktemp -d "$TMPROOT/sb.XXXXXX")"
  printf '%s' "$d"
}

assert_eq() { # expected actual message
  if [[ "$1" == "$2" ]]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $3"
    echo "  expected: [$1]"
    echo "  actual:   [$2]"
  fi
}

assert_contains() { # haystack needle message
  if [[ "$1" == *"$2"* ]]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $3"
    echo "  expected to contain: [$2]"
    echo "  in:                  [$1]"
  fi
}

assert_not_contains() { # haystack needle message
  if [[ "$1" != *"$2"* ]]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $3"
    echo "  expected NOT to contain: [$2]"
    echo "  in:                      [$1]"
  fi
}

skip() { # message
  SKIP=$((SKIP + 1))
  echo "SKIP: $1"
}

# host_os -> the OS token for the machine running the tests (gates link-creating tests).
host_os() { detect_os "$(uname -s)" ""; }

# Load the functions under test. The guard in install-skills.sh keeps main() from running.
# shellcheck source=/dev/null
source "$SCRIPT"

# ----- tests -----

test_script_sources_and_usage() {
  local out
  out="$(print_usage)"
  assert_contains "$out" "install-skills.sh" "print_usage mentions the script name"
  assert_contains "$out" "--dry-run" "print_usage documents --dry-run"
  assert_contains "$out" "--force" "print_usage documents --force"
}

# ----- runner (auto-discovers test_* functions) -----
for t in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
  "$t"
done

echo "----"
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[[ "$FAIL" -eq 0 ]]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `source "$SCRIPT"` errors because `scripts/install-skills.sh` does not exist yet (`No such file or directory`).

- [ ] **Step 3: Write the minimal script skeleton**

Create `scripts/install-skills.sh`:

```bash
#!/usr/bin/env bash
# install-skills.sh — link managed skills into ~/.agents/skills and ~/.claude/skills.
# Source of truth: <repo>/skills/<name>. See docs/installation.md.

print_usage() {
  cat <<'EOF'
Usage: install-skills.sh [--dry-run] [--force]

Links every skill listed in skills.manifest.json into:
  ~/.agents/skills/<name>  -> <repo>/skills/<name>      (shared/Codex layer)
  ~/.claude/skills/<name>  -> ~/.agents/skills/<name>   (Claude layer)

  --dry-run  Print what would happen; change nothing.
  --force    Back up an existing entry to <dest>.backup.<timestamp>, then link.
EOF
}

main() {
  print_usage
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — final line `PASS=3 FAIL=0 SKIP=0`. (The `test_script_sources_and_usage` test will report a not-defined error for `detect_os` inside `host_os` only if called; it is not called yet, so the run is clean.)

- [ ] **Step 5: Mark the script executable and commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git update-index --chmod=+x scripts/install-skills.sh
git commit -m "feat(install): bootstrap install-skills.sh and bash test runner"
```

---

### Task 2: OS detection (`detect_os`)

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `detect_os(uname_s, proc_version)` → echoes `darwin | linux | windows | wsl | unknown`. WSL = `uname_s` is `Linux` **and** `proc_version` contains `microsoft` (case-insensitive).

- [ ] **Step 1: Write the failing tests**

Add this function to `tests/install-skills.tests.sh` (anywhere among the `test_*` functions; the runner auto-discovers it):

```bash
test_detect_os() {
  assert_eq "darwin"  "$(detect_os "Darwin" "")"               "Darwin -> darwin"
  assert_eq "linux"   "$(detect_os "Linux" "some kernel build")" "plain Linux -> linux"
  assert_eq "windows" "$(detect_os "MINGW64_NT-10.0-26200" "")" "MINGW -> windows"
  assert_eq "windows" "$(detect_os "MSYS_NT-10.0" "")"          "MSYS -> windows"
  assert_eq "windows" "$(detect_os "CYGWIN_NT-10.0" "")"        "CYGWIN -> windows"
  assert_eq "wsl"     "$(detect_os "Linux" "Linux ... Microsoft ... WSL2")" "Linux + microsoft -> wsl"
  assert_eq "wsl"     "$(detect_os "Linux" "...microsoft-standard-WSL2...")" "lowercase microsoft -> wsl"
  assert_eq "unknown" "$(detect_os "SunOS" "")"                "unrecognized -> unknown"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `detect_os: command not found` (8 failing assertions).

- [ ] **Step 3: Implement `detect_os`**

In `scripts/install-skills.sh`, add the function above `main`:

```bash
detect_os() {
  local uname_s="${1:-$(uname -s)}"
  local proc_version="${2:-}"
  case "$uname_s" in
    Darwin) echo "darwin" ;;
    Linux)
      if printf '%s' "$proc_version" | grep -qi microsoft; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): add OS detection with WSL discrimination"
```

---

### Task 3: Manifest parsing (`read_manifest_skills` + jq and fallback parsers)

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `parse_manifest_names_jq(manifest_path)` → names, one per line, via `jq -r '.skills[].name'`.
  - `parse_manifest_names_fallback(manifest_path)` → names, one per line, via `grep`/`sed`.
  - `read_manifest_skills(manifest_path)` → names; uses `jq` if on `PATH`, else fallback + a stderr warning. Errors to stderr and returns 1 if the file is missing.

- [ ] **Step 1: Write the failing tests**

Add to `tests/install-skills.tests.sh`:

```bash
# Helper: write a small manifest fixture into a sandbox and echo its path.
_write_manifest() {
  local dir="$1"
  cat > "$dir/skills.manifest.json" <<'EOF'
{
  "skills": [
    { "name": "caveman" },
    { "name": "design-an-interface" },
    { "name": "tdd" }
  ]
}
EOF
  printf '%s' "$dir/skills.manifest.json"
}

test_parse_manifest_fallback() {
  local sb manifest out
  sb="$(new_sandbox)"
  manifest="$(_write_manifest "$sb")"
  out="$(parse_manifest_names_fallback "$manifest")"
  assert_eq "caveman
design-an-interface
tdd" "$out" "fallback parser extracts names in order"
}

test_parse_manifest_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not installed; skipping jq parser test"
    return
  fi
  local sb manifest out
  sb="$(new_sandbox)"
  manifest="$(_write_manifest "$sb")"
  out="$(parse_manifest_names_jq "$manifest")"
  assert_eq "caveman
design-an-interface
tdd" "$out" "jq parser extracts names in order"
}

test_read_manifest_skills_happy() {
  local sb manifest out
  sb="$(new_sandbox)"
  manifest="$(_write_manifest "$sb")"
  out="$(read_manifest_skills "$manifest" 2>/dev/null)"
  assert_contains "$out" "caveman" "read_manifest_skills returns caveman"
  assert_contains "$out" "tdd" "read_manifest_skills returns tdd"
}

test_read_manifest_skills_missing_file() {
  local sb rc
  sb="$(new_sandbox)"
  read_manifest_skills "$sb/nope.json" >/dev/null 2>&1
  rc=$?
  assert_eq "1" "$rc" "missing manifest returns non-zero"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `parse_manifest_names_fallback: command not found`, etc.

- [ ] **Step 3: Implement the parsers**

In `scripts/install-skills.sh`, add above `main`:

```bash
parse_manifest_names_jq() {
  jq -r '.skills[].name' "$1"
}

parse_manifest_names_fallback() {
  # Extract each "name": "<value>" occurrence, in file order.
  grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$1" \
    | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
}

read_manifest_skills() {
  local manifest="$1"
  if [[ ! -f "$manifest" ]]; then
    echo "ERROR: missing manifest: $manifest" >&2
    return 1
  fi
  if command -v jq >/dev/null 2>&1; then
    parse_manifest_names_jq "$manifest"
  else
    echo "Warning: jq not found; using grep/sed fallback. Installing jq is recommended." >&2
    parse_manifest_names_fallback "$manifest"
  fi
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`. (On the dev machine `jq` is present, so `test_parse_manifest_jq` runs rather than skips.)

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): parse managed skill names from manifest (jq + fallback)"
```

---

### Task 4: Windows path translation and the dry-run command string

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `to_windows_path(posix_path)` → `cygpath -w "$posix_path"`.
  - `link_command_string(os, src, dest)` → the exact command `make_link` will run. For `darwin`/`linux`: `ln -s "<src>" "<dest>"`. For `windows`: a `powershell.exe -NoProfile -Command "New-Item -ItemType SymbolicLink -Path '<win_dest>' -Target '<win_src>'"` string with both paths converted via `to_windows_path`.

This is the most error-prone step in the design; it is unit-tested directly so the `--dry-run` output is trustworthy on every OS.

- [ ] **Step 1: Write the failing tests**

Add to `tests/install-skills.tests.sh`:

```bash
test_link_command_string_unix() {
  local out
  out="$(link_command_string "linux" "/repo/skills/tdd" "/home/u/.agents/skills/tdd")"
  assert_eq 'ln -s "/repo/skills/tdd" "/home/u/.agents/skills/tdd"' "$out" \
    "linux link command is a plain ln -s"
}

test_link_command_string_windows() {
  if ! command -v cygpath >/dev/null 2>&1; then
    skip "cygpath not available; skipping windows command-string test"
    return
  fi
  local src dest out win_src win_dest
  src="$HOME/.agents/skills/tdd"
  dest="$HOME/.claude/skills/tdd"
  win_src="$(to_windows_path "$src")"
  win_dest="$(to_windows_path "$dest")"
  out="$(link_command_string "windows" "$src" "$dest")"
  assert_contains "$out" "powershell.exe -NoProfile -Command" "uses powershell.exe -NoProfile"
  assert_contains "$out" "New-Item -ItemType SymbolicLink" "creates a SymbolicLink"
  assert_contains "$out" "-Path '$win_dest'" "target path is the cygpath-converted dest"
  assert_contains "$out" "-Target '$win_src'" "link target is the cygpath-converted src"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `link_command_string: command not found` / `to_windows_path: command not found`.

- [ ] **Step 3: Implement the functions**

In `scripts/install-skills.sh`, add above `main`:

```bash
to_windows_path() {
  cygpath -w "$1"
}

link_command_string() {
  local os="$1" src="$2" dest="$3"
  case "$os" in
    darwin|linux)
      printf 'ln -s "%s" "%s"' "$src" "$dest"
      ;;
    windows)
      local win_src win_dest
      win_src="$(to_windows_path "$src")"
      win_dest="$(to_windows_path "$dest")"
      printf "powershell.exe -NoProfile -Command \"New-Item -ItemType SymbolicLink -Path '%s' -Target '%s'\"" \
        "$win_dest" "$win_src"
      ;;
    *)
      printf 'ERROR: unsupported OS for linking: %s' "$os"
      ;;
  esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`. (On the dev machine `cygpath` is present, so the windows test runs.)

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): build per-OS link command string with cygpath translation"
```

---

### Task 5: Link primitives (`make_link`, `is_link_to`)

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: `to_windows_path`, `detect_os` (via `host_os` in tests).
- Produces:
  - `make_link(os, src, dest)` → creates the symlink (`ln -s` on Unix; `powershell.exe New-Item -ItemType SymbolicLink` on windows). On windows failure, prints the Developer-Mode/elevation guidance and returns 1. Never copies.
  - `is_link_to(os, dest, src)` → returns 0 iff `dest` is a symlink whose immediate target is `src`. On windows it compares the `cygpath -w` form via PowerShell's `(Get-Item ...).Target`; on Unix it compares `readlink "$dest"` to `src`.

Link-creating tests are **gated to non-Windows** OSes (see test-environment facts). On Windows these tests `skip`; Task 10 verifies the windows path manually.

- [ ] **Step 1: Write the failing tests**

Add to `tests/install-skills.tests.sh`:

```bash
test_make_link_and_is_link_to_unix() {
  if [[ "$(host_os)" == "windows" ]]; then
    skip "real symlink creation uses powershell on windows; verified manually (Task 10)"
    return
  fi
  local sb src dest
  sb="$(new_sandbox)"
  mkdir -p "$sb/src"
  src="$sb/src"
  dest="$sb/link"

  make_link "$(host_os)" "$src" "$dest"
  assert_eq "0" "$?" "make_link succeeds on unix"
  assert_eq "$src" "$(readlink "$dest")" "link target is src"

  is_link_to "$(host_os)" "$dest" "$src"
  assert_eq "0" "$?" "is_link_to true for a matching link"

  is_link_to "$(host_os)" "$dest" "$sb/other"
  assert_eq "1" "$?" "is_link_to false for a non-matching target"

  is_link_to "$(host_os)" "$sb/missing" "$src"
  assert_eq "1" "$?" "is_link_to false when dest is absent"
}

test_is_link_to_plain_dir_is_false() {
  # A real directory is not a managed link, on every OS.
  local sb
  sb="$(new_sandbox)"
  mkdir -p "$sb/realdir"
  is_link_to "$(host_os)" "$sb/realdir" "$sb/src"
  assert_eq "1" "$?" "is_link_to false for a plain directory"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `make_link: command not found` / `is_link_to: command not found`. (On the Windows dev machine `test_make_link_and_is_link_to_unix` reports SKIP, but `test_is_link_to_plain_dir_is_false` still fails until `is_link_to` exists.)

- [ ] **Step 3: Implement the primitives**

In `scripts/install-skills.sh`, add above `main`:

```bash
make_link() {
  local os="$1" src="$2" dest="$3"
  case "$os" in
    darwin|linux)
      ln -s "$src" "$dest"
      ;;
    windows)
      local win_src win_dest
      win_src="$(to_windows_path "$src")"
      win_dest="$(to_windows_path "$dest")"
      if ! powershell.exe -NoProfile -Command \
        "New-Item -ItemType SymbolicLink -Path '$win_dest' -Target '$win_src' | Out-Null"; then
        echo "ERROR: failed to create symlink at $dest." >&2
        echo "On Windows, enable Developer Mode (Settings > For developers) or run from an" >&2
        echo "elevated shell, then re-run. The installer never falls back to copying." >&2
        return 1
      fi
      ;;
    *)
      echo "ERROR: unsupported OS for linking: $os" >&2
      return 1
      ;;
  esac
}

is_link_to() {
  local os="$1" dest="$2" src="$3"
  case "$os" in
    windows)
      [[ -e "$dest" || -L "$dest" ]] || return 1
      local cur win_src
      cur="$(powershell.exe -NoProfile -Command \
        "(Get-Item -LiteralPath '$(to_windows_path "$dest")' -Force).Target" 2>/dev/null | tr -d '\r')"
      win_src="$(to_windows_path "$src")"
      [[ "$cur" == "$win_src" ]]
      ;;
    *)
      [[ -L "$dest" ]] || return 1
      [[ "$(readlink "$dest")" == "$src" ]]
      ;;
  esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`. On the dev machine the output includes `SKIP: real symlink creation uses powershell on windows; verified manually (Task 10)`.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): add native symlink primitive and idempotency check"
```

---

### Task 6: `ensure_link` orchestration (idempotency, force/backup, dry-run)

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: `is_link_to`, `make_link`, `link_command_string`. Reads globals `OS`, `DRY_RUN`, `FORCE`.
- Produces: `ensure_link(name, src, dest)`:
  - Missing `src`: in dry-run, prints `Would link <name> -> <src> (source created by an earlier pass)` and returns 0; otherwise prints an error and returns 1.
  - Already linked (`is_link_to` true): prints `Already linked <name> -> <src>`, returns 0.
  - `dest` exists but differs, no `--force`: prints `ERROR: refusing to replace existing <dest>...` and returns 1.
  - `dest` exists but differs, `--force`: backs up to `<dest>.backup.<timestamp>` then links (dry-run prints both `Would move...` and `Would link...`).
  - Missing parent dir: creates it (dry-run prints `Would create skills root <parent>`).
  - Link step: dry-run prints `Would link <name> -> <src>` and `  via: <link_command_string>`; real run calls `make_link` then prints `Linked <name> -> <src>`.

- [ ] **Step 1: Write the failing tests**

Add to `tests/install-skills.tests.sh`. These set the globals `ensure_link` reads. The dry-run, refuse, and force-dry-run cases run on **every** OS; the real-creation and idempotency cases are Unix-gated.

```bash
test_ensure_link_dryrun_creates_nothing() {
  local sb out
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/skills/tdd"
  OS="$(host_os)" DRY_RUN=1 FORCE=0
  out="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd")"
  assert_contains "$out" "Would create skills root $sb/home/.agents/skills" "dry-run announces parent creation"
  assert_contains "$out" "Would link tdd -> $sb/repo/skills/tdd" "dry-run announces the link"
  assert_contains "$out" "via:" "dry-run prints the exact command"
  if [[ -e "$sb/home/.agents/skills/tdd" || -L "$sb/home/.agents/skills/tdd" ]]; then
    FAIL=$((FAIL + 1)); echo "FAIL: dry-run must not create the dest"
  else
    PASS=$((PASS + 1))
  fi
}

test_ensure_link_missing_source_dryrun() {
  local sb out
  sb="$(new_sandbox)"
  OS="$(host_os)" DRY_RUN=1 FORCE=0
  out="$(ensure_link "tdd" "$sb/home/.agents/skills/tdd" "$sb/home/.claude/skills/tdd")"
  assert_contains "$out" "source created by an earlier pass" "dry-run tolerates a source from an earlier pass"
}

test_ensure_link_refuses_existing_dir() {
  local sb rc err
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/skills/tdd"
  mkdir -p "$sb/home/.agents/skills/tdd"   # a real directory squatting on the dest
  OS="$(host_os)" DRY_RUN=0 FORCE=0
  err="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd" 2>&1)"
  rc=$?
  assert_eq "1" "$rc" "refuses without --force"
  assert_contains "$err" "refusing to replace existing" "prints the refusal message"
}

test_ensure_link_force_dryrun_announces_backup() {
  local sb out
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/skills/tdd"
  mkdir -p "$sb/home/.agents/skills/tdd"
  OS="$(host_os)" DRY_RUN=1 FORCE=1
  out="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd")"
  assert_contains "$out" "Would move existing $sb/home/.agents/skills/tdd to $sb/home/.agents/skills/tdd.backup." \
    "force dry-run announces a timestamped backup"
  assert_contains "$out" "Would link tdd ->" "force dry-run announces the link"
}

test_ensure_link_real_and_idempotent_unix() {
  if [[ "$(host_os)" == "windows" ]]; then
    skip "real link creation verified manually on windows (Task 10)"
    return
  fi
  local sb out1 out2
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/skills/tdd"
  OS="$(host_os)" DRY_RUN=0 FORCE=0
  out1="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd")"
  assert_contains "$out1" "Linked tdd ->" "first run links"
  assert_eq "$sb/repo/skills/tdd" "$(readlink "$sb/home/.agents/skills/tdd")" "link points at the source"
  out2="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd")"
  assert_contains "$out2" "Already linked tdd ->" "second run is idempotent"
}

test_ensure_link_force_backup_real_unix() {
  if [[ "$(host_os)" == "windows" ]]; then
    skip "force backup verified manually on windows (Task 10)"
    return
  fi
  local sb out
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/skills/tdd"
  mkdir -p "$sb/home/.agents/skills/tdd"
  echo "marker" > "$sb/home/.agents/skills/tdd/old.txt"
  OS="$(host_os)" DRY_RUN=0 FORCE=1
  out="$(ensure_link "tdd" "$sb/repo/skills/tdd" "$sb/home/.agents/skills/tdd")"
  assert_contains "$out" "Backed up tdd to" "announces the backup"
  assert_eq "$sb/repo/skills/tdd" "$(readlink "$sb/home/.agents/skills/tdd")" "dest is now a link to the source"
  local backup_count
  backup_count="$(find "$sb/home/.agents/skills" -maxdepth 1 -name 'tdd.backup.*' -type d | wc -l | tr -d ' ')"
  assert_eq "1" "$backup_count" "exactly one backup directory was created"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — `ensure_link: command not found`.

- [ ] **Step 3: Implement `ensure_link`**

In `scripts/install-skills.sh`, add above `main`:

```bash
ensure_link() {
  local name="$1" src="$2" dest="$3"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      echo "Would link $name -> $src (source created by an earlier pass)"
      return 0
    fi
    echo "ERROR: missing source for $name: $src" >&2
    return 1
  fi

  if is_link_to "${OS}" "$dest" "$src"; then
    echo "Already linked $name -> $src"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "${FORCE:-0}" != "1" ]]; then
      echo "ERROR: refusing to replace existing $dest. Re-run with --force after verifying it should be managed." >&2
      return 1
    fi
    local backup="$dest.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      echo "Would move existing $dest to $backup"
      echo "Would link $name -> $src"
      echo "  via: $(link_command_string "${OS}" "$src" "$dest")"
      return 0
    fi
    mv "$dest" "$backup"
    echo "Backed up $name to $backup"
  fi

  local parent
  parent="$(dirname "$dest")"
  if [[ ! -d "$parent" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      echo "Would create skills root $parent"
    else
      mkdir -p "$parent"
    fi
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "Would link $name -> $src"
    echo "  via: $(link_command_string "${OS}" "$src" "$dest")"
    return 0
  fi

  make_link "${OS}" "$src" "$dest" || return 1
  echo "Linked $name -> $src"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`. On the dev machine the two `*_unix` tests report SKIP.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): orchestrate ensure_link with idempotency, force backup, dry-run"
```

---

### Task 7: `main` — flags, OS/WSL guards, repo resolution, two passes

**Files:**
- Modify: `scripts/install-skills.sh`
- Test: `tests/install-skills.tests.sh`

**Interfaces:**
- Consumes: `detect_os`, `read_manifest_skills`, `ensure_link`. Sets globals `OS`, `DRY_RUN`, `FORCE`.
- Produces: `main(args...)`:
  - Parses `--dry-run`, `--force`, `-h`/`--help` (prints usage, returns 0); unknown args print usage to stderr and return 2.
  - Resolves `OS = detect_os(uname -s, /proc/version)`. WSL → error + guidance, return 1. `unknown` → error, return 1.
  - Resolves `repo_root` from `${BASH_SOURCE[0]}/..` (no hardcoded path). `manifest = <repo_root>/skills.manifest.json`.
  - Pass 1 (shared/Codex): `ensure_link <name> <repo>/skills/<name> $HOME/.agents/skills/<name>`.
  - Pass 2 (Claude): `ensure_link <name> $HOME/.agents/skills/<name> $HOME/.claude/skills/<name>`.

The integration tests run the **installed script as a subprocess** against a self-contained sandbox repo (script copied in) with `HOME` pointed at the sandbox — so repo-root resolution and `$HOME`-based targets are exercised honestly. The dry-run integration test runs on **every** OS (it is the spec's primary cross-OS self-check); the real full-run is Unix-gated.

- [ ] **Step 1: Write the failing tests**

Add to `tests/install-skills.tests.sh`:

```bash
# _make_repo <sandbox> -> builds a sandbox repo with the script, a 1-skill manifest,
# and the skill source; echoes the repo path.
_make_repo() {
  local sb="$1"
  mkdir -p "$sb/repo/scripts" "$sb/repo/skills/sample" "$sb/home"
  cp "$SCRIPT" "$sb/repo/scripts/install-skills.sh"
  cat > "$sb/repo/skills.manifest.json" <<'EOF'
{ "skills": [ { "name": "sample" } ] }
EOF
  cat > "$sb/repo/skills/sample/SKILL.md" <<'EOF'
---
name: sample
description: Test skill
---
Sample.
EOF
  printf '%s' "$sb/repo"
}

test_main_help() {
  local out rc
  out="$(HOME="$TMPROOT/ignored" bash "$SCRIPT" --help)"
  rc=$?
  assert_eq "0" "$rc" "--help exits 0"
  assert_contains "$out" "Usage: install-skills.sh" "--help prints usage"
}

test_main_unknown_arg() {
  local rc
  HOME="$TMPROOT/ignored" bash "$SCRIPT" --bogus >/dev/null 2>&1
  rc=$?
  assert_eq "2" "$rc" "unknown arg exits 2"
}

test_main_dryrun_both_passes() {
  local sb repo out
  sb="$(new_sandbox)"
  repo="$(_make_repo "$sb")"
  out="$(HOME="$sb/home" bash "$repo/scripts/install-skills.sh" --dry-run)"
  assert_contains "$out" "Pass 1" "announces pass 1"
  assert_contains "$out" "Pass 2" "announces pass 2"
  assert_contains "$out" "Would link sample -> $repo/skills/sample" "pass 1 links sample from the repo"
  assert_contains "$out" "$sb/home/.agents/skills/sample (source created by an earlier pass)" \
    "pass 2 tolerates the not-yet-created shared link"
  # dry-run must not touch the filesystem
  if [[ -e "$sb/home/.agents/skills/sample" || -e "$sb/home/.claude/skills/sample" ]]; then
    FAIL=$((FAIL + 1)); echo "FAIL: dry-run created filesystem entries"
  else
    PASS=$((PASS + 1))
  fi
}

test_main_real_full_run_unix() {
  if [[ "$(host_os)" == "windows" ]]; then
    skip "real full run verified manually on windows (Task 10)"
    return
  fi
  local sb repo
  sb="$(new_sandbox)"
  repo="$(_make_repo "$sb")"
  HOME="$sb/home" bash "$repo/scripts/install-skills.sh" >/dev/null
  assert_eq "$repo/skills/sample" "$(readlink "$sb/home/.agents/skills/sample")" \
    "shared link points at the repo skill"
  assert_eq "$sb/home/.agents/skills/sample" "$(readlink "$sb/home/.claude/skills/sample")" \
    "claude link points at the shared link"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/install-skills.tests.sh`
Expected: FAIL — the current `main` only calls `print_usage`, so `--help` passes by accident but `test_main_unknown_arg` (expects exit 2), `test_main_dryrun_both_passes` (expects `Pass 1`), and the real-run test fail.

- [ ] **Step 3: Implement `main`**

In `scripts/install-skills.sh`, replace the placeholder `main` with:

```bash
main() {
  set -uo pipefail

  DRY_RUN=0
  FORCE=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --force)   FORCE=1 ;;
      -h|--help) print_usage; return 0 ;;
      *) echo "Unknown argument: $arg" >&2; print_usage >&2; return 2 ;;
    esac
  done

  local proc_version
  proc_version="$(cat /proc/version 2>/dev/null || true)"
  OS="$(detect_os "$(uname -s)" "$proc_version")"

  if [[ "$OS" == "wsl" ]]; then
    echo "ERROR: Detected WSL. Run this from Git Bash or PowerShell on Windows, not WSL." >&2
    echo "Links created from WSL under /mnt/c are not reliably followed by Windows-native apps." >&2
    return 1
  fi
  if [[ "$OS" == "unknown" ]]; then
    echo "ERROR: Unsupported OS (uname -s: $(uname -s))." >&2
    return 1
  fi

  local script_dir repo_root manifest agents_root claude_root names
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/.." && pwd)"
  manifest="$repo_root/skills.manifest.json"
  agents_root="$HOME/.agents/skills"
  claude_root="$HOME/.claude/skills"

  names="$(read_manifest_skills "$manifest")" || return 1

  echo "== Pass 1: shared/Codex layer ($agents_root) =="
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    ensure_link "$name" "$repo_root/skills/$name" "$agents_root/$name" || return 1
  done <<< "$names"

  echo "== Pass 2: Claude layer ($claude_root) =="
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    ensure_link "$name" "$agents_root/$name" "$claude_root/$name" || return 1
  done <<< "$names"

  echo "Done."
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0`. On the dev machine `test_main_real_full_run_unix` reports SKIP.

- [ ] **Step 5: Run the installer's own dry-run against the real repo (manual smoke)**

Run: `bash scripts/install-skills.sh --dry-run`
Expected: prints `== Pass 1 ...`, a `Would link <name> -> <repo>/skills/<name>` and a `  via: powershell.exe ... New-Item -ItemType SymbolicLink ...` line for each of the 19 manifest skills, then `== Pass 2 ...`, then `Done.`. No filesystem changes.

- [ ] **Step 6: Commit**

```bash
git add scripts/install-skills.sh tests/install-skills.tests.sh
git commit -m "feat(install): wire main with flag parsing, WSL guard, and two-pass linking"
```

---

### Task 8: Retire the PowerShell scripts and their test

**Files:**
- Delete: `scripts/install-codex-skills.ps1`
- Delete: `scripts/install-claude-skills.ps1`
- Delete: `tests/install-scripts.tests.ps1`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing (removal only). The bash script + bash tests fully subsume these.

- [ ] **Step 1: Confirm nothing else references the old scripts**

Run: `grep -rn "install-codex-skills\|install-claude-skills\|install-scripts.tests" --include='*.md' --include='*.sh' --include='*.json' .`
Expected: matches only in `README.md`, `docs/installation.md` (handled in Task 9) and possibly this plan. No code references remain.

- [ ] **Step 2: Delete the three files**

```bash
git rm scripts/install-codex-skills.ps1 scripts/install-claude-skills.ps1 tests/install-scripts.tests.ps1
```

- [ ] **Step 3: Verify the bash test suite still passes**

Run: `bash tests/install-skills.tests.sh`
Expected: PASS — `FAIL=0` (deleting the `.ps1` files does not affect the bash suite).

- [ ] **Step 4: Commit**

```bash
git commit -m "chore(install): retire PowerShell installers superseded by install-skills.sh"
```

---

### Task 9: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/installation.md`
- Modify: `docs/provider-adapters.md`

**Interfaces:**
- Consumes: nothing.
- Produces: docs that describe `./scripts/install-skills.sh [--dry-run] [--force]`, use `~`/`<repo>` placeholders only, and add the Prerequisites note.

- [ ] **Step 1: Update `README.md` — Layout block**

Replace the `scripts/` lines in the Layout code block:

```text
scripts/
  install-codex-skills.ps1
  install-claude-skills.ps1
```

with:

```text
scripts/
  install-skills.sh
```

- [ ] **Step 2: Update `README.md` — Install block**

Replace the entire `## Install` section body (the PowerShell code block and the `-Force` note) with:

````markdown
## Install

From this repo:

```bash
./scripts/install-skills.sh --dry-run   # preview
./scripts/install-skills.sh             # apply
```

The script builds both layers in one run: `~/.agents/skills/<name>` (shared/Codex)
then `~/.claude/skills/<name>` (Claude), each a symlink back toward
`<repo>/skills/<name>`. Use `--force` only after reviewing the dry run; it backs up
an existing entry to `<dest>.backup.<timestamp>` before replacing it.

**Prerequisites:** On Windows, run from **Git Bash** (provides `bash`, `cygpath`, and
the bundled `powershell.exe`) with **Developer Mode** enabled (Settings → For
developers) so symlinks can be created; do **not** run from WSL. `jq` is optional but
recommended. macOS/Linux need only `bash`.

See [docs/installation.md](docs/installation.md) for the full flow.
````

- [ ] **Step 3: Rewrite `docs/installation.md`**

Replace the whole file with:

````markdown
# Installation

Run from the repository root (referred to below as `<repo>`).

## 1. Prerequisites

- **macOS / Linux:** `bash`. `jq` optional (recommended).
- **Windows:** **Git Bash** (provides `bash`, `cygpath`, and the bundled
  `powershell.exe`) and **Developer Mode** enabled (Settings → For developers) so
  symlinks can be created. Do **not** run from WSL — links made under `/mnt/c` are not
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
````

- [ ] **Step 4: Update `docs/provider-adapters.md` — replace hardcoded paths**

- Replace the canonical-source block `C:\Git\agent-skills-shared\skills\<skill-name>` with `<repo>/skills/<skill-name>`.
- Replace `~\.agents\skills\<skill-name>` with `~/.agents/skills/<skill-name>` and the line "Installed as a junction to the canonical source." with "Installed as a symlink to the canonical source."
- Replace `~\.claude\skills\<skill-name>` with `~/.claude/skills/<skill-name>` and "Installed as a junction to the Codex/shared runtime path." with "Installed as a symlink to the Codex/shared runtime path."
- Replace the project-local example block `C:\Git\retireratio\.claude\skills\finance-audit` with `<your-project>/.claude/skills/finance-audit`.

- [ ] **Step 5: Confirm no machine-specific paths remain in docs**

Run: `grep -rn 'C:\\\\Users\|C:\\\\Git\|install-codex-skills\|install-claude-skills\|Junction' README.md docs/`
Expected: no matches.

- [ ] **Step 6: Commit**

```bash
git add README.md docs/installation.md docs/provider-adapters.md
git commit -m "docs: document os-agnostic install-skills.sh and drop machine paths"
```

---

### Task 10: Final verification (static analysis + manual Windows real-run)

**Files:** none (verification only).

**Interfaces:**
- Consumes: the finished script.
- Produces: confidence that the script is portable and that the Windows symlink path (not covered by the automated suite) works on a real machine.

- [ ] **Step 1: Run the full bash test suite**

Run: `bash tests/install-skills.tests.sh`
Expected: final line `PASS=<n> FAIL=0 SKIP=<m>`. On Windows, `SKIP` covers the Unix-gated real-link tests; on macOS/Linux, `SKIP` is 0 (or only the jq test if `jq` is absent).

- [ ] **Step 2: Run shellcheck if available**

Run: `command -v shellcheck >/dev/null 2>&1 && shellcheck scripts/install-skills.sh || echo "shellcheck not installed; skipping (install: https://www.shellcheck.net) "`
Expected: either no shellcheck findings, or the "not installed" notice. If findings appear, fix them (quoting/portability) and re-run the bash test suite before continuing. `shellcheck` is not on the dev machine, so this step is best-effort there.

- [ ] **Step 3: Windows real-run smoke test (manual, dev machine)**

Run (review first):

```bash
bash scripts/install-skills.sh --dry-run   # confirm cygpath-converted paths + powershell command look right
bash scripts/install-skills.sh             # apply for real
```

Then verify the chain in PowerShell:

```powershell
Get-Item ~/.claude/skills/prd | Select-Object LinkType,Target
Get-Item ~/.agents/skills/prd | Select-Object LinkType,Target
```

Expected: `LinkType` is `SymbolicLink`; `~/.claude/skills/prd` targets `~/.agents/skills/prd`, which targets `<repo>/skills/prd`. If `New-Item` fails, enable Developer Mode (Settings → For developers) or use an elevated shell, then re-run. Re-running the installer should print `Already linked ...` for every skill (idempotency).

- [ ] **Step 4: No commit**

This task changes no tracked files. The real-run creates links under `~`, which are not part of the repo.

---

## Self-Review

**1. Spec coverage:**

| Spec item | Task |
|---|---|
| Single `scripts/install-skills.sh` (bash) | Tasks 1, 7 |
| Symlinks on every OS, never junctions/copy | Task 5 |
| `ensure_link <name> <src> <dest>` (absolute paths, idempotent, force/backup, dry-run) | Task 6 |
| OS detection branch (Darwin/Linux vs MINGW/MSYS/CYGWIN) | Task 2 |
| Windows path translation via `cygpath -w` + PowerShell shell-out | Tasks 4, 5 |
| Manifest parse with `jq`, `grep`/`sed` fallback + warning | Task 3 |
| Hard-stop on WSL with guidance | Task 7 |
| Windows missing-privilege guard (fail loudly, never silent copy) | Task 5 (`make_link`) |
| Two ordered passes (shared then Claude) in one script | Task 7 |
| Resolve `repo_root` from script location; no hardcoded paths | Task 7 |
| Flags `--dry-run`, `--force` | Tasks 6, 7 |
| Retire the two `.ps1` scripts | Task 8 |
| Docs: README, installation.md, provider-adapters.md; Prerequisites note; `~`/`<repo>` placeholders | Task 9 |
| Verification: shellcheck, dry-run cross-OS, real-run verify | Task 10 (+ dry-run/real tests in Tasks 6–7) |
| Out of scope: chain topology, manifest format, uninstall, auto-installing deps | Not implemented (correct) |

**2. Placeholder scan:** No `TBD`/`TODO`/"handle edge cases"/"similar to Task N". Every code step shows complete code; every test step shows complete tests; every run step shows the command and expected output.

**3. Type consistency:** Function names and the globals they read (`OS`, `DRY_RUN`, `FORCE`) are consistent across Tasks 2–7. `link_command_string`, `make_link`, `is_link_to`, `ensure_link`, `read_manifest_skills`, `to_windows_path`, `detect_os` are spelled identically in their definitions, their callers, and the tests. The dry-run output strings asserted in tests (`Would link`, `Would create skills root`, `Would move existing`, `Already linked`, `Linked`, `Backed up`, `refusing to replace existing`, `source created by an earlier pass`) match the strings emitted by `ensure_link`/`main`.
