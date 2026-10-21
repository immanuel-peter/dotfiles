#!/usr/bin/env bash
# Bootstrap a machine for coding agents: Linux apt packages, nvm + Node LTS,
# HF CLI, rclone, agent CLIs, MCP configs, skills.
#
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/setup.sh | bash
#
# From a checkout: ./setup.sh
#
# Override the GitHub source with DOTFILES_REPO / DOTFILES_REF if needed.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-immanuel-peter/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-main}"
ARCHIVE_URL="https://github.com/${DOTFILES_REPO}/archive/${DOTFILES_REF}.tar.gz"

export DOTFILES_REPO DOTFILES_REF
# Child installers skip "run the next script" hints while this orchestrator
# is about to run them.
export DOTFILES_SETUP=1

ROOT=""
CLEANUP_DIR=""

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
else
  C_RESET= C_BOLD= C_DIM= C_GREEN= C_YELLOW= C_RED= C_CYAN=
fi

info()  { printf '%s==>%s %s\n' "${C_BOLD}${C_CYAN}" "${C_RESET}" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"; }
warn()  { printf '%s  !%s %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }
err()   { printf '%s  ✗%s %s\n' "${C_RED}" "${C_RESET}" "$*" >&2; }

die() {
  err "$*"
  exit 1
}

cleanup() {
  if [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]]; then
    rm -rf "$CLEANUP_DIR"
  fi
}
trap cleanup EXIT

download() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    die "Need curl or wget to fetch ${url}"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1 ($2)"
}

# Checkout next to this script, or a fetched tarball of DOTFILES_REPO@DOTFILES_REF.
# `curl …/setup.sh | bash` has no script path, so that path always fetches.
resolve_root() {
  local src="${BASH_SOURCE[0]:-}"
  local dir=""
  if [[ -n "$src" && -f "$src" ]]; then
    dir="$(cd "$(dirname "$src")" && pwd)"
  fi

  if [[ -n "$dir" \
    && -f "$dir/deps/install-apt.sh" \
    && -f "$dir/deps/install-hf.sh" \
    && -f "$dir/deps/install-rclone.sh" \
    && -f "$dir/install-node.sh" \
    && -f "$dir/agents/install.sh" \
    && -f "$dir/mcp/install.sh" \
    && -f "$dir/skills/install.sh" ]]; then
    ROOT="$dir"
    return
  fi

  info "No local checkout — fetching ${DOTFILES_REPO}@${DOTFILES_REF}"
  local tmp archive candidate extracted
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX")"
  CLEANUP_DIR="$tmp"
  archive="${tmp}/src.tar.gz"
  download "$ARCHIVE_URL" "$archive"

  tar -xzf "$archive" -C "$tmp"

  extracted=""
  for candidate in "$tmp"/*; do
    if [[ -d "$candidate" && -f "$candidate/deps/install-apt.sh" && -f "$candidate/deps/install-hf.sh" && -f "$candidate/deps/install-rclone.sh" && -f "$candidate/install-node.sh" && -f "$candidate/agents/install.sh" ]]; then
      extracted="$candidate"
      break
    fi
  done
  [[ -n "$extracted" ]] || die "Archive from ${ARCHIVE_URL} is missing deps/install-apt.sh, deps/install-hf.sh, deps/install-rclone.sh, install-node.sh, or agents/install.sh"

  ROOT="$extracted"
  ok "Fetched repo into ${ROOT}"
}

run_installer() {
  local label="$1"
  local script="$2"
  [[ -f "$script" ]] || die "Missing ${script}"
  # </dev/null so a curl|bash of this file cannot have its stdin eaten by a child.
  bash "$script" </dev/null || die "${label} failed"
}

main() {
  printf '%s\n' "${C_BOLD}Dotfiles setup${C_RESET}"
  printf '%s\n\n' "${C_DIM}Linux apt packages, HF CLI, rclone, Node LTS, agent CLIs, MCP configs, agent skills${C_RESET}"

  # Fail before any installer. mcp/install.sh needs both.
  require_cmd python3 "needed to merge Codex MCP config"
  require_cmd jq "needed to merge Claude MCP config"

  resolve_root
  if [[ -z "$CLEANUP_DIR" ]]; then
    printf '%s\n\n' "${C_DIM}source: ${ROOT}${C_RESET}"
  else
    printf '%s\n\n' "${C_DIM}source: ${DOTFILES_REPO}@${DOTFILES_REF}${C_RESET}"
  fi

  run_installer "Apt packages" "${ROOT}/deps/install-apt.sh"
  echo
  run_installer "HF CLI install" "${ROOT}/deps/install-hf.sh"
  echo
  run_installer "rclone install" "${ROOT}/deps/install-rclone.sh"
  echo
  run_installer "Node install" "${ROOT}/install-node.sh"
  echo
  run_installer "Agents install" "${ROOT}/agents/install.sh"
  echo
  run_installer "MCP install" "${ROOT}/mcp/install.sh"
  echo
  run_installer "Skills install" "${ROOT}/skills/install.sh"
  echo

  info "Setup complete"
  ok "Linux apt packages, HF CLI, rclone, Node LTS via nvm, agent CLIs, MCP configs, and agent skills"
  ok "Open a new shell so nvm's node is on PATH"
}

main "$@"
