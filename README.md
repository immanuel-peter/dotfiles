# Dotfiles

Configs to bootstrap a remote machine for coding agents.

On a fresh box, no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/install-node.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/mcp/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/skills/install.sh | bash
```

Or from a checkout:

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install-node.sh mcp/install.sh skills/install.sh
./install-node.sh      # nvm + Node LTS (skip if nvm/Node already installed)
./mcp/install.sh       # MCP server configs
./skills/install.sh    # agent skills (~/.agents/skills + Claude symlinks)
```

## Node — `install-node.sh`

Installs [nvm](https://github.com/nvm-sh/nvm) into `~/.nvm` if it is missing, then `nvm install --lts` and sets that as the default. Uses an existing nvm when already present.

## MCP - `mcp/`

### MCP Servers

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

### MCP Clients

- Claude Code
- Cursor
- OpenAI Codex
- OpenCode
- Grok Build
- Muse Code

## Skills — `skills/`

Installed into `~/.agents/skills` and symlinked into `~/.claude/skills`.

- bro
- frontend-design
- html-communication
- unslop
- wait-what
