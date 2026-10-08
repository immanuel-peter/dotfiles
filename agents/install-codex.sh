#!/usr/bin/env bash
# Install the Codex CLI.
# https://developers.openai.com/codex/cli
#
#   ./agents/install-codex.sh
#
# The vendor script is POSIX sh. Sign-in is separate: run `codex`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}

curl -fsSL https://chatgpt.com/codex/install.sh | sh
