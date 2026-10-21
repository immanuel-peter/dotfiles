#!/usr/bin/env bash
# Install or update rclone with the official installer, without prompting.
#
#   ./deps/install-rclone.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-rclone.sh | bash
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "Missing required command: curl"

user_id="$(id -u)"
if [[ "$user_id" != 0 ]]; then
  command -v sudo >/dev/null 2>&1 || die "Need root or sudo to install rclone"
  sudo -n true </dev/null || die "Need passwordless or cached sudo. Run sudo -v separately, then retry."
fi

run_privileged() {
  if [[ "$user_id" == 0 ]]; then
    "$@"
  else
    sudo -n "$@"
  fi
}

# Check the PATH used by the installer, including sudo's secure_path.
# shellcheck disable=SC2016
run_privileged bash -c '
  for cmd in curl mktemp uname head cp chmod chown mv mkdir rm; do
    command -v "$cmd" >/dev/null 2>&1 || {
      printf "Missing required command: %s\n" "$cmd" >&2
      exit 1
    }
  done
  if ! command -v unzip >/dev/null 2>&1 \
    && ! command -v 7z >/dev/null 2>&1 \
    && ! command -v busybox >/dev/null 2>&1; then
    printf "rclone requires unzip, 7z, or busybox to extract its download.\n" >&2
    exit 1
  fi
  case "$(uname -s)" in
    FreeBSD|OpenBSD|NetBSD)
      command -v makewhatis >/dev/null 2>&1 || {
        printf "Missing required command: makewhatis\n" >&2
        exit 1
      }
      ;;
  esac
' </dev/null || die "Cannot run the rclone installer. Check the dependencies and root/sudo access above."

tmp="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-rclone.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL https://rclone.org/install.sh -o "$tmp/install.sh"

printf '==> Installing rclone\n'
status=0
run_privileged bash "$tmp/install.sh" </dev/null || status=$?
case "$status" in
  0) printf 'rclone installed.\n' ;;
  3) printf 'rclone is already up to date.\n' ;;
  *) die "Official rclone installer failed with status $status" ;;
esac

# Keep this outside sudo so the invoking user owns newly created config files.
mkdir -p "$HOME/.config/rclone"
touch "$HOME/.config/rclone/rclone.conf"
printf 'rclone config ready: %s/.config/rclone/rclone.conf\n' "$HOME"
