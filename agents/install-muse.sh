#!/usr/bin/env bash
# Install Muse Code.
# https://dev.meta.ai/docs/muse-code
#
#   ./agents/install-muse.sh
#
# The vendor script is bash. Sign-in is separate: run `muse`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}

curl -fsSL https://dev.meta.ai/install.sh | bash
