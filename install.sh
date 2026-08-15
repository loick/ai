#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

AGENTS_REPO="https://github.com/VoltAgent/awesome-claude-code-subagents.git"
AGENTS_CACHE="$HOME/.claude/agents-src"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Env
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
  echo "✔ .env loaded"
else
  echo "⚠ No .env file found — copy .env.example to .env and fill in your values"
fi

# jq and node are provided by the machine's package manager, not this repo.
command -v jq   > /dev/null 2>&1 || echo "⚠ jq not found — settings/MCP merge will be skipped (install jq)"
command -v node > /dev/null 2>&1 || echo "⚠ node not found — remote skills and Claude CLI need it (install node)"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# AGENTS.md (CLAUDE.md is a symlink to it)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

mkdir -p ~/.claude
# @-imports inside the doc resolve relative to the symlink target, so the rule
# files sit next to AGENTS.md in this repo and need no separate link.
ln -Fs "$SCRIPT_DIR/AGENTS.md" ~/.claude/CLAUDE.md
echo "✔ CLAUDE.md symlink → AGENTS.md"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Agents (VoltAgent/awesome-claude-code-subagents)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -d "$AGENTS_CACHE" ]; then
  git -C "$AGENTS_CACHE" pull --ff-only
else
  git clone "$AGENTS_REPO" "$AGENTS_CACHE"
fi

# Claude Code doesn't follow directory symlinks — ensure it's a real directory
[ -L ~/.claude/agents ] && rm ~/.claude/agents
mkdir -p ~/.claude/agents

AGENTS_LIST="$SCRIPT_DIR/agents.txt"
while IFS= read -r agent_name || [ -n "$agent_name" ]; do
  # Skip comments and blank lines
  case "$agent_name" in
    '#'*|'') continue ;;
  esac
  agent_file=$(find "$AGENTS_CACHE/categories" -name "${agent_name}.md" | head -1)
  if [ -n "$agent_file" ]; then
    cp "$agent_file" ~/.claude/agents/"${agent_name}.md"
  else
    echo "⚠ Agent not found: $agent_name"
  fi
done < "$AGENTS_LIST"
echo "✔ Claude agents installed globally"

# Claude Code bundles its own ripgrep binary to scan ~/.claude/agents/, ~/.claude/skills/,
# etc. for .md files. npm installs it without execute permissions, so Claude silently finds
# nothing. Fix it here so agents/skills/commands always load after a fresh npm install.
RG_BIN="$(npm root -g 2>/dev/null)/@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin/rg"
if [ -f "$RG_BIN" ] && [ ! -x "$RG_BIN" ]; then
  chmod +x "$RG_BIN"
  echo "✔ Fixed Claude bundled ripgrep permissions"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Custom Skills
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

mkdir -p "$SKILLS_DST"

for skill in "$SKILLS_SRC"/*; do
  name="$(basename "$skill")"
  [ "$name" = ".gitkeep" ] && continue
  rm -rf "$SKILLS_DST/$name"
  ln -Fs "$skill" "$SKILLS_DST/$name"
done
echo "✔ Custom skills symlinked"

# Install CLI symlinks for any skill that ships a <name>.sh script
mkdir -p "$HOME/bin"
for skill in "$SKILLS_DST"/*; do
  name="$(basename "$skill")"
  script="$skill/$name.sh"
  if [ -f "$script" ]; then
    chmod +x "$script"
    ln -sf "$script" "$HOME/bin/$name"
    echo "✔ $name CLI installed to ~/bin/$name"
  fi
done

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Commands (global slash commands)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

COMMANDS_SRC="$SCRIPT_DIR/commands"
COMMANDS_DST="$HOME/.claude/commands"

if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DST"
  for cmd in "$COMMANDS_SRC"/*.md; do
    [ -e "$cmd" ] || continue
    name="$(basename "$cmd")"
    ln -Fs "$cmd" "$COMMANDS_DST/$name"
  done
  echo "✔ Global commands symlinked"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Output Styles
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

OUTPUT_STYLES_SRC="$SCRIPT_DIR/output-styles"
OUTPUT_STYLES_DST="$HOME/.claude/output-styles"

if [ -d "$OUTPUT_STYLES_SRC" ]; then
  mkdir -p "$OUTPUT_STYLES_DST"
  for style in "$OUTPUT_STYLES_SRC"/*.md; do
    [ -e "$style" ] || continue
    name="$(basename "$style")"
    ln -Fs "$style" "$OUTPUT_STYLES_DST/$name"
  done
  echo "✔ Output styles symlinked"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remote Skills
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

SKILLS_LIST="$SCRIPT_DIR/skills.txt"

if command -v skills > /dev/null 2>&1 || npm install -g skills > /dev/null 2>&1; then
  # Group skills by repo and install in one call per repo. Disable globbing so a
  # `*` skill token (install every skill in the repo) reaches the CLI literally
  # instead of expanding against the working directory.
  set -f
  grep -v '^\s*#' "$SKILLS_LIST" | grep -v '^\s*$' | awk '{repos[$1] = repos[$1] " --skill " $2} END {for (r in repos) print r repos[r]}' | while read -r cmd; do
    repo=$(echo "$cmd" | awk '{print $1}')
    skill_flags=$(echo "$cmd" | cut -d' ' -f2-)
    # -g --copy installs real files at the user level. Without them the CLI writes
    # repo-local symlinks that Claude also loads, registering each skill twice.
    # shellcheck disable=SC2086
    skills add "$repo" $skill_flags -g --copy -a claude-code codex cursor -y < /dev/null
  done
  set +f
  echo "✔ Remote skills installed"
else
  echo "⚠ Could not install skills CLI — skipping remote skills"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Plugins
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

PLUGINS_LIST="$SCRIPT_DIR/plugins.txt"

if [ -f "$PLUGINS_LIST" ]; then
  # Add each unique marketplace once
  grep -v '^\s*#' "$PLUGINS_LIST" | grep -v '^\s*$' | awk '{print $1}' | sort -u | while read -r source; do
    claude plugin marketplace add "$source" 2>/dev/null || true
  done
  # Install each plugin
  grep -v '^\s*#' "$PLUGINS_LIST" | grep -v '^\s*$' | awk '{print $2}' | while read -r plugin; do
    claude plugin install "$plugin" 2>/dev/null || true
  done
  echo "✔ Plugins installed"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Settings
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

SETTINGS_FILE="$HOME/.claude/settings.json"
DEFAULT_OUTPUT_STYLE="Zero Trust Didactic"
DEFAULT_PERMISSION_MODE="default"

if [ ! -f "$SETTINGS_FILE" ]; then
  printf '{"permissions":{"allow":["Read"],"defaultMode":"%s"},"outputStyle":"%s"}\n' "$DEFAULT_PERMISSION_MODE" "$DEFAULT_OUTPUT_STYLE" > "$SETTINGS_FILE"
else
  if command -v jq > /dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg style "$DEFAULT_OUTPUT_STYLE" --arg mode "$DEFAULT_PERMISSION_MODE" '
      (if (.permissions.allow | index("Read")) == null then .permissions.allow += ["Read"] else . end)
      | .permissions.defaultMode = $mode
      | .outputStyle = $style
    ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
  else
    echo "⚠ jq not found — skipping settings.json merge (install jq to enable)"
  fi
fi
echo "✔ Claude settings configured"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# MCP Servers
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sh "$SCRIPT_DIR/setup-mcp.sh"
