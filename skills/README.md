# Skills

Shared agent skills. Installed into `~/.agents/skills` (the copy other clients read) and symlinked into `~/.claude/skills` for Claude Code.

## Skills

- [asset-upload](./asset-upload/SKILL.md) — upload a file to PostPlan, get a public URL
- [bro](./bro/SKILL.md) — restate the last message in plain language, no jargon
- [file-pr](./file-pr/SKILL.md) — file a concise pull request
- [frontend-design](./frontend-design/SKILL.md) — distinctive production-grade frontend interfaces
- [gh](./gh/SKILL.md) — GitHub CLI patterns for agents (`gh`)
- [html-communication](./html-communication/SKILL.md) — self-contained HTML drafts, published to PostPlan
- [no-comments](./no-comments/SKILL.md) — remove unnecessary comments and fix the code problems they explain
- [unslop](./unslop/SKILL.md) — cut AI tells from writing
- [wait-what](./wait-what/SKILL.md) — re-pitch the last message with the missing context, in plain English
- [xurl](./xurl/SKILL.md) — X API CLI: posts, search, DMs, media, XChat (`xurl` binary)

## Environment variables

| Variable | Skill |
| --- | --- |
| `POSTPLAN_TOKEN` | asset-upload, html-communication |

## Installation

No clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/skills/install.sh | bash
```

Or from a checkout:

```bash
git clone https://github.com/immanuel-peter/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x skills/install.sh
./skills/install.sh
```

What the installer does:

1. Copies each skill directory into `~/.agents/skills/<name>/`
2. Symlinks `~/.claude/skills/<name>` → `../../.agents/skills/<name>`
3. Reports whether `POSTPLAN_TOKEN` is set

Existing files under `~/.agents/skills/<name>/` are replaced. Other skills already on the machine are left alone.
