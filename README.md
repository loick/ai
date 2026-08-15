# ai

Portable AI coding-agent config, shared across machines and tools. `AGENTS.md`
is the single source of truth for agent instructions; `CLAUDE.md` is a symlink
to it, so Claude Code, Codex, and Cursor all read the same rules.

`install.sh` wires everything into `~/.claude`: global agent instructions,
subagents, custom and remote skills, slash commands, output styles, default
settings, and MCP servers.

## Prerequisites

The toolchain is **not** installed by this repo. Ensure these are present first
(they come from a normal dev machine setup, e.g. Homebrew):

```sh
brew install jq node
brew install --cask claude-code
```

## Setup

```sh
cp .env.example .env   # fill in your tokens
./install.sh
```

Re-run `./install.sh` any time to reconcile config; it is idempotent and stays
the source of truth for `~/.claude`.

## Layout

- `AGENTS.md` — global agent instructions (`CLAUDE.md` → symlink)
- `comment-rules.md`, `agent-doc-rules.md`, `RTK.md` — rule files `@`-imported by `AGENTS.md`
- `agents.txt` — subagents to pull from the upstream subagents catalog
- `skills/` — custom skills; `skills.txt` — remote skills to install
- `commands/` — global slash commands
- `output-styles/` — Claude Code output styles
- `plugins.txt` — Claude Code plugins + their marketplaces
- `setup-mcp.sh` — MCP server + permission configuration

## Secrets

`.env`, `gmail-oauth.keys.json`, and `gmail-oauth.credentials.json` are
gitignored and never committed. See `.env.example` for what each var is for.
