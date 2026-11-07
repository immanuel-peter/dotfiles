#!/usr/bin/env bash
# Install T3 Code (nightly).
# https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md
#
#   ./agents/install-t3.sh
#
# The vendor script is POSIX sh. T3CODE_CHANNEL must be set on that shell.
# On Debian and Ubuntu the CLI needs libatomic.so.1 from the libatomic1 package.
# Sign-in stays with each provider CLI. Start the app with `t3`.
# Linked environments stays off until settings.json says otherwise. This script
# turns that on once, including when the file already holds other settings.
set -euo pipefail

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "Missing required command: curl"

libatomic_present() {
  local libs="" status=""
  if command -v ldconfig >/dev/null 2>&1; then
    libs="$(ldconfig -p 2>/dev/null || true)"
    if grep -q 'libatomic\.so\.1' <<< "$libs"; then
      return 0
    fi
  fi
  if command -v dpkg-query >/dev/null 2>&1; then
    status="$(dpkg-query -W -f='${Status}' libatomic1 2>/dev/null || true)"
    if [[ "$status" == "install ok installed" ]]; then
      return 0
    fi
  fi
  return 1
}

# The vendor installer runs the downloaded binary. Without libatomic.so.1 that
# check fails after the download. deps/install-apt.sh installs the same package.
ensure_libatomic() {
  [[ "$(uname -s)" == Linux ]] || return 0
  libatomic_present && return 0
  if ! command -v apt-get >/dev/null 2>&1; then
    printf 'libatomic.so.1 not found and apt-get is missing; the T3 Code CLI may fail to start\n' >&2
    return 0
  fi

  printf '==> Installing libatomic1\n'
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
  libatomic_present || die "libatomic1 install finished but libatomic.so.1 is still missing"
}

# Merge the flag into userdata/settings.json. A running server reloads that file.
enable_linked_environments() {
  command -v jq >/dev/null 2>&1 || die "Missing required command: jq"
  local root path tmp mode
  if [[ -n "${T3CODE_HOME:-}" ]]; then
    root="${T3CODE_HOME/#\~/$HOME}"
  else
    root="${HOME}/.t3"
  fi
  path="${root}/userdata/settings.json"
  mkdir -p "${root}/userdata"

  if [[ -s "$path" ]]; then
    jq -e 'type == "object"' "$path" >/dev/null || die "${path} is not a JSON object"
    mode="$(stat -c '%a' "$path" 2>/dev/null || stat -f '%OLp' "$path")"
  else
    mode="600"
  fi

  tmp="$(mktemp "${root}/userdata/.settings.XXXXXX")"
  if [[ -s "$path" ]]; then
    jq '.linkedEnvironmentsEnabled = true' "$path" >"$tmp" || { rm -f "$tmp"; die "Could not update ${path}"; }
  else
    jq -n '.linkedEnvironmentsEnabled = true' >"$tmp" || { rm -f "$tmp"; die "Could not update ${path}"; }
  fi
  chmod "$mode" "$tmp"
  mv "$tmp" "$path"
  printf '==> Linked environments enabled in %s\n' "$path"
}

ensure_libatomic
curl -fsSL https://t3.codes/install.sh | T3CODE_CHANNEL=nightly sh
enable_linked_environments
