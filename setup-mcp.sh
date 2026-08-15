#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SETTINGS="$HOME/.claude/settings.json"
MCP_FILE="$HOME/.claude.json"

# Ensure files exist with valid JSON
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi
if [ ! -f "$MCP_FILE" ]; then
  echo "{}" > "$MCP_FILE"
fi

# Upsert an MCP server config. Always overwrites so the script stays the source
# of truth — re-running install.sh reconciles any config drift in ~/.claude.json.
# Usage: add_mcp <name> <json-object>
add_mcp() {
  name="$1"
  config="$2"

  tmp=$(mktemp)
  jq --arg name "$name" --argjson config "$config" \
    '.mcpServers[$name] = $config' "$MCP_FILE" > "$tmp" && mv "$tmp" "$MCP_FILE"
  echo "  ✔ MCP '$name' configured"
}

# Add a permission if it doesn't already exist.
# Usage: add_permission <tool>
add_permission() {
  tool="$1"

  existing=$(jq -r --arg tool "$tool" '.permissions.allow // [] | index($tool)' "$SETTINGS")
  if [ "$existing" != "null" ]; then
    echo "  ↳ Permission '$tool' already set, skipping"
    return
  fi

  tmp=$(mktemp)
  jq --arg tool "$tool" \
    '.permissions.allow = ((.permissions.allow // []) + [$tool])' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "  ✔ Permission '$tool' added"
}

echo "Configuring Claude MCP servers..."

add_mcp "context7" '{
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"]
}'

add_permission "mcp__context7__resolve-library-id"
add_permission "mcp__context7__query-docs"

add_mcp "chrome-devtools" '{
  "command": "npx",
  "args": ["-y", "chrome-devtools-mcp@latest"]
}'

if [ -z "$LINEAR_API_KEY" ]; then
  echo "  ⚠ LINEAR_API_KEY not set, skipping Linear MCP"
else
  add_mcp "linear" "{
    \"command\": \"npx\",
    \"args\": [\"-y\", \"@linear/mcp-server\"],
    \"env\": { \"LINEAR_API_KEY\": \"$LINEAR_API_KEY\" }
  }"
fi

# We want to allow permissions anyway, if Linear is configured directly from Claude Code.
add_permission "mcp__linear__get_authenticated_user"
add_permission "mcp__linear__save_issue"
add_permission "mcp__linear__list_teams"
add_permission "mcp__linear__list_milestones"

if [ -z "$NOTION_API_TOKEN" ]; then
  echo "  ⚠ NOTION_API_TOKEN not set, skipping Notion MCP"
else
  add_mcp "notion" "{
    \"command\": \"notion-mcp-server\",
    \"env\": { \"NOTION_TOKEN\": \"$NOTION_API_TOKEN\" }
  }"
fi

# Google Workspace (personal) MCP — Gmail + Calendar behind one server, reusing
# the same OAuth Desktop client JSON at ./gmail-oauth.keys.json.
# Prerequisites (one-time, in the same GCP project as the OAuth client):
#   - Enable the Google Calendar API (Gmail API is already enabled).
#   - Register redirect URI http://localhost:8000/oauth2callback on the client.
# Auth runs inline on first tool use (browser opens); token is stored by the
# server outside the repo, so no credentials file is tracked here.
GOOGLE_OAUTH_KEYS="$SCRIPT_DIR/gmail-oauth.keys.json"
if [ ! -f "$GOOGLE_OAUTH_KEYS" ]; then
  echo "  ⚠ $GOOGLE_OAUTH_KEYS not found — skipping Google Workspace MCP (see .env.example)"
elif [ -z "$USER_GOOGLE_EMAIL" ]; then
  echo "  ⚠ USER_GOOGLE_EMAIL not set — skipping Google Workspace MCP (see .env.example)"
else
  add_mcp "google-workspace-personal" "{
    \"command\": \"uvx\",
    \"args\": [\"workspace-mcp\", \"--single-user\", \"--tools\", \"gmail\", \"calendar\"],
    \"env\": {
      \"GOOGLE_CLIENT_SECRET_PATH\": \"$GOOGLE_OAUTH_KEYS\",
      \"USER_GOOGLE_EMAIL\": \"$USER_GOOGLE_EMAIL\",
      \"OAUTHLIB_INSECURE_TRANSPORT\": \"1\"
    }
  }"
fi

# Gmail
add_permission "mcp__google-workspace-personal__search_gmail_messages"
add_permission "mcp__google-workspace-personal__get_gmail_message_content"
add_permission "mcp__google-workspace-personal__get_gmail_messages_content_batch"
add_permission "mcp__google-workspace-personal__get_gmail_thread_content"
add_permission "mcp__google-workspace-personal__send_gmail_message"
add_permission "mcp__google-workspace-personal__draft_gmail_message"
add_permission "mcp__google-workspace-personal__list_gmail_labels"
add_permission "mcp__google-workspace-personal__manage_gmail_label"
add_permission "mcp__google-workspace-personal__modify_gmail_message_labels"
add_permission "mcp__google-workspace-personal__batch_modify_gmail_message_labels"
add_permission "mcp__google-workspace-personal__list_gmail_filters"
add_permission "mcp__google-workspace-personal__manage_gmail_filter"
# Calendar
add_permission "mcp__google-workspace-personal__list_calendars"
add_permission "mcp__google-workspace-personal__get_events"
add_permission "mcp__google-workspace-personal__manage_event"
add_permission "mcp__google-workspace-personal__query_freebusy"
