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
