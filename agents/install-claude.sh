#!/usr/bin/env bash
# Install Claude Code.
# https://code.claude.com/docs/en/quickstart
#
#   ./agents/install-claude.sh
#
# Sign-in is separate: run `claude`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}

curl -fsSL https://claude.ai/install.sh | bash
