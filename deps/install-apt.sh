#!/usr/bin/env bash
# Install apt packages for a Linux machine.
# Currently cloudflared, from Cloudflare's apt repository:
# https://developers.cloudflare.com/tunnel/downloads/
#
#   ./deps/install-apt.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-apt.sh | bash
#
# Skips on non-Linux, and on Linux when apt-get is missing. Skips cloudflared
# when it is already on PATH. Requires root or passwordless/cached sudo;
# never prompts for credentials or package configuration.
set -euo pipefail

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

cloudflared_version() {
  cloudflared --version 2>/dev/null | awk 'NR==1 { print $3 }'
}

install_cloudflared() {
  info "Checking cloudflared"
  if command -v cloudflared >/dev/null 2>&1; then
    ok "cloudflared $(cloudflared_version) ($(command -v cloudflared))"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "Need curl to fetch the Cloudflare apt key"
  local -a elevate=()
  if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install cloudflared"
    sudo -n true || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
    elevate=(sudo -n)
  fi

  info "Installing cloudflared"

  "${elevate[@]}" mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | "${elevate[@]}" tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
    | "${elevate[@]}" tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold cloudflared </dev/null

  command -v cloudflared >/dev/null 2>&1 || die "cloudflared install finished but it is not on PATH"
  ok "cloudflared $(cloudflared_version)"
}

main() {
  printf '%s\n' "${C_BOLD}Apt packages${C_RESET}"
  printf '%s\n\n' "${C_DIM}cloudflared on Debian and Ubuntu${C_RESET}"

  if [[ "$(uname -s)" != Linux ]]; then
    ok "Not Linux ($(uname -s)); skipping apt packages"
    return
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    warn "apt-get not found; skipping cloudflared"
    return
  fi

  install_cloudflared
  echo
  info "Done"
}

main "$@"
