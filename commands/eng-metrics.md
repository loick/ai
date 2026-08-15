# Engineering Delivery Metrics

Run the `eng-metrics` script — ad-hoc GitHub PR delivery metrics (lead time and
review engagement) sliced by author, window, LoC band, and repo scope. Reads raw
GitHub data via `gh` + `jq`; nothing is stored.

input = $ARGUMENTS

## Usage

```
/eng-metrics lead-time --since 2026-06-01
/eng-metrics lead-time --org acme-team --min-loc 300 --compare
/eng-metrics reviews  --repo acme-team/acme-platform --since 2026-05-01 --min-loc 300
/eng-metrics reviews  --org acme-team --denominator events
```

Two metrics:

- `lead-time` — PR open → merge duration per author (median / mean / p90).
- `reviews` — review engagement per reviewer (comments, distinct PRs, per-PR avg).

Key flags: `--repo` / `--org`, `--since` / `--until`, `--min-loc` / `--max-loc`,
`--compare` (vs the preceding equal-length window), `--denominator prs|events`
(reviews), `--include-bots`, `--json`. Full reference: `eng-metrics --help`.

## Execute

```bash
eng-metrics $ARGUMENTS
```

If `eng-metrics` is not found, run it by path: `~/dotfiles/bin/eng-metrics $ARGUMENTS`.

## Notes

- Lead time is **open → merge**, not first-commit → merge — the cheap, honest
  version. If you need first-commit lead time, that requires commit history and a
  different query.
- The review denominator defaults to **distinct PRs reviewed**, not raw review
  submissions (which over-count roughly 3× because each batch of inline comments
  is its own review object). Use `--denominator events` for the raw-submission
  basis.
- Numbers come from raw GitHub data and **will not match third-party review
  dashboards** — those use different repo scope, windows, and definitions.
- Bots (AI reviewers, dependabot, CI apps) are excluded by default; `--include-bots`
  to keep them, `--bots "a,b,c"` to override the list.
- Default window is the last 30 days; org mode fans out over all non-archived,
  non-fork repos.
