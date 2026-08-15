---
name: qa-swarm
description: >
  Orchestrates four review skills (paul-reviewer, xp-reviewer,
  security-audit, ponytail) into a single comprehensive PR review with inline GitHub
  comments. Use when the user asks for "qa-swarm", "swarm review", or wants a
  full multi-perspective review posted to their PR. Accepts an optional PR
  number or base branch as argument.
---

# QA Swarm: Multi-Perspective PR Review

Runs four independent review perspectives in parallel and posts findings as
inline PR comments. Each reviewer operates independently — none knows about
the others.

## Bot identifier — REQUIRED on every posted comment

Every comment this skill posts to GitHub (inline review comments, review
body, top-level PR comments, thread replies — **every single one**) must
begin with the bot-identifier header so a human reader can tell at a
glance that it was not written by a person:

```markdown
> [!NOTE]
> 🤖 Automated comment by **QA Swarm** — not written by a human
```

Do not skip this header under any circumstance. If the comment body is
constructed in multiple places, apply the header at the outermost point
where the body is assembled. The existing templates in Step 5 already
include a compliant header; keep it in place when adapting them.

On public repositories (e.g. PostHog/posthog), never put absolute production
counts — raw event, user, or revenue numbers — in a finding or comment. Cite
percentages or ratios instead; the repo is public and absolute counts leak
operational scale.

## Workflow

### Step 1: Detect PR & gather diff

If `$ARGUMENTS` looks like a PR number or URL, use that. Otherwise detect the
current PR:

```bash
gh pr view --json number,headRefName,baseRefName,url
```

