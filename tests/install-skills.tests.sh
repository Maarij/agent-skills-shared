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

# ----- runner (auto-discovers test_* functions) -----
for t in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
  "$t"
done

echo "----"
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
[[ "$FAIL" -eq 0 ]]
