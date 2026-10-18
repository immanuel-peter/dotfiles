# Agents

CLI installers for the coding agents. Each script runs that vendor's installer. Sign-in stays outside these scripts.

## Scripts

| Agent | Script | CLI |
| --- | --- | --- |
| Claude Code | `install-claude.sh` | `claude` |
| Codex | `install-codex.sh` | `codex` |
| OpenCode | `install-opencode.sh` | `opencode` |
| Grok Build | `install-grok.sh` | `grok` |
| Muse Code | `install-muse.sh` | `muse` |

`install.sh` runs all five, in that order, and stops on the first failure.

## Installation

Without a checkout:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/agents/install.sh | bash
```

This downloads all five installer scripts to a temporary directory and removes it on exit. Set `DOTFILES_REPO` and `DOTFILES_REF` on the receiving `bash` to use a different source.

From a checkout:

```bash
./agents/install.sh
./agents/install-claude.sh
```
