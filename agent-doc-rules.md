# Agent doc rules

Canonical rules for writing per-package agent docs (`AGENTS.md`, auto-loaded by Claude Code via path-walking; `CLAUDE.md` is typically a symlink to it). The goal is a doc that **does not rot**. Code moves, gets renamed, and gets refactored constantly — a doc pinned to today's file names and function signatures is wrong within weeks and actively misleads agents. Architecture changes slowly. Write to the slow layer.

## The one test

> If someone renames a file, moves a folder, renames a function, or changes an argument, would this doc become wrong?

If yes, you wrote the wrong thing. Rewrite it as a rule about the package's **shape and boundaries** instead.

## What an agent doc is for

It answers, for an agent about to touch this package:

- **What is this package responsible for?** Its perimeter — the slice of the system it owns.
- **What does it deliberately NOT do?** The boundaries someone will otherwise be tempted to cross.
- **What are the load-bearing rules?** The architectural constraints that, if violated, break the design or create a class of bug.
- **What's the non-obvious trap?** The gotcha that isn't visible from reading one file.
- **What's the non-standard way to work in it?** A workflow an agent would otherwise get wrong — a codegen step that must be re-run and committed, a catalog that must be re-extracted, a generate-don't-hand-write rule. This is the single most useful thing to write down: tooling that's spelled out gets used; tooling that isn't gets skipped or reinvented.

It is **not** an API reference, a file index, a dependency list, or a changelog. The agent reads the code, the `package.json`, and the git history for those in one glance, and those sources never go stale because they _are_ the source. Don't restate the tech stack (it's in `package.json`) or the directory tree (a folder scan shows it) — spend your lines on what those _don't_ reveal: intent, boundaries, traps, and non-standard workflow.

## Rules

### 1. Stay inside your own package

Describe only the package the doc lives in. Don't document another package's internals, entities, or APIs — that knowledge belongs in _that_ package's doc and will rot here. When a boundary touches another area, state it as **your** package's rule, phrased by role, not by naming the other package's files or symbols. (e.g. "this package must not be depended on by backend code" — not "don't import `@scope/foo-domain/src/x`".)

Equally, **don't describe the package's consumers or what they do.** The doc is about this package's own perimeter, internals, and rules — not about who calls it or how. "The web and mobile apps wire this in and own the navigation" is the consumers' story; it rots independently of this package and isn't this doc's job. Phrase boundaries as the package's own constraints ("UX and navigation are out of scope"), and refer to the package's reach by the **runtimes/platforms it targets** (browser, native, server) rather than by naming consumer apps.

### 2. No paths, filenames, function names, or arguments

Do not name source file paths, folders, specific functions/methods and their arguments, class/entity names, endpoint routes, cron class names, env-var lists, or ticket IDs. These are exactly the things that move and get renamed. State the **rule or pattern** they embody instead.

- ❌ "`resolveFileClassifiedNextSteps()` in `domain/services/next-steps-resolver.ts` maps classification → hints."
- ✅ "File-classification hints are resolved in one place in the domain layer; add new hint types there rather than branching in callers."
- ❌ "`POST /protected/biomarker-results/visit/:visitUuid/reprocess` rejects CANCELLED/SCHEDULED visits."
- ✅ "Admin reprocessing is gated by visit status and only re-derives the explicitly named computed values, never the rest."

Naming a **pattern, convention, or architectural concept** is fine and encouraged — those are stable: CQRS, repository pattern, aggregate root, railway-oriented results, the `.browser`/`.native` platform-split suffix convention, "one subpath export per helper". Naming a build/config convention that rarely moves is fine when it carries a real rule.

**No directory maps.** Don't list a package's folders — an agent discovers structure by scanning far more reliably than a hand-kept map stays current. The one exception is the **repo root**, where a brief top-level map (what `apps/`, `libs/`, `packages/`, `tools/` mean and the layering inside them) earns its place because it encodes an organizing _convention_, not just a list of folders.

### 3. Describe the feature, not what implements it

Talk about the **capability** the package provides, not the third-party tool or the specific in-house construct behind it. Say "authentication", not "Clerk"; "analytics", not "PostHog"; "the generated API client", not the codegen tool's name. The vendor and the implementation are swappable details — the product capability is the stable thing, and it's what the package actually owns. Name a vendor **only** when the rule is specifically about that vendor being a swappable detail confined behind the package's contract (e.g. "raw vendor error messages must not leak to users") — and even then, lead with the capability.

### 4. Architecture over inventory

Lead with the package's responsibility in one or two lines. Then explain its internal shape as _principles_ ("hooks stay thin; UX orchestration is out of scope"), not as a list of what currently exists. If you find yourself writing a table of entities, services, or endpoints, stop — that's inventory, and inventory is the code's job.

### 5. Always include Do / Don't

Every doc carries a **Do / Don't** section. These are the highest-value lines: they encode decisions a fresh agent can't infer and would otherwise get wrong. Each should be a rule about shape or boundaries, not about a specific symbol.

### 6. Say what the package does NOT own

A short "what this does NOT own" section prevents the most common mistake: putting logic in this package that belongs elsewhere. List the responsibilities that are out of scope and stop there — **don't say where they live instead.** Pointing at another package, layer, or consumer creates a second thing that rots and pulls the doc outside its own perimeter. Naming the responsibility is enough for an agent to know not to put it here.

### 7. Capture non-standard workflow; skip the discoverable

Do write down a **non-standard workflow** — a codegen step that must be re-run and its artifact committed, an i18n catalog that must be re-extracted and committed, a "change the source of truth and generate, never hand-write" rule. These aren't visible in `package.json` and getting them wrong breaks the build; phrase them as a Do/Don't rather than a transcribed command. Don't add a generic Commands/Testing section for standard scripts (they're in `package.json`), and don't paste code — describe the pattern in words, with at most a tiny convention-level snippet when prose genuinely can't carry it.

### 8. Keep it short

Brevity is a feature: a short doc is read and stays current; a long one rots and gets skipped. If a section isn't load-bearing, cut it.

## Shape to follow

```markdown
# <Human Name of the Package>

<One or two lines: what this package is responsible for, and its defining constraint.>

## Architecture

- <Principle about the package's internal shape — phrased so a rename can't falsify it.>
- <Boundary / data-flow rule, by role.>
- <The non-obvious design decision and why it's that way.>

## Do / Don't

- DO <rule about shape or boundary>
- DO <rule>
- DON'T <the boundary someone will be tempted to cross, and why it matters>
- DON'T <anti-pattern>

## What this does NOT own

- <Responsibility that is out of scope>
- <Responsibility that is out of scope>
```

A good worked example is a package doc with a tight perimeter statement, architecture as principles, concrete Do/Don'ts, and an explicit "what this does NOT own" — with essentially nothing in it that a refactor could falsify.

## When to update

Update a package's doc when its **responsibility, boundaries, or load-bearing rules** change — a new architectural pattern, a moved boundary, a new class of trap. Do **not** update it for renames, new functions, or new endpoints: if the doc was written correctly, those don't affect it. If a routine code change forces a doc edit, the doc was too specific — fix the doc to be about the rule, not the symbol.
