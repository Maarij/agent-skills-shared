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

main() {
  print_usage
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
