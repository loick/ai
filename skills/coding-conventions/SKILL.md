---
name: coding-conventions
description: >-
  Loick's code-authoring conventions — comment style, React component patterns, and JSX formatting. Use whenever writing or editing code, and especially when authoring or changing React / TypeScript (.tsx) components. Triggers: writing code, adding a component, refactoring, "build/add/change a React component", editing JSX.
metadata:
  domain: dev
  tags: "comments, react, jsx, code-style, conventions"
  consumers: "claude-code"
---

# Coding Conventions

Author code to these conventions. They apply while writing or editing code; the React and JSX rules apply only when working in React / `.tsx`.

## Comments

A comment describes only the symbol it sits on, pitched at a different altitude than the code (intent or precision, never restating it), and only when the code cannot be made to say it itself. No PR/change references, vendor names, call-site descriptions, or foreign internals. The `comment-audit` skill checks changed code against the full rubric.

## Readability

- Put the conditional body on its own line; avoid one-liner `if () return`. A break before the body reads more easily at a glance.

  ```ts
  // Avoid
  if (!user) return null

  // Prefer
  if (!user) {
    return null
  }
  ```

## Structure

- Enforce one function / component per file as much as practical.

## React

- For multi-part UI (tabs, dropdowns, menus), prefer compound components with Context over prop drilling.
- Compound component API: the main component IS the root (`<Breadcrumb>…</Breadcrumb>`), not a `.Root` child. Attach subparts as static properties (`Breadcrumb.Item`, `Breadcrumb.Separator`).

## JSX Formatting

- Separate sibling components in JSX with a blank line for readability.
