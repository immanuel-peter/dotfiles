# MCP Configs

Shared MCP server configs for coding agents.

## Supported Clients

- [Claude Code](./claude.mcp.json) — merged into `~/.claude.json` (`mcpServers`, user scope)
- [Cursor](./cursor.mcp.json) — copied to `~/.cursor/mcp.json`
- [OpenAI Codex](./mcp.toml) — merged into `~/.codex/config.toml` (`[mcp_servers.*]`)
- [OpenCode](./opencode.mcp.json) — copied to `~/.config/opencode/opencode.jsonc`

> **Grok Build** is compatible with Claude Code and Codex MCPs, so there is no need to make a separate config!

## MCP Servers

- Hugging Face
- Shadcn
- Chrome Devtools
- GitHub
- Perplexity
- DeepWiki
- Markitdown
- OpenAI Docs
- xAI Docs
- alphaXiv
- Remotion
- Playwright

## Environment variables

| Variable | MCP |
| --- | --- |
| `HF_TOKEN` | Hugging Face |
| `GITHUB_MCP_PAT` | GitHub |
| `PERPLEXITY_API_KEY` | Perplexity |
| `ALPHAXIV_API_KEY` | alphaXiv |

## Installation

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles/mcp
chmod +x install.sh
./install.sh
```

What the installer does:

1. Checks the env vars above and reports any that are unset
2. **Claude Code** — merges `mcpServers` from `claude.mcp.json` into the top-level key of `~/.claude.json`
3. **Cursor** — copies `cursor.mcp.json` → `~/.cursor/mcp.json`
4. **Codex** — merges `[mcp_servers.*]` tables from `mcp.toml` into `~/.codex/config.toml`
5. **OpenCode** — copies `opencode.mcp.json` → `~/.config/opencode/opencode.jsonc`

Existing target files are backed up as `*.bak.<timestamp>` before writing.
