## Workflow Orchestration

### 1. Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Question blind spots before specifying
- Propose alternatives if the feature seems poorly thought out
- Use plan mode for verification steps, not just building
- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done

- Never mark a task complete without proving it works

---

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.

---

## Comments

A comment describes only the symbol it sits on — no vendor names, PR-references, call-sites, foreign internals, or restating the code. Try to delete the need for the comment first. Full rubric:

@comment-rules.md

## Agent docs (AGENTS.md / CLAUDE.md)

Per-package agent docs describe the package's shape and boundaries, never its file names or symbols — write to the slow layer so a rename can't falsify them. Full rubric:

@agent-doc-rules.md

## React

- For Multi-part UI (tabs, dropdowns, menus), prefer compound components with Context over prop drilling.
- Compound component API: the main component IS the root (`<Breadcrumb>…</Breadcrumb>`), not a `.Root` child. Attach subparts as static properties (`Breadcrumb.Item`, `Breadcrumb.Separator`).
- For every components, always keep the rule of 1 component per file.

## JSX Formatting

- Add a blank line between sibling components in JSX for readability:

```tsx
// Good
<Layout.Column>
  <ComponentA />

  <ComponentB />

  <ComponentC />
</Layout.Column>

// Avoid
<Layout.Column>
  <ComponentA />
  <ComponentB />
  <ComponentC />
</Layout.Column>
```

### MCPs
When I want to connect to my personal MCP for:

@RTK.md
