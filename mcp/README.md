# MCP Configs

Shared MCP server configs for coding agents.

## Supported Clients

- [Claude Code](./claude.mcp.json) — merged into `~/.claude.json` (`mcpServers`, user scope)
- [Cursor](./cursor.mcp.json) — copied to `~/.cursor/mcp.json`
- [OpenAI Codex](./mcp.toml) — merged into `~/.codex/config.toml` (`[mcp_servers.*]`)
- [OpenCode](./opencode.mcp.json) — copied to `~/.config/opencode/opencode.jsonc`

> **Grok Build** and **Muse Code** are compatible with Claude Code and Codex MCPs, so there is no need to make a separate config!

## MCP Servers

- Hugging Face
- Shadcn
- Chrome Devtools
- GitHub
- Perplexity
- DeepWiki
- Markitdown
- OpenAI Docs
- Claude Code Docs
- Brev Docs
- xAI Docs
- alphaXiv
- Remotion
- Playwright
- Agent Browser
- OpenRouter

## Environment variables

| Variable | MCP |
| --- | --- |
| `HF_TOKEN` | Hugging Face |
| `GITHUB_MCP_PAT` | GitHub |
| `PERPLEXITY_API_KEY` | Perplexity |
| `ALPHAXIV_API_KEY` | alphaXiv |

## Installation

No clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/install-node.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/mcp/install.sh | bash
```

Or from a checkout:

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install-node.sh mcp/install.sh
./install-node.sh    # nvm + Node LTS, if needed
cd mcp && ./install.sh
```

What the installer does:

1. Checks the env vars above and reports any that are unset
2. Installs the `agent-browser` CLI via `npm install -g` if it is missing, then `agent-browser install` (`--with-deps` on Linux). Does **not** install nvm or Node — run [`../install-node.sh`](../install-node.sh) (or the curl one-liner above) first if the machine has neither.
3. **Claude Code** — merges `mcpServers` from `claude.mcp.json` into the top-level key of `~/.claude.json`
4. **Cursor** — copies `cursor.mcp.json` → `~/.cursor/mcp.json`
5. **Codex** — merges `[mcp_servers.*]` tables from `mcp.toml` into `~/.codex/config.toml`
6. **OpenCode** — copies `opencode.mcp.json` → `~/.config/opencode/opencode.jsonc`

Existing target files are backed up as `*.bak.<timestamp>` before writing.
