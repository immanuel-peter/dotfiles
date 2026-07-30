#!/usr/bin/env bash
# Install MCP server configs into Claude Code, Cursor, Codex, and OpenCode.
#
# - Claude Code: merge mcpServers from claude.mcp.json into ~/.claude.json (user scope)
# - Cursor:      copy cursor.mcp.json -> ~/.cursor/mcp.json
# - Codex:       merge [mcp_servers.*] from mcp.toml into ~/.codex/config.toml
# - OpenCode:    copy opencode.mcp.json -> ~/.config/opencode/opencode.jsonc
#
# Also reports which MCP-related env vars are missing on this machine.
set -euo pipefail

# ---------------------------------------------------------------------------
# Env vars required by certain MCP servers (set these before opening a client)
# Format: VAR_NAME -> human-readable MCP server name
# ---------------------------------------------------------------------------
REQUIRED_ENV_VARS=(
  "HF_TOKEN:Hugging Face"
  "GITHUB_MCP_PAT:GitHub"
  "PERPLEXITY_API_KEY:Perplexity"
  "ALPHAXIV_API_KEY:alphaXiv"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_CLAUDE_JSON="${SCRIPT_DIR}/claude.mcp.json"
SRC_CURSOR_JSON="${SCRIPT_DIR}/cursor.mcp.json"
SRC_MCP_TOML="${SCRIPT_DIR}/mcp.toml"
SRC_OPENCODE="${SCRIPT_DIR}/opencode.mcp.json"

CLAUDE_JSON="${HOME}/.claude.json"
CURSOR_MCP="${HOME}/.cursor/mcp.json"
CODEX_CONFIG="${HOME}/.codex/config.toml"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.jsonc"

# Colors (disabled when not a TTY)
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

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

backup_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    local bak="${path}.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$path" "$bak"
    ok "Backed up $(basename "$path") -> ${bak/#$HOME/~}"
  fi
}

ensure_parent_dir() {
  mkdir -p "$(dirname "$1")"
}

