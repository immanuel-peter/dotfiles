#!/usr/bin/env bash
# Install MCP server configs into Claude Code, Cursor, Codex, and OpenCode.
#
# - Claude Code: merge mcpServers from claude.mcp.json into ~/.claude.json (user scope)
# - Cursor:      copy cursor.mcp.json -> ~/.cursor/mcp.json
# - Codex:       merge [mcp_servers.*] from mcp.toml into ~/.codex/config.toml
# - OpenCode:    copy opencode.mcp.json -> ~/.config/opencode/opencode.jsonc
#
# Also reports which MCP-related env vars are missing on this machine.
# If agent-browser or xurl is missing and npm is available, installs that CLI globally.
#
# Works from a clone or via:
#   curl -fsSL \
#     -H "Authorization: Bearer $(gh auth token)" \
#     -H "Accept: application/vnd.github+json" \
#     https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/mcp/install.sh | bash
#
# Override the GitHub source with DOTFILES_REPO / DOTFILES_REF if needed.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-immanuel-peter/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/mcp"

# ---------------------------------------------------------------------------
# Env vars required by certain MCP servers (set these before opening a client)
# Format: VAR_NAME -> human-readable MCP server name
# ---------------------------------------------------------------------------
REQUIRED_ENV_VARS=(
  "HF_TOKEN:Hugging Face"
  "GITHUB_MCP_PAT:GitHub"
  "PERPLEXITY_API_KEY:Perplexity"
  "ALPHAXIV_API_KEY:alphaXiv"
  "CLIENT_ID:xurl"
  "CLIENT_SECRET:xurl"
)

SCRIPT_DIR=""
SOURCE_KIND=""
SRC_CLAUDE_JSON=""
SRC_CURSOR_JSON=""
SRC_MCP_TOML=""
SRC_OPENCODE=""

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

# Private repo. gh auth token is the bearer; do not print it.
github_token() {
  command -v gh >/dev/null 2>&1 || die "Need gh to download from GitHub"
  local token
  token="$(gh auth token)" || die "gh auth token failed. Run: gh auth login"
  [[ -n "$token" ]] || die "gh auth token returned nothing. Run: gh auth login"
  printf '%s' "$token"
}

download() {
  local url="$1"
  local dest="$2"
  local token
  token="$(github_token)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL \
      -H "Authorization: Bearer ${token}" \
      -H "Accept: application/vnd.github+json" \
      "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" \
      --header="Authorization: Bearer ${token}" \
      --header="Accept: application/vnd.github+json" \
      "$url"
  else
    die "Need curl or wget to fetch ${url}"
  fi
}

# Prefer configs next to this script (a clone). Otherwise fetch them from GitHub
# so `curl …/mcp/install.sh | bash` works on a machine with no checkout.
resolve_sources() {
  local src="${BASH_SOURCE[0]:-}"
  local dir=""
  if [[ -n "$src" && -f "$src" ]]; then
    dir="$(cd "$(dirname "$src")" && pwd)"
  fi

  if [[ -n "$dir" \
    && -f "$dir/claude.mcp.json" \
    && -f "$dir/cursor.mcp.json" \
    && -f "$dir/mcp.toml" \
    && -f "$dir/opencode.mcp.json" ]]; then
    SCRIPT_DIR="$dir"
    SOURCE_KIND="checkout"
  else
    SCRIPT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mcp-dotfiles.XXXXXX")"
    SOURCE_KIND="remote"
    info "No local checkout — fetching MCP configs from ${DOTFILES_REPO}@${DOTFILES_REF}"
    download "${RAW_BASE}/claude.mcp.json" "${SCRIPT_DIR}/claude.mcp.json"
    download "${RAW_BASE}/cursor.mcp.json" "${SCRIPT_DIR}/cursor.mcp.json"
    download "${RAW_BASE}/mcp.toml" "${SCRIPT_DIR}/mcp.toml"
    download "${RAW_BASE}/opencode.mcp.json" "${SCRIPT_DIR}/opencode.mcp.json"
    ok "Fetched 4 config file(s) into ${SCRIPT_DIR}"
  fi

  SRC_CLAUDE_JSON="${SCRIPT_DIR}/claude.mcp.json"
  SRC_CURSOR_JSON="${SCRIPT_DIR}/cursor.mcp.json"
  SRC_MCP_TOML="${SCRIPT_DIR}/mcp.toml"
  SRC_OPENCODE="${SCRIPT_DIR}/opencode.mcp.json"
}

