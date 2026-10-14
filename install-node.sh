#!/usr/bin/env bash
# Bootstrap nvm + Node.js LTS on a fresh remote machine.
#
# Does not install MCP configs — run mcp/install.sh after this.
#
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/install-node.sh | bash
#
# Override the GitHub source with DOTFILES_REPO / DOTFILES_REF if needed.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-immanuel-peter/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-main}"
MCP_INSTALL_URL="https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/mcp/install.sh"

NVM_VERSION="v0.40.6"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"

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

# nvm.sh is not nounset-safe.
with_nvm() {
  set +u
  "$@"
  local rc=$?
  set -u
  return "$rc"
}

find_nvm_sh() {
  local candidates=(
    "${NVM_DIR:-}/nvm.sh"
    "${HOME}/.nvm/nvm.sh"
    "/opt/homebrew/opt/nvm/nvm.sh"
    "/usr/local/opt/nvm/nvm.sh"
  )
  local path
  for path in "${candidates[@]}"; do
    if [[ -n "$path" && -s "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

load_nvm() {
  local nvm_sh
  nvm_sh="$(find_nvm_sh)" || return 1
  export NVM_DIR
  NVM_DIR="$(cd "$(dirname "$nvm_sh")" && pwd)"
  # shellcheck disable=SC1090
  with_nvm . "$nvm_sh"
}

install_nvm() {
  info "Installing nvm ${NVM_VERSION} into ~/.nvm"
  command -v git >/dev/null 2>&1 || die "git is required to install nvm"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$NVM_INSTALL_URL" | bash
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$NVM_INSTALL_URL" | bash
  else
    die "Need curl or wget to download nvm"
  fi
  export NVM_DIR="${HOME}/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] || die "nvm install finished but ${NVM_DIR}/nvm.sh is missing"
  ok "nvm installed at ${NVM_DIR/#$HOME/~}"
}

install_node_lts() {
  info "Installing Node.js LTS via nvm"
  with_nvm nvm install --lts
  with_nvm nvm alias default 'lts/*'
  with_nvm nvm use --lts
  ok "node $(node -v)  npm $(npm -v)"
}

main() {
  printf '%s\n' "${C_BOLD}Node bootstrap${C_RESET}"
  printf '%s\n\n' "${C_DIM}nvm ${NVM_VERSION} + Node LTS${C_RESET}"

  if load_nvm; then
    ok "nvm already present (${NVM_DIR/#$HOME/~})"
  else
    install_nvm
    load_nvm || die "Failed to load nvm after install"
  fi

  install_node_lts
  echo

  info "Done"
  ok "Open a new shell (or: source ${NVM_DIR/#$HOME/~}/nvm.sh)"

  # setup.sh runs MCP itself; don't tell the user to do that next.
  if [[ -n "${DOTFILES_SETUP:-}" ]]; then
    return
  fi

  local sibling=""
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" ]]; then
    sibling="$(cd "$(dirname "$src")" && pwd)/mcp/install.sh"
  fi
  if [[ -n "$sibling" && -f "$sibling" ]]; then
    ok "Then install MCP configs:  $sibling"
  fi
  ok "Or: curl -fsSL ${MCP_INSTALL_URL} | bash"
}

main "$@"
