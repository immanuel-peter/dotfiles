#!/usr/bin/env bash
# Install OpenCode v2.
# https://opencode.ai/v2/docs/
#
#   ./agents/install-opencode.sh
#
# v1 is still https://opencode.ai/install. Sign-in is separate: run `opencode`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}

curl -fsSL https://opencode.ai/v2/install | bash
