# Open Worktree in Cursor

Open the current worktree (or a named one) in Cursor.

input = $ARGUMENTS

## Usage

```
/open-worktree                  # open the current worktree
/open-worktree <name>           # open .claude/worktrees/<name>
```

## Execute

### No argument — open current worktree

Resolve the worktree root and launch Cursor:

```bash
WT_ROOT="$(git rev-parse --show-toplevel)"
cursor "$WT_ROOT"
echo "Opened in Cursor: $WT_ROOT"
```

### With a name argument

Look up the worktree by name under `.claude/worktrees/`:

```bash
MAIN_ROOT="$(git rev-parse --show-toplevel)"
# If we're inside a worktree, find the main checkout
MAIN_ROOT="$(git -C "$MAIN_ROOT" worktree list --porcelain | head -1 | sed 's/^worktree //')"
WT_PATH="$MAIN_ROOT/.claude/worktrees/<name>"

if [ ! -d "$WT_PATH" ]; then
  echo "❌ Worktree not found: $WT_PATH"
  echo "Existing worktrees:"
  git -C "$MAIN_ROOT" worktree list
  exit 1
fi

cursor "$WT_PATH"
echo "Opened in Cursor: $WT_PATH"
```

## Notes

- Uses the `cursor` CLI shipped with Cursor.app (`/usr/local/bin/cursor`). If missing, ask the user to run `Cmd+Shift+P → Shell Command: Install 'cursor' command` in Cursor.
- Does not block — Cursor launches detached.
