# Dotfiles

Configs to bootstrap a remote machine for coding agents.

On a fresh box, no clone needed. The repo is private, so each curl sends `gh auth token` as a bearer token (`gh auth login` first):

```bash
curl -fsSL \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/setup.sh | bash
```

That installs nvm + Node LTS, MCP configs, and agent skills. To run one piece:

```bash
curl -fsSL \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/install-node.sh | bash
curl -fsSL \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/mcp/install.sh | bash
curl -fsSL \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Accept: application/vnd.github+json" \
  https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/skills/install.sh | bash
```

Or from a checkout:

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
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
- xurl

### MCP Clients

- Claude Code
- Cursor
- OpenAI Codex
- OpenCode
- Grok Build
- Muse Code

## Skills — `skills/`

Installed into `~/.agents/skills` and symlinked into `~/.claude/skills`.

- asset-upload
- bro
- frontend-design
- html-communication
- unslop
- wait-what
- xurl