# Use an existing nvm so npm/agent-browser resolve in this non-interactive bash
# script. Does not install nvm or a Node version.
load_nvm() {
  local candidates=(
    "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    "${HOME}/.nvm/nvm.sh"
    "/opt/homebrew/opt/nvm/nvm.sh"
    "/usr/local/opt/nvm/nvm.sh"
  )
  local nvm_sh
  for nvm_sh in "${candidates[@]}"; do
    if [[ -s "$nvm_sh" ]]; then
      export NVM_DIR
      NVM_DIR="$(cd "$(dirname "$nvm_sh")" && pwd)"
      set +u
      # shellcheck disable=SC1090
      . "$nvm_sh"
      set -u
      return 0
    fi
  done
}

# Linux needs shared libraries; --with-deps installs them (no-op / unused on macOS).
agent_browser_install_chrome() {
  if [[ "$(uname -s)" == Linux ]]; then
    info "Installing browser binaries + Linux system deps"
    agent-browser install --with-deps
  else
    info "Downloading Chrome for Testing (agent-browser install)"
    agent-browser install
  fi
}

# agent-browser is a global CLI (not npx/uvx). Install it if missing, then
# download Chrome for Testing. On Linux, also install system deps.
ensure_agent_browser() {
  info "Checking agent-browser CLI"
  load_nvm

  local fresh=0
  if command -v agent-browser >/dev/null 2>&1; then
    ok "agent-browser $(agent-browser --version 2>/dev/null | awk '{print $NF}')"
  else
    if ! command -v npm >/dev/null 2>&1; then
      warn "agent-browser not on PATH and npm is missing"
      warn "Install Node first: curl -fsSL -H \"Authorization: Bearer \$(gh auth token)\" -H \"Accept: application/vnd.github+json\" https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/install-node.sh | bash"
      return 0
    fi

    info "Installing agent-browser via npm -g"
    if npm install -g agent-browser; then
      ok "Installed $(command -v agent-browser)"
      fresh=1
    else
      warn "npm install -g agent-browser failed; Agent Browser MCP will not start"
      return 0
    fi
  fi

  # First install always; Linux also needs --with-deps even if the CLI was already present.
  if ((fresh)) || [[ "$(uname -s)" == Linux ]]; then
    if agent_browser_install_chrome; then
      ok "Browser binaries ready"
    else
      warn "agent-browser install failed; run it manually before using Agent Browser"
    fi
  fi
}

# Global xurl is for the skill. The MCP server is `npx -y @xdevplatform/xurl mcp`,
# which opens the OAuth2 browser login from CLIENT_ID and CLIENT_SECRET.
ensure_xurl() {
  info "Checking xurl CLI"
  load_nvm

  if command -v xurl >/dev/null 2>&1; then
    ok "xurl $(xurl version 2>/dev/null | awk '{print $NF}')"
  else
    if ! command -v npm >/dev/null 2>&1; then
      warn "xurl not on PATH and npm is missing"
      warn "Install Node first: curl -fsSL -H \"Authorization: Bearer \$(gh auth token)\" -H \"Accept: application/vnd.github+json\" https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/install-node.sh | bash"
      return 0
    fi

    info "Installing @xdevplatform/xurl via npm -g"
    if npm install -g @xdevplatform/xurl; then
      ok "Installed $(command -v xurl)"
    else
      warn "npm install -g @xdevplatform/xurl failed; xurl skill commands will not run"
      return 0
    fi
  fi

  if [[ -f "${HOME}/.xurl/auth.yml" || -f "${HOME}/.xurl" ]]; then
    ok "xurl credential store present (~/.xurl)"
  elif [[ -n "${CLIENT_ID:-}" && -n "${CLIENT_SECRET:-}" ]]; then
    ok "set: CLIENT_ID, CLIENT_SECRET (xurl first-run login)"
  else
    warn "xurl has no ~/.xurl credential store and CLIENT_ID/CLIENT_SECRET are unset"
    printf '%s\n' "${C_DIM}Register the app yourself, then authenticate outside an agent session:${C_RESET}"
    printf '  export CLIENT_ID="…"\n'
    printf '  export CLIENT_SECRET="…"\n'
    printf '  xurl auth oauth2\n'
  fi
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
  resolve_sources
  if [[ "$SOURCE_KIND" == remote ]]; then
    printf '%s\n\n' "${C_DIM}source: ${DOTFILES_REPO}@${DOTFILES_REF}${C_RESET}"
  else
    printf '%s\n\n' "${C_DIM}source: ${SCRIPT_DIR}${C_RESET}"
  fi

  [[ -f "$SRC_CLAUDE_JSON" ]] || die "Missing ${SRC_CLAUDE_JSON}"
  [[ -f "$SRC_CURSOR_JSON" ]] || die "Missing ${SRC_CURSOR_JSON}"
  [[ -f "$SRC_MCP_TOML" ]] || die "Missing ${SRC_MCP_TOML}"
  [[ -f "$SRC_OPENCODE" ]] || die "Missing ${SRC_OPENCODE}"

  check_env_vars
  echo
  ensure_agent_browser
  echo
  ensure_xurl
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
