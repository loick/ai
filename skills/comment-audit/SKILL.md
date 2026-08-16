---
name: comment-audit
description: >-
  Audits comments in changed code — or a given path — against the repo's comment rules. Flags comments that leak a vendor or foreign internals, reference the change/PR, describe call-sites, restate the code, or state what the code does not do. Reports violations only; never rewrites unprompted. Language-agnostic. Triggers: "audit comments", "comment lint", "check comments", "review the comments", "are these comments ok".
metadata:
  domain: dev
  tags: "comments, code-quality, review, lint"
  consumers: "claude-code"
---

# Comment Audit

Review comments against the repo's comment rules and report violations for a human to act on. This is a flag, never a fix — comment edits are semantic, not cosmetic, so a human validates them.

## When to Use

- Before committing or opening a PR — audit the comments a change introduced
- Reviewing an existing file or directory for comment quality
- User asks "audit comments", "check the comments", "comment lint", "are these comments ok"

## Scope: diff by default, path on request

- **No argument** → audit only the comments **added or changed** in the current diff (`git diff HEAD`). This is the common case: judge the churn, not the whole repo.
- **A path/dir argument** → audit **all** comments in the matching files. Use for reviewing existing code.
- **A git ref/range argument** (e.g. `main`, `HEAD~3`) → diff against that instead of `HEAD`.

## Workflow

### 1. Load the rules

Read `references/comment-rules.md` (relative to this skill). It is the rubric — judge against it, do not invent or paraphrase your own criteria.

### 2. Collect the comments

**Diff mode (default):**

```bash
git diff ${ARG:-HEAD} -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.sql'
```

The rules themselves are language-agnostic; this default glob just scopes to the repo's primary source extensions for a fast, low-noise pass. For other languages, widen the glob or use path mode.

Keep only **added (`+`) or modified comment lines** — `//`, `/* */`, `/** */`, `#`. Ignore pre-existing comments the change did not touch, code lines, deletions, and whitespace.

**Path mode:** read the files under the given path and collect every comment.

For each comment, capture `file:line` **and the signature/code it annotates** — the rules judge a comment against the code it sits on, so the context is required.

If there are no comments in scope, say so and stop. A clean result is the expected outcome most of the time.

### 3. Judge each comment

Decide `clean` or `violation`. Assess the comment **as written**, with fresh eyes — not the intent you imagine the author had. When a comment merely restates the code, the right call is usually deletion, not rewording. For each violation record:

- `file:line`
- the comment text
- the exact rule it breaks (quote it from the rubric)
- **severity** — `substantive` vs `nit` (see the rubric)
- a suggested rewrite or deletion

### 4. Report — do not edit

```markdown
# Comment Audit

**Scope**: <diff vs path> · **Files**: K · **Comments checked**: N
**Violations**: X substantive, Y nits

## Violations (grouped by file)

src/foo.ts:42  [substantive] — leaks a vendor (rule: "Name a vendor or another library's internals")
  // PostHog fires the connected event on the webhook
  → Suggest: delete — describes work done elsewhere, not this symbol.
```

Lead with substantive findings; nits go last. End with the one-line tally.

### 5. Stop and ask before changing anything

Present the report and **ask** which fixes to apply. Apply only what the user confirms. Never rewrite comments unprompted — that turns a review into an unreviewed semantic edit of someone's code.

## Notes

- This skill audits; it does not enforce. The authoring-time rules live in each repo's agent docs — this is the checkpoint that catches what slipped through.
- The rubric in `references/comment-rules.md` is the single source of truth. If a consuming repo also ships a comment-rules doc, keep them in sync (or have the repo point at this skill).
