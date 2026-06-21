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
  assert_contains "$out" "powershell.exe -NoProfile -Command" "uses powershell.exe -NoProfile"
  assert_contains "$out" "New-Item -ItemType SymbolicLink" "creates a SymbolicLink"
  assert_contains "$out" "-Path '$win_dest'" "target path is the cygpath-converted dest"
  assert_contains "$out" "-Target '$win_src'" "link target is the cygpath-converted src"
}

# ----- runner (auto-discovers test_* functions) -----
for t in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
  "$t"
done

echo "----"
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[[ "$FAIL" -eq 0 ]]
