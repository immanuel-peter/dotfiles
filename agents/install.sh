#!/usr/bin/env bash
# Install Claude Code, Codex, OpenCode, Grok Build, and Muse Code.
#
#   ./agents/install.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/agents/install.sh | bash
#
# Stops on the first failure. Sign-in is separate. Override the GitHub source
# with DOTFILES_REPO / DOTFILES_REF if needed.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-immanuel-peter/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/agents"

ROOT=""
CLEANUP_DIR=""
INSTALLERS=(install-claude.sh install-codex.sh install-opencode.sh install-grok.sh install-muse.sh)

cleanup() {
  if [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

# A piped script has no BASH_SOURCE path or sibling installers. Download all
# five before running any of them, and keep children away from the script's stdin.
resolve_root() {
  local src="${BASH_SOURCE[0]:-}"
  local dir="" script
  if [[ -n "$src" && -f "$src" ]]; then
    dir="$(cd "$(dirname "$src")" && pwd)"
  fi

  if [[ -n "$dir" ]]; then
    local all_present=1
    for script in "${INSTALLERS[@]}"; do
      if [[ ! -f "$dir/$script" ]]; then
        all_present=0
        break
      fi
    done
    if (( all_present )); then
      ROOT="$dir"
      return
    fi
  fi

  command -v curl >/dev/null 2>&1 || {
    printf 'Missing required command: curl\n' >&2
    exit 1
  }
  CLEANUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-agents.XXXXXX")"
  ROOT="$CLEANUP_DIR"
  printf '==> Fetching agent installers from %s@%s\n' "$DOTFILES_REPO" "$DOTFILES_REF"
  for script in "${INSTALLERS[@]}"; do
    curl -fsSL "${RAW_BASE}/${script}" -o "${ROOT}/${script}"
  done
}

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

resolve_root
run "Claude Code" "${ROOT}/install-claude.sh"
run "Codex" "${ROOT}/install-codex.sh"
run "OpenCode" "${ROOT}/install-opencode.sh"
run "Grok Build" "${ROOT}/install-grok.sh"
run "Muse Code" "${ROOT}/install-muse.sh"
