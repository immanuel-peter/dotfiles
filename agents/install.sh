#!/usr/bin/env bash
# Install Claude Code, Codex, OpenCode, Grok Build, and Muse Code.
#
#   ./agents/install.sh
#
# Stops on the first failure. Sign-in is separate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
  local label="$1"
  local script="$2"
  [[ -f "$script" ]] || {
    printf 'Missing %s\n' "$script" >&2
    exit 1
  }
  printf '==> %s\n' "$label"
  bash "$script" </dev/null
}

run "Claude Code" "${ROOT}/install-claude.sh"
run "Codex" "${ROOT}/install-codex.sh"
run "OpenCode" "${ROOT}/install-opencode.sh"
run "Grok Build" "${ROOT}/install-grok.sh"
run "Muse Code" "${ROOT}/install-muse.sh"
