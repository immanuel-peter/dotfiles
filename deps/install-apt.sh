#!/usr/bin/env bash
# Install apt packages for a Linux machine.
# cloudflared, from Cloudflare's apt repository:
# https://developers.cloudflare.com/tunnel/downloads/
# gh, from GitHub's apt repository:
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
#
#   ./deps/install-apt.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-apt.sh | bash
#
# Skips on non-Linux, and on Linux when apt-get is missing. Skips cloudflared
# when it is already on PATH. gh is installed or upgraded from the official
# repository. Also installs terminal tools, venv support for the distro's
# default Python, and libatomic1 when the T3 Code CLI's libatomic.so.1 is missing.
# sudo is used only for the apt steps.
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

libatomic_installed() {
  local status
  status="$(dpkg-query -W -f='${Status}' libatomic1 2>/dev/null || true)"
  [[ "$status" == "install ok installed" ]]
}

install_libatomic() {
  info "Checking libatomic1"
  if libatomic_installed; then
    ok "libatomic1 already installed"
    return
  fi

  info "Installing libatomic1"
  local -a elevate=()
  if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install libatomic1"
    sudo -n true </dev/null || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
    elevate=(sudo -n)
  fi

  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold libatomic1 </dev/null

  libatomic_installed || die "libatomic1 install finished but the package is not installed"
  ok "libatomic1 installed"
}

install_python_venv() {
  info "Installing Python venv support"
  local -a elevate=()
  if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install python3-venv"
    sudo -n true || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
    elevate=(sudo -n)
  fi

  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold python3-venv </dev/null
  ok "Python venv support installed"
}

link_tool() {
  local name="$1" fallback="$2" target
  if command -v "$name" >/dev/null 2>&1; then
    return
  fi
  target="$(command -v "$fallback" || true)"
  [[ -n "$target" ]] || die "Neither $name nor $fallback is on PATH after installation"
  if [[ -e "$HOME/.local/bin/$name" || -L "$HOME/.local/bin/$name" ]]; then
    warn "$HOME/.local/bin/$name already exists; leaving it unchanged"
    return
  fi
  mkdir -p "$HOME/.local/bin"
  ln -s "$target" "$HOME/.local/bin/$name"
  if ! command -v "$name" >/dev/null 2>&1; then
    warn "Add $HOME/.local/bin to PATH to use $name"
  fi
}

install_terminal_tools() {
  info "Installing terminal tools"
  local -a elevate=(env)
  if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install terminal tools"
    sudo -n true </dev/null || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
    elevate=(sudo -n env)
  fi

  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold bat fd-find ripgrep micro </dev/null

  link_tool bat batcat
  link_tool fd fdfind
  ok "Terminal tools installed"
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

gh_version() {
  gh --version 2>/dev/null | awk 'NR==1 { print $3 }'
}

install_gh() {
  info "Installing GitHub CLI"
  command -v dpkg >/dev/null 2>&1 || die "Need dpkg to configure the GitHub CLI apt repository"
  local -a elevate=(env)
  if (( EUID != 0 )); then
    command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install gh"
    sudo -n true </dev/null || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
    elevate=(sudo -n env)
  fi

  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold wget ca-certificates </dev/null

  if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
    info "Adding GitHub CLI apt repository"
    "${elevate[@]}" mkdir -p -m 755 /etc/apt/keyrings
    "${elevate[@]}" mkdir -p -m 755 /etc/apt/sources.list.d

    local tmp_key
    tmp_key="$(mktemp)"
    wget -nv -O "$tmp_key" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat "$tmp_key" | "${elevate[@]}" tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    rm -f "$tmp_key"

    "${elevate[@]}" chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | "${elevate[@]}" tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  else
    ok "GitHub CLI apt repository already configured"
  fi

  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get update </dev/null
  "${elevate[@]}" DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get install -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold gh </dev/null

  command -v gh >/dev/null 2>&1 || die "gh install finished but it is not on PATH"
  ok "gh $(gh_version)"
}

main() {
  printf '%s\n' "${C_BOLD}Apt packages${C_RESET}"
  printf '%s\n\n' "${C_DIM}Terminal tools, Python venv support, libatomic1, cloudflared, and gh on Debian and Ubuntu${C_RESET}"

  if [[ "$(uname -s)" != Linux ]]; then
    ok "Not Linux ($(uname -s)); skipping apt packages"
    return
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    warn "apt-get not found; skipping apt packages"
    return
  fi

  install_terminal_tools
  echo
  install_python_venv
  echo
  install_libatomic
  echo
  install_cloudflared
  echo
  install_gh
  echo
  info "Done"
}

main "$@"
