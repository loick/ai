---
name: pr-feedback
description: Monitor a GitHub PR until merged and present new feedback one item at a time for the user to accept or reject, remembering equivalent decisions within that PR. Use when the user asks to watch a PR and approve its review feedback interactively.
---

# PR Feedback

The user decides which feedback to accept. Keep watching until the PR is merged, the user stops, or an error needs intervention. A green CI or empty review queue is not completion. Never merge or enable auto-merge.

## Start and listen

Resolve the requested PR; use the current branch's PR if unambiguous. Record its URL, head repository, head SHA and base. Read the repository instructions and inspect working-tree changes before editing; preserve unrelated work.

Run the bundled read-only watcher with an absolute path:

```sh
python3 <skill-dir>/scripts/watch.py <PR-URL>
```

It reports existing comments on the first run, new or edited PR comments, review summaries and inline replies, and merge/closure. It paginates all comment collections. A per-PR lock prevents duplicate watchers. Errors exit loudly; they are not a successful or empty poll. It does not post, edit code, or resolve threads.

Use the harness's streaming monitor when available. Otherwise keep the command session and this turn active, resuming the command at intervals of at most 60 seconds. Drain events while waiting for a user decision, but queue them rather than opening a second question. Do not claim that a finished conversation will keep monitoring: without a live monitor/session, explain the interruption and how to resume. Restart the watcher after errors only once their cause is addressed.

The watcher prints its state directory first. Keep `decisions.json` there, outside the repository, alongside its transport state. On every start or resume, fetch all existing PR comments, review summaries and unresolved review threads with pagination and reconcile them against that ledger; the watcher remembers delivered events, not unfinished work. Persist each detected finding as pending (source IDs, URLs and content revision, with no decision yet) before asking about it. Read previous pending findings and actions before handling new events. This startup rescan recovers even an event delivered just before a crash, including feedback without a resolvable thread. Fetch full thread/review contents and current resolution status through GitHub tools or paginated `gh api` queries before judging a finding. Skip status-only messages, your own acknowledgements, resolved threads and feedback that no longer applies. A review summary and inline comment describing the same problem are one finding.

## Decide one finding at a time

Inspect the relevant code and explain the feedback in French (or the user's language): location and link, claimed problem, what is actually true, and your recommendation. Keep unrelated findings queued. Split a comment containing multiple independent findings and resolve its thread only once every finding has an outcome.

Ask one self-contained question using the harness's user-input tool, or a normal question if unavailable. Present exactly these two actions:

1. **Accepter et corriger** — describe the smallest correction, relevant verification, and thread closure.
2. **Rejeter et répondre** — show the exact proposed GitHub reply, then thread closure.

Make a real recommendation based on evidence; do not invent a rebuttal if the feedback is correct. If rejection would leave a known issue, say so and offer factual wording acknowledging that it is deferred. The user can edit the reply or request clarification before choosing. Do not change code, post a reply or resolve this finding until the user chooses, unless an equivalent decision is already recorded.

## Remember the decision

Write the decision before acting, then persist progress after each successful action. Keep the ledger valid JSON and replace it atomically. For each finding record:

- root problem, affected behavior, relevant constraints and evidence;
- accept/reject and the user's rationale, plus approved rejection wording;
- source comment URLs and review thread IDs (or top-level comment IDs);
- progress: pending, verified commit if any, posted reply URL, resolved threads.

Compare meaning, not just wording: another bot, another line number or a paraphrase is not a new decision. Reuse a choice only for the same root problem under the same relevant constraints in this PR. Announce the reused decision briefly and act without asking again. Adapt factual references in an approved reply, preserving its meaning. Changed constraints or genuinely different failure modes require a new question; explain the material difference. Do not re-ask merely because HEAD changed or a bot repeated itself. Never extend a decision automatically to a different PR.

## Apply and close

**Accept:** make the scoped correction, run relevant repository checks, commit and push to the PR's actual head branch using the repository workflow. Recheck that the finding is fixed on the pushed head. Resolve the associated review thread only after the push and verification succeed. If an acknowledgement is useful, keep it factual, e.g. `Corrigé dans <commit>.` Do not bundle unrelated changes or bypass checks. If the finding was already fixed, verify that instead of manufacturing another commit.

**Reject:** post the approved reply in the review thread, verify its returned URL, then resolve that thread. Write in the repository's review language unless the user specifies otherwise. Use plain factual wording: no model name, agent/tool attribution, AI badge, signature, or invented personal claim. This custom workflow replaces `leaving-pr-comments` for these replies.

Use GitHub's actual review thread ID for `resolveReviewThread`; comment IDs are not thread IDs. Top-level PR comments and review summaries have no resolvable thread: reply where supported, otherwise reference the feedback in a PR comment, and mark it handled in the ledger. Do not pretend to close something GitHub cannot resolve.

Before any write, recheck PR state, current feedback and head. If the PR merged or the thread was resolved while waiting, update the ledger and skip obsolete actions. Respect concurrent branch updates; never force-push or overwrite others' work. A failed push, reply or resolution remains pending: record the error and resume the missing step without repeating the user's choice. If an action may have succeeded before its result was saved, reconcile GitHub first: find the already-pushed correction, or an existing reply by the authenticated user matching the approved text in that thread, and recover its commit/URL. Retry only when the remote state proves it is missing; ambiguous results need investigation, not a duplicate reply. Recheck resolution status before retrying closure.

After each action, reconcile queued feedback and continue watching. CI-only notifications do not authorize unrelated fixes. If the PR is closed without merging, stop and report that state; do not reopen it. On merge, stop the watcher and report the PR link, accepted/rejected decisions and any unfinished actions. On user interruption, stop the watcher, save progress and say monitoring has stopped.
