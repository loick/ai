# Docker Compose Down for Current Worktree

Stop the Compose stack for the repo of the worktree you run this from. The
project name is derived from the **main checkout's** directory — the same key
`/docker-up` uses — so this tears down whichever worktree currently holds the
stack, regardless of where it was started.

input = $ARGUMENTS

## Usage

```
/docker-down               # stop the stack, keep volumes (DB persists)
/docker-down -v            # also remove named volumes (wipes the database)
/docker-down <service...>  # stop only these services
```

## Execute

```bash
WT_ROOT="$(git rev-parse --show-toplevel)"
MAIN_ROOT="$(git -C "$WT_ROOT" worktree list --porcelain | head -1 | sed 's/^worktree //')"
PROJECT="$(basename "$MAIN_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')"

cd "$WT_ROOT"
docker compose -p "$PROJECT" down $ARGUMENTS

echo "Stopped project: $PROJECT"
```

## Notes

- `down` without `-v` keeps named volumes, so dependencies and any database
  survive and are reused on the next `/docker-up`.
- Because the project name is fixed per repo, this stops the single shared stack
  no matter which worktree brought it up.
- To stop without removing containers, pass `stop` semantics instead via
  `docker compose -p <project> stop`.