# ---------------------------------------------------------------------------
# Env var check
# ---------------------------------------------------------------------------
check_env_vars() {
  info "Checking MCP-related environment variables"
  local missing=()
  local present=()
  local entry var server

  for entry in "${REQUIRED_ENV_VARS[@]}"; do
    var="${entry%%:*}"
    server="${entry#*:}"
    if [[ -n "${!var:-}" ]]; then
      present+=("$var ($server)")
    else
      missing+=("$var ($server)")
    fi
  done

  if ((${#present[@]} > 0)); then
    for item in "${present[@]}"; do
      ok "set: $item"
    done
  fi

  if ((${#missing[@]} > 0)); then
    echo
    warn "Missing env vars (set these before opening a coding client):"
    for item in "${missing[@]}"; do
      err "missing: $item"
    done
    echo
    printf '%s\n' "${C_DIM}Add them to your shell profile, e.g.:${C_RESET}"
    for entry in "${REQUIRED_ENV_VARS[@]}"; do
      var="${entry%%:*}"
      if [[ -z "${!var:-}" ]]; then
        printf '  export %s="…"\n' "$var"
      fi
    done
    echo
    printf '%s\n' "${C_DIM}Servers that need these keys will fail to authenticate until they are set.${C_RESET}"
  else
    ok "All required MCP env vars are set"
  fi

  # Export count for optional non-zero exit later if desired
  MISSING_ENV_COUNT=${#missing[@]}
}

# ---------------------------------------------------------------------------
# Claude Code: merge mcpServers into top-level ~/.claude.json (user scope)
# https://code.claude.com/docs/en/mcp-quickstart#find-your-configuration-on-disk
# ---------------------------------------------------------------------------
install_claude() {
  info "Claude Code: merging mcpServers into ${CLAUDE_JSON/#$HOME/~}"
  require_cmd jq

  if [[ ! -f "$SRC_CLAUDE_JSON" ]]; then
    die "Source not found: $SRC_CLAUDE_JSON"
  fi

  if [[ ! -f "$CLAUDE_JSON" ]]; then
    warn "No existing ~/.claude.json — creating with mcpServers only"
    printf '%s\n' '{"mcpServers":{}}' >"$CLAUDE_JSON"
  fi

  # Validate JSON first so we never clobber a bad parse with empty output
  jq -e '.mcpServers | type == "object"' "$SRC_CLAUDE_JSON" >/dev/null \
    || die "claude.mcp.json must contain an object mcpServers"
  jq -e . "$CLAUDE_JSON" >/dev/null \
    || die "Existing ~/.claude.json is not valid JSON"

  backup_file "$CLAUDE_JSON"

  local tmp
  tmp="$(mktemp)"
  # Right-hand keys win for shared server names; other top-level keys preserved.
  jq -s '
    .[0] as $src | .[1] as $dest |
    $dest + {
      mcpServers: (($dest.mcpServers // {}) + ($src.mcpServers // {}))
    }
  ' "$SRC_CLAUDE_JSON" "$CLAUDE_JSON" >"$tmp"

  mv "$tmp" "$CLAUDE_JSON"
  chmod 600 "$CLAUDE_JSON" 2>/dev/null || true

  local count
  count="$(jq -r '.mcpServers | keys | length' "$SRC_CLAUDE_JSON")"
  ok "Merged ${count} server(s) into user-scope mcpServers"
}

# ---------------------------------------------------------------------------
# Cursor: copy cursor.mcp.json -> ~/.cursor/mcp.json
# ---------------------------------------------------------------------------
install_cursor() {
  info "Cursor: copying cursor.mcp.json -> ${CURSOR_MCP/#$HOME/~}"

  [[ -f "$SRC_CURSOR_JSON" ]] || die "Source not found: $SRC_CURSOR_JSON"

  ensure_parent_dir "$CURSOR_MCP"
  backup_file "$CURSOR_MCP"
  cp "$SRC_CURSOR_JSON" "$CURSOR_MCP"
  chmod 600 "$CURSOR_MCP" 2>/dev/null || true
  ok "Wrote ${CURSOR_MCP/#$HOME/~}"
}

# ---------------------------------------------------------------------------
# Codex: merge [mcp_servers.*] from mcp.toml into ~/.codex/config.toml
# https://developers.openai.com / learn.chatgpt.com Codex config reference
# ---------------------------------------------------------------------------
install_codex() {
  info "Codex: merging mcp_servers into ${CODEX_CONFIG/#$HOME/~}"
  require_cmd python3

  [[ -f "$SRC_MCP_TOML" ]] || die "Source not found: $SRC_MCP_TOML"

  ensure_parent_dir "$CODEX_CONFIG"
  if [[ ! -f "$CODEX_CONFIG" ]]; then
    warn "No existing ~/.codex/config.toml — creating new file"
    : >"$CODEX_CONFIG"
  fi

  backup_file "$CODEX_CONFIG"

  python3 - "$SRC_MCP_TOML" "$CODEX_CONFIG" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

src_path = Path(sys.argv[1])
dest_path = Path(sys.argv[2])

src_text = src_path.read_text(encoding="utf-8")
dest_text = dest_path.read_text(encoding="utf-8")

# Top-level server ids declared in source: [mcp_servers.<id>] (no extra dots)
server_ids = sorted(
    set(re.findall(r"(?m)^\[mcp_servers\.([^.\]]+)\]\s*$", src_text))
)
if not server_ids:
    print("error: no [mcp_servers.<id>] tables found in mcp.toml", file=sys.stderr)
    sys.exit(1)

# Drop any dest tables for those servers, including nested tables like
# [mcp_servers.<id>.tools.<tool>] so a reinstall fully replaces that server.
id_alt = "|".join(re.escape(s) for s in server_ids)
section_re = re.compile(
    rf"(?ms)^\[mcp_servers\.(?:{id_alt})(?:\.[^\]]+)?\][^\n]*(?:\n(?!\[)[^\n]*)*"
)

cleaned = section_re.sub("", dest_text)
# Collapse excessive blank lines introduced by removals
cleaned = re.sub(r"\n{3,}", "\n\n", cleaned).rstrip() + "\n"

src_body = src_text.strip()
if cleaned.strip():
    merged = cleaned.rstrip() + "\n\n" + src_body + "\n"
else:
    merged = src_body + "\n"

dest_path.write_text(merged, encoding="utf-8")
print(f"merged {len(server_ids)} mcp_servers table(s): {', '.join(server_ids)}")
PY

  chmod 600 "$CODEX_CONFIG" 2>/dev/null || true
  ok "Merged mcp_servers from mcp.toml"
}

# ---------------------------------------------------------------------------
# OpenCode: copy opencode.mcp.json -> ~/.config/opencode/opencode.jsonc
# ---------------------------------------------------------------------------
install_opencode() {
  info "OpenCode: copying opencode.mcp.json -> ${OPENCODE_CONFIG/#$HOME/~}"

  [[ -f "$SRC_OPENCODE" ]] || die "Source not found: $SRC_OPENCODE"

  ensure_parent_dir "$OPENCODE_CONFIG"
  backup_file "$OPENCODE_CONFIG"
  cp "$SRC_OPENCODE" "$OPENCODE_CONFIG"
  ok "Wrote ${OPENCODE_CONFIG/#$HOME/~}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  printf '%s\n' "${C_BOLD}MCP dotfiles installer${C_RESET}"
  printf '%s\n\n' "${C_DIM}source: ${SCRIPT_DIR}${C_RESET}"

  [[ -f "$SRC_CLAUDE_JSON" ]] || die "Missing ${SRC_CLAUDE_JSON}"
  [[ -f "$SRC_CURSOR_JSON" ]] || die "Missing ${SRC_CURSOR_JSON}"
  [[ -f "$SRC_MCP_TOML" ]] || die "Missing ${SRC_MCP_TOML}"
  [[ -f "$SRC_OPENCODE" ]] || die "Missing ${SRC_OPENCODE}"

  check_env_vars
  echo

  install_claude
  echo
  install_cursor
  echo
  install_codex
  echo
  install_opencode
  echo

  info "Done"
  ok "Claude Code  ${CLAUDE_JSON/#$HOME/~}  (merged mcpServers)"
  ok "Cursor       ${CURSOR_MCP/#$HOME/~}  (copied)"
  ok "Codex        ${CODEX_CONFIG/#$HOME/~}  (merged mcp_servers)"
  ok "OpenCode     ${OPENCODE_CONFIG/#$HOME/~}  (copied)"

  if ((MISSING_ENV_COUNT > 0)); then
    echo
    warn "Install finished, but ${MISSING_ENV_COUNT} required env var(s) are missing."
    warn "Set them, then restart your coding client(s)."
    exit 0
  fi
}

main "$@"
