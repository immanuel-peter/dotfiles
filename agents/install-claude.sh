#!/usr/bin/env bash
# Install Claude Code and configure user settings.
# https://code.claude.com/docs/en/quickstart
# https://code.claude.com/docs/en/settings-reference
#
#   ./agents/install-claude.sh
#
# Sign-in is separate: run `claude`.
set -euo pipefail

command -v curl >/dev/null 2>&1 || {
  printf 'Missing required command: curl\n' >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  printf 'Missing required command: jq\n' >&2
  exit 1
}

curl -fsSL https://claude.ai/install.sh | bash

settings_dir="${HOME}/.claude"
settings_file="${settings_dir}/settings.json"
mkdir -p "$settings_dir"
settings_tmp="$(mktemp "${settings_dir}/settings.json.XXXXXX")"
trap 'rm -f "$settings_tmp"' EXIT

if [[ -e "$settings_file" ]]; then
  cat "$settings_file"
else
  printf '{}\n'
fi | jq -s '
  if length != 1 or (.[0] | type) != "object" then
    error("Claude settings must contain a single JSON object")
  else .[0] end
  | .permissions = ((.permissions // {}) + {defaultMode: "auto"})
  | . + {
      outputStyle: "Concise",
      autoMemoryEnabled: false,
      inputNeededNotifEnabled: true,
      skipAutoPermissionPrompt: true,
      attribution: false
    }
' >"$settings_tmp"

mv "$settings_tmp" "$settings_file"
printf 'Configured Claude Code settings in %s\n' "$settings_file"
