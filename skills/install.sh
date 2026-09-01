#!/usr/bin/env bash
# Install agent skills into ~/.agents/skills and symlink them into ~/.claude/skills.
#
# Works from a clone or via:
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/skills/install.sh | bash
#
# Override the GitHub source with DOTFILES_REPO / DOTFILES_REF if needed.
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-immanuel-peter/dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/${DOTFILES_REPO}/${DOTFILES_REF}/skills"
ARCHIVE_URL="https://github.com/${DOTFILES_REPO}/archive/${DOTFILES_REF}.tar.gz"

SKILLS=(
  frontend-design
  html-communication
  unslop
)

AGENTS_SKILLS="${HOME}/.agents/skills"
CLAUDE_SKILLS="${HOME}/.claude/skills"

SCRIPT_DIR=""
SOURCE_KIND=""

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

download() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    die "Need curl or wget to fetch ${url}"
  fi
}

# Prefer skills next to this script (a clone). Otherwise fetch the skills/
# tree from GitHub so `curl …/skills/install.sh | bash` works with no checkout.
resolve_sources() {
  local src="${BASH_SOURCE[0]:-}"
  local dir=""
  if [[ -n "$src" && -f "$src" ]]; then
    dir="$(cd "$(dirname "$src")" && pwd)"
  fi

  local skill
  if [[ -n "$dir" ]]; then
    local all_present=1
    for skill in "${SKILLS[@]}"; do
      if [[ ! -f "$dir/$skill/SKILL.md" ]]; then
        all_present=0
        break
      fi
    done
    if ((all_present)); then
      SCRIPT_DIR="$dir"
      SOURCE_KIND="checkout"
      return
    fi
  fi

  SOURCE_KIND="remote"
  info "No local checkout — fetching skills from ${DOTFILES_REPO}@${DOTFILES_REF}"

  local tmp archive extracted
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/skills-dotfiles.XXXXXX")"
  archive="${tmp}/src.tar.gz"

  if download "$ARCHIVE_URL" "$archive" && tar -tzf "$archive" >/dev/null 2>&1; then
    tar -xzf "$archive" -C "$tmp"
    extracted="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
    [[ -n "$extracted" && -d "${extracted}/skills" ]] \
      || die "Archive from ${ARCHIVE_URL} has no skills/ directory"
    SCRIPT_DIR="${extracted}/skills"
    ok "Fetched skills tree into ${SCRIPT_DIR}"
    return
  fi

  warn "Tarball fetch failed — falling back to raw SKILL.md files"
  SCRIPT_DIR="$tmp"
  for skill in "${SKILLS[@]}"; do
    download "${RAW_BASE}/${skill}/SKILL.md" "${SCRIPT_DIR}/${skill}/SKILL.md"
  done
  ok "Fetched ${#SKILLS[@]} skill file(s) into ${SCRIPT_DIR}"
}

install_skill() {
  local skill="$1"
  local src="${SCRIPT_DIR}/${skill}"
  local dest="${AGENTS_SKILLS}/${skill}"
  local link="${CLAUDE_SKILLS}/${skill}"
  local rel_target="../../.agents/skills/${skill}"

  [[ -d "$src" ]] || die "Source not found: $src"
  [[ -f "$src/SKILL.md" ]] || die "Missing SKILL.md in $src"

  mkdir -p "$dest"
  # Copy contents, not the directory itself, so dest stays a real folder
  # even if src is later removed (curl-install case).
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    find "$dest" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -R "$src/." "$dest/"
  fi
  ok "Installed ${skill} -> ${dest/#$HOME/~}"

  mkdir -p "$CLAUDE_SKILLS"
  if [[ -e "$link" || -L "$link" ]]; then
    if [[ -L "$link" ]]; then
      local current
      current="$(readlink "$link")"
      if [[ "$current" == "$rel_target" || "$current" == "$dest" ]]; then
        ok "Claude symlink already points at ${dest/#$HOME/~}"
        return
      fi
    fi
    rm -rf "$link"
  fi
  ln -s "$rel_target" "$link"
  ok "Symlinked ${link/#$HOME/~} -> ${rel_target}"
}

check_postplan_token() {
  info "Checking skill-related environment variables"
  if [[ -n "${POSTPLAN_TOKEN:-}" ]]; then
    ok "set: POSTPLAN_TOKEN (html-communication)"
  else
    warn "missing: POSTPLAN_TOKEN (html-communication)"
    printf '%s\n' "${C_DIM}html-communication will refuse to publish until this is set, e.g.:${C_RESET}"
    printf '  export POSTPLAN_TOKEN="…"\n'
  fi
}

main() {
  printf '%s\n' "${C_BOLD}Skills installer${C_RESET}"
  resolve_sources
  if [[ "$SOURCE_KIND" == remote ]]; then
    printf '%s\n\n' "${C_DIM}source: ${DOTFILES_REPO}@${DOTFILES_REF}${C_RESET}"
  else
    printf '%s\n\n' "${C_DIM}source: ${SCRIPT_DIR}${C_RESET}"
  fi

  mkdir -p "$AGENTS_SKILLS" "$CLAUDE_SKILLS"

  check_postplan_token
  echo

  local skill
  for skill in "${SKILLS[@]}"; do
    info "Installing ${skill}"
    install_skill "$skill"
    echo
  done

  info "Done"
  ok "Canonical  ${AGENTS_SKILLS/#$HOME/~}"
  ok "Claude     ${CLAUDE_SKILLS/#$HOME/~}  (symlinks)"
}

main "$@"
