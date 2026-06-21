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
  assert_contains "$out" "design-an-interface" "read_manifest_skills returns design-an-interface"
  assert_contains "$out" "tdd" "read_manifest_skills returns tdd"
}

test_read_manifest_skills_missing_file() {
  local sb rc
  sb="$(new_sandbox)"
  read_manifest_skills "$sb/nope.json" >/dev/null 2>&1
  rc=$?
  assert_eq "1" "$rc" "missing manifest returns non-zero"
}

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
  assert_contains "$out" "cmd.exe /c mklink /D" "uses cmd mklink (works unprivileged under Developer Mode)"
  assert_not_contains "$out" "New-Item -ItemType SymbolicLink" "does not use PowerShell 5.1 New-Item"
  assert_contains "$out" "\"$win_dest\"" "link path is the cygpath-converted dest"
  assert_contains "$out" "\"$win_src\"" "link target is the cygpath-converted src"
}

test_make_link_and_is_link_to_unix() {
  if [[ "$(host_os)" == "windows" ]]; then
    skip "real symlink creation uses cmd mklink on windows; verified manually"
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

test_main_empty_manifest_fails() {
  local sb repo out rc
  sb="$(new_sandbox)"
  mkdir -p "$sb/repo/scripts" "$sb/home"
  cp "$SCRIPT" "$sb/repo/scripts/install-skills.sh"
  cat > "$sb/repo/skills.manifest.json" <<'EOF'
{ "skills": [] }
EOF
  repo="$sb/repo"
  out="$(HOME="$sb/home" bash "$repo/scripts/install-skills.sh" --dry-run 2>&1)"
  rc=$?
  assert_eq "1" "$rc" "empty manifest exits non-zero"
  assert_contains "$out" "no managed skills found" "empty manifest prints no managed skills found"
}

# ----- runner (auto-discovers test_* functions) -----
for t in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
  "$t"
done

echo "----"
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[[ "$FAIL" -eq 0 ]]