If no PR exists, fall back to diffing against `master` (or `main` if `master`
doesn't exist). In this case, skip PR commenting and output the report to the
terminal only.

Gather context:

```bash
git diff <base>...HEAD --name-only
git diff <base>...HEAD
git log <base>...HEAD --oneline
git rev-parse HEAD
```

Store: PR number, owner/repo (from `gh repo view --json owner,name`), base
branch, changed file list, full diff, commit log, and HEAD SHA.

### Step 2: Load skill content

Load the three reviewer bodies. paul-reviewer, xp-reviewer and security-audit
resolve local-first. ponytail is a plugin.

Issue all four loads in **parallel** (single message, four tool calls).

### Step 3: Launch 4 review agents in parallel

Launch ALL agents in a **single message** with multiple Agent tool calls so
they run in true parallel.

Pin each reviewer's model explicitly on its Agent call rather than inheriting
the session/caller model — review is the reasoning-heavy part of the loop and
must stay sharp even when the caller (e.g. pr-shepherd's runner) is on a
cheaper model. The split:

- **security-audit: `model: 'opus'`** — the technical-depth
  reviewers get the strongest model.
- **ponytail, paul-reviewer and xp-reviewer: `model: 'opus'`** — voice/style reviewers;
  fable's 2x per-token cost isn't warranted there.

If the harness rejects `'fable'` (older Claude Code), fall back to `'opus'`
for that agent.

Each agent is told it is the sole reviewer. Each must return findings in the
structured format described in "Agent output format" below.

#### Agent 1: paul-reviewer

Pass the full paul-reviewer SKILL.md content and real-review-examples into the
agent prompt, along with the diff. Tell it to review the diff in Paul's voice
and return structured findings with `reviewer: paul`.

#### Agent 2: xp-reviewer

Pass the full xp-reviewer SKILL.md content and c2wiki-wisdom into the agent
prompt, along with the diff. Tell it to review the diff in the XP voice and
return structured findings with `reviewer: xp`.

#### Agent 3: security-audit

Pass the full security-audit SKILL.md content into the agent
prompt, along with the diff. Tell it to review the diff in the security-audit's voice and
return structured findings with `reviewer: security-audit`.

If the agent has no findings, return the `(none)` form described in the
"Agent output format" section below.

#### Agent 4: ponytail

Pass the full ponytail SKILL.md content into the agent
prompt, along with the diff. Tell it to review the diff in the ponytail's voice and
return structured findings with `reviewer: ponytail`.

#### Agent output format

Every agent must end its response with findings in this exact format:

```
STRUCTURED_FINDINGS:
- file: <path> | line: <number or "general"> | severity: <CRITICAL|HIGH|MEDIUM|LOW|NIT> | reviewer: <tag> | body: <the review comment text>
- file: <path> | line: <number or "general"> | severity: <CRITICAL|HIGH|MEDIUM|LOW|NIT> | reviewer: <tag> | body: <the review comment text>
...

OVERALL_SUMMARY:
<1 paragraph assessment>
```

If an agent has no findings, it returns:

```
STRUCTURED_FINDINGS:
(none)

OVERALL_SUMMARY:
<1 paragraph assessment>
```

### Step 4: Synthesize

Collect all findings from the four agents.

**Deduplication:** If multiple reviewers flagged the same file+line (within 5
lines) or clearly the same concern, merge them into a single finding. Note the
convergence — convergent findings carry higher confidence.

**Verdict**:
- CRITICAL: Any CRITICAL finding → overall CRITICAL
- HIGH: 2+ HIGH findings, or 1 HIGH + 2 MEDIUM → overall HIGH
- MEDIUM: 1 HIGH, or 3+ MEDIUM → overall MEDIUM
- LOW: Only LOW/NIT/none → overall LOW

Map to verdict:
- ✅ **APPROVE** — LOW, no actionable findings
- 💬 **APPROVE WITH NITS** — MEDIUM, minor suggestions
- ⚠️ **REQUEST CHANGES** — HIGH, fixes needed before merge
- 🚫 **BLOCKED** — CRITICAL, blocking issues

### Step 5: Post to PR

If no PR was detected, output the full report to the terminal and stop.

#### 5a: Inline comments

For each finding with a specific file and line number, post an inline review
comment. Use the GitHub pull request review API to post all comments as a
single review (not individual comments):

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  -f event="COMMENT" \
  -f body="QA Swarm review complete. See inline comments." \
  -f commit_id="{HEAD_SHA}" \
  --jq '.id' \
  -f 'comments[]={path: "<file>", line: <line>, body: "<comment_body>"}'
```

If the review API is awkward to construct with many comments, fall back to
posting individual comments:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --method POST \
  -f path="<file>" \
  -f line=<line> \
  -f commit_id="{HEAD_SHA}" \
  -f body="<comment_body>"
```

Each inline comment body uses this format:

```markdown
> [!NOTE]
> 🤖 Automated comment by **QA Swarm** — not written by a human

**[<reviewer_tag>]** <severity emoji> <severity>

<the finding body text>
```

Severity emojis: 🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🟢 LOW, ⚪ NIT

For convergent findings (flagged by 2+ reviewers independently):

```markdown
> [!NOTE]
> 🤖 Automated comment by **QA Swarm** — not written by a human

**[convergent: <reviewer1> + <reviewer2>]** <severity emoji> <severity>

<merged finding body>
```

#### 5b: Summary comment — one sticky comment per PR, upserted

qa-swarm maintains exactly **one** top-level summary comment per PR, marked
with `<!-- qa-swarm-summary -->`. Re-runs (re-review rounds, later shepherd
iterations) **update that comment in place** instead of posting a new one —
multiple bot comments per PR is exactly the noise this repo is trying to kill.
The comment always shows the LATEST verdict; earlier rounds collapse into a
`<details>` history block so the audit trail survives without the length.

First find any existing summary comment:

```bash
gh api "repos/{owner}/{repo}/issues/{pr_number}/comments" --paginate \
  --jq '[.[] | select(.body | contains("<!-- qa-swarm-summary -->"))][0].id'
```

Build the body in this shape (current verdict on top, prior rounds folded):

```markdown
<!-- qa-swarm-summary -->
> [!NOTE]
> 🤖 Automated comment by **QA Swarm** — not written by a human
>
> Multi-perspective review: paul-reviewer, xp-reviewer, ponytail, security-audit

## Verdict: <emoji> <VERDICT> <sub>(round <N> @ <short_sha>)</sub>

<1-2 sentences explaining the verdict>

### Key findings

<bulleted list of the top findings, grouped by severity — current round only>

### Convergence

<findings flagged independently by 2+ reviewers — these are highest confidence>

### Reviewer summaries

| Reviewer | Assessment |
| --- | --- |
| 👤 paul | <1 sentence> |
| 📐 xp | <1 sentence> |
| 🤓 ponytail | <1 sentence> |
| 🛡 security-audit | <1 sentence> |

<details>
<summary>Previous rounds (<n>)</summary>

<for each prior round, one compact line: `round <N> @ <short_sha> — <verdict>: <1-line disposition>`.
When updating, derive these lines from the existing comment's current-verdict
header plus its own history block — the previous round's detail collapses to
one line, it is not carried verbatim.>

</details>

---
*Automated by QA Swarm — not a human review*
EOF
```

If a comment id was found, update in place; otherwise create:

```bash
# update
gh api "repos/{owner}/{repo}/issues/comments/{comment_id}" -X PATCH -F body=@/tmp/qa-summary.md
# create (no existing comment)
gh pr comment {pr_number} --body-file /tmp/qa-summary.md
```

The inline review comments from 5a are unaffected — they are threaded,
per-finding, and resolvable. Only the top-level summary is deduplicated.

### Graceful degradation

- **paul-reviewer not found (disk or store):** Skip paul agent. Warn user. Run the other three.
- **xp-reviewer not found (disk or store):** Skip xp agent. Warn user. Run the other three.
- **security-audit not found:** Skip security-audit
  agent. Run the other three.
- **ponytail not found (disk or store):** Skip ponytail agent. Warn user. Run the other three.
- **No PR detected:** Run all reviews, output report to terminal only. Offer to post if user provides a PR number.
- **Only one reviewer available:** Still run it and post findings. Better than nothing.
