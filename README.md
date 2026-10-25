# Dotfiles

Configs to bootstrap a remote machine for coding agents.

On a fresh box, no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/setup.sh | bash
```

That sets git `user.name` and `user.email` when those global keys are unset, then installs Linux apt packages, HF CLI, rclone, nvm + Node LTS, the agent CLIs, MCP configs, and agent skills. To run one piece:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-apt.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-hf.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-rclone.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/deps/install-node.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/agents/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/mcp/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/skills/install.sh | bash
```

Or from a checkout:

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Apt — `deps/install-apt.sh`

Installs [cloudflared](https://developers.cloudflare.com/tunnel/downloads/) from Cloudflare's apt repository and the [gh](https://cli.github.com/) from GitHub's apt repository on Debian and Ubuntu. Other systems skip this step. An existing `cloudflared` on `PATH` is left as it is. `gh` is installed or upgraded.

Also installs `python3-venv`, which pulls in venv support for the distro's default Python, including `python3.10-venv` on Ubuntu 22.04 and `python3.12-venv` on Ubuntu 24.04.

Also installs `libatomic1` when it is missing. The T3 Code CLI needs `libatomic.so.1` from that package.

## Hugging Face CLI — `deps/install-hf.sh`

Installs [HF CLI](https://huggingface.co/docs/huggingface_hub/en/guides/cli) with the official installer as the current user. Setup runs this after apt dependencies. A working `hf` on `PATH` or in `~/.local/bin` is left as it is. The vendor installer supports macOS and Linux, requires Python 3.10+, and manages the shell's PATH entry for `~/.local/bin`.

For a standalone install on Debian/Ubuntu, run `deps/install-apt.sh` first. The HF installer checks that its selected Python can create a venv, including pip. A custom Python earlier on `PATH` needs its own venv/ensurepip support. Sign in separately with `hf auth login`.

## rclone — `deps/install-rclone.sh`

Installs or updates [rclone](https://rclone.org/) using the [official installer](https://rclone.org/install.sh). Runs as root or uses `sudo -n`, and fails without prompting if passwordless or cached sudo is unavailable. The installer requires `curl` and one of `unzip`, `7z`, or `busybox` on the privileged command's PATH. BSD systems also need `makewhatis`. An already current rclone counts as success.

After installation, creates `~/.config/rclone` and touches `~/.config/rclone/rclone.conf` as the invoking user, preserving existing config contents. Configure remotes separately with `rclone config`.

## Node — `deps/install-node.sh`

Installs [nvm](https://github.com/nvm-sh/nvm) into `~/.nvm` if it is missing, then `nvm install --lts` and sets that as the default. Uses an existing nvm when already present.

## Agents — `agents/`

Installs agent CLIs. Sign-in stays outside the scripts.

- Claude Code
- Codex
- OpenCode
- Grok Build
- Muse Code
- T3 Code (nightly)

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
- gh
- html-communication
- unslop
- wait-what
- xurl
