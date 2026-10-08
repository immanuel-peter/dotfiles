#!/usr/bin/env bash
# Install Grok Build.
# https://x.ai/docs/build/overview
#
#   ./agents/install-grok.sh
#
# Sign-in is separate: run `grok`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}

curl -fsSL https://x.ai/cli/install.sh | bash
