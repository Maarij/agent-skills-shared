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
  jq -r '.skills[].name' "$1" | tr -d '\r'
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

main() {
  print_usage
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
