#!/usr/bin/env bash
# Install the Hugging Face CLI as the current user.
#
#   ./deps/install-hf.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-hf.sh | bash
#
# On Debian/Ubuntu, run deps/install-apt.sh first for python3-venv.
# Sign-in is separate: hf auth login.
set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if command -v hf >/dev/null 2>&1 && hf --help >/dev/null 2>&1; then
  printf 'Hugging Face CLI already installed: %s\n' "$(command -v hf)"
  exit 0
fi

hf_bin="${HF_CLI_BIN_DIR:-${HOME}/.local/bin}/hf"
if [[ -x "$hf_bin" ]] && "$hf_bin" --help >/dev/null 2>&1; then
  printf 'Hugging Face CLI already installed: %s\n' "$hf_bin"
  exit 0
fi

command -v curl >/dev/null 2>&1 || die "Missing required command: curl"

# Match the vendor installer's Python selection, including its minimum version.
python_cmd=""
for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1 \
    && "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'; then
    python_cmd="$candidate"
    break
  fi
done
[[ -n "$python_cmd" ]] || die "HF CLI requires Python 3.10 or newer on PATH"

# Creating a venv also checks ensurepip, which may be missing on Debian/Ubuntu.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hf.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
if ! "$python_cmd" -m venv "$tmp/venv" >"$tmp/venv.log" 2>&1; then
  cat "$tmp/venv.log" >&2
  die "Cannot create a venv with $python_cmd. On Debian/Ubuntu, run deps/install-apt.sh. A custom Python needs its own venv/ensurepip support."
fi

printf '==> Installing Hugging Face CLI\n'
curl -LsSf https://hf.co/cli/install.sh | bash
"$hf_bin" --help >/dev/null || die "HF CLI install finished but hf --help failed"
printf 'Hugging Face CLI installed: %s\n' "$hf_bin"
