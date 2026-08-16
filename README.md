# ai

My approach to building with and adopting AI, and the portable config that implements it.

Two things live here:

- **The playbook** (`ai-manifesto/`): an opinionated, team-facing take on doing AI well.
- **The config** (everything else): a portable AI coding-agent setup, shared across machines and tools.

## The playbook

> **The spine:** your job is the whole loop, specify, orchestrate, verify. The agent only takes the middle. Both ends stay yours.

- **[Manifesto](./ai-manifesto/MANIFESTO.md)**: 14 principles. Where your effort should go, how to review, how to coordinate, how to keep data and judgment where they belong.
- **[Playbook](./ai-manifesto/PLAYBOOK.md)**: the tunable dials. Parallelism, layered review and AI-merge gates, the hard floor, PR ownership, tickets, project forecasting, security & confidentiality, model selection.
- **[WAT](./ai-manifesto/WAT.md)**: the Workflows / Agents / Tools architecture that makes the manifesto buildable. Probabilistic AI reasons, deterministic code executes.

A mindset, not a rulebook. The principles are stable; the numbers and mechanics change as models and tooling improve. For engineers and non-engineers alike.

## The setup

Portable AI coding-agent config, shared across machines and tools. `AGENTS.md` is the single source of truth for agent instructions; `CLAUDE.md` is a symlink to it, so Claude Code, Codex, and Cursor all read the same rules. `install.sh` wires everything into `~/.claude`: global agent instructions, subagents, custom and remote skills, slash commands, output styles, default settings, and MCP servers.

### Prerequisites

The toolchain is **not** installed by this repo. Ensure these are present first (they come from a normal dev machine setup, e.g. Homebrew):

```sh
brew install jq node
brew install --cask claude-code
```

Optional, for React Native / Expo debugging on simulators and emulators: `npx @swmansion/argent@latest init` installs the `argent` CLI, which `setup-mcp.sh` wires up as an MCP server (skipped automatically if the CLI isn't present).

### Install

```sh
cp .env.example .env   # fill in your tokens
./install.sh
```

Re-run `./install.sh` any time to reconcile config; it is idempotent and stays the source of truth for `~/.claude`.

### Install as a plugin (shareable skills only)

The shareable parts — skills, slash commands, and the output style — are also packaged as a Claude Code plugin, so others can use them without cloning. **In Claude Code** (these are prompt commands, not shell), run:

```text
/plugin marketplace add loick/ai
/plugin install ai-config@loick-ai
/reload-plugins
```

The skills load namespaced under `ai-config:` (e.g. `/ai-config:comment-audit`, `/ai-config:xp-reviewer`), and the output style becomes selectable. Publicly installable while the repo is public.

It intentionally does **not** carry the global agent instructions, subagent catalog, or MCP setup — a plugin can't ship those; run `install.sh` for the full setup.

### Layout

- `AGENTS.md`: global agent instructions (`CLAUDE.md` is a symlink)
- `agent-doc-rules.md`, `RTK.md`: rule files `@`-imported by `AGENTS.md`
- `.claude-plugin/`: plugin + marketplace manifests, so the shareable skills/commands/output-style install via `/plugin`
- `agents.txt`: subagents to pull from the upstream catalog
- `skills/`: custom skills; `skills.txt`: remote skills to install
- `commands/`: global slash commands
- `output-styles/`: Claude Code output styles
- `plugins.txt`: Claude Code plugins and their marketplaces
- `setup-mcp.sh`: MCP server and permission configuration

### Secrets

`.env`, `gmail-oauth.keys.json`, and `gmail-oauth.credentials.json` are gitignored and never committed. See `.env.example` for what each var is for.
