# Docker Compose Up in Current Worktree

Bring the Compose stack up against the worktree you run this from. A Compose
build context and bind mounts resolve relative to the compose file's directory,
so the stack serves whatever is checked out here — Docker has no git branch
awareness, only the directory decides.

input = $ARGUMENTS

## Usage

```
/docker-up                 # up the whole stack for the current worktree
/docker-up <service...>    # only these services
/docker-up --build         # force-rebuild images first
```

## Model

The project name is derived from the **main checkout's** directory, so every
worktree of the same repo maps to one shared project — one set of named volumes
and one stack. Re-running `up -d` from a different worktree recreates the
containers in place, pointing the single stack at the new directory. Host ports
are singular, so only one stack runs at a time — this command swaps it over.

## Execute

```bash
WT_ROOT="$(git rev-parse --show-toplevel)"
MAIN_ROOT="$(git -C "$WT_ROOT" worktree list --porcelain | head -1 | sed 's/^worktree //')"
PROJECT="$(basename "$MAIN_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')"

# .env is commonly gitignored and may not exist in a fresh worktree; copy it across.
if [ ! -f "$WT_ROOT/.env" ] && [ -f "$MAIN_ROOT/.env" ]; then
  cp "$MAIN_ROOT/.env" "$WT_ROOT/.env"
  echo "Copied .env from main checkout: $MAIN_ROOT/.env"
fi

cd "$WT_ROOT"
docker compose -p "$PROJECT" up -d $ARGUMENTS

echo "Stack up from: $WT_ROOT (project: $PROJECT)"
docker compose -p "$PROJECT" ps
echo "Logs: docker compose -p $PROJECT logs -f"
echo "Stop: docker compose -p $PROJECT down"
```

## Notes

- Runs detached (`-d`) so it returns; tail with `docker compose -p <project> logs -f`.
- First boot on a fresh volume set is slow if the stack installs deps or runs
  migrations on start; warm volumes are then reused across worktrees.
- Keeping the project name fixed per repo means volumes and any database persist
  across worktrees; `down` (no `-v`) preserves them. Add `-v` only to wipe them.
- Pass `--build` only after changing a Dockerfile.
