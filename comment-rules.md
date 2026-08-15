# Comment rules

Canonical rules for every comment you write or change. Language-agnostic; applies to backend, frontend, mobile, AI, and data code alike.

A comment is a liability, not a free win. A comment that is wrong, stale, or describes things outside the code it sits on is _worse_ than no comment — the reader trusts it, and it rots the moment the world around it moves. By trying to help, a careless comment hurts the outcome.

## First, try to delete the need for the comment

Before writing a comment, challenge the code. If a comment would explain _how_ the code works, that is a signal the code is unclear — rename, restructure, or split it so it explains itself. Reach for a comment only for what code genuinely cannot express.

## What a comment may say

**A comment describes the code it annotates, as it stands today.** Its only valid subject is the symbol it sits on.

Explain a non-obvious _why_ only when it constrains _this_ code — an invariant, a gotcha, a rationale a future editor needs to change this line safely. Pitch it at a different altitude than the code: higher (intent) or lower (precision), never the same level (which just restates the code). Never explain the system around it — other files, services, or libraries.

## Form

When a comment is warranted on a function, class, method, or constant, prefer a doc block (e.g. TSDoc `/** */`) above the signature over a plain inline comment — doc blocks surface in editor hovers. Keep it to one to three sentences. Do not restate already-typed parameters; the types are the contract — describe semantics only when they are genuinely unclear from the name.

## What a comment must never do

- **Reference the change that introduced it.** No "No more X", "we don't do this anymore", "previously…", "now that…". The comment must read correctly years from now with zero memory of this PR.
- **Name a vendor or another library's internals.** Refer to the capability, not the SDK behind it — the vendor is a swappable detail behind its contract.
- **Describe where or how the symbol is used.** Call sites move; describe what _this_ code does, not who calls it or what fires elsewhere.
- **Name foreign symbols, events, files, or endpoints.** Reference only the thing being annotated.
- **State what the code does _not_ do.** State only the positive fact.

## Worked example

```ts
// ✅ Best — the name says it; no comment needed.
export const reportConnectSuccess = (provider) => { ... }

// ✅ Acceptable — states only this code's own behavior, when the scope is
//    genuinely non-obvious.
/** Reports the client-side connect outcome only. */
export const reportConnectSuccess = (provider) => { ... }

// ❌ Bad — verbose, leaks the vendor, names foreign events and endpoints, and
//    describes work done elsewhere.
// PostHog connect analytics fire server-side (`wearable_connecting` on the
// connect-init endpoints, `wearable_connected` on the webhook); the lib only
// emits the observability signal for the client-side connect outcome.
export const reportConnectSuccess = (provider) => { ... }
```

## Further reading

- [A Philosophy of Software Design — John Ousterhout](https://milkov.tech/assets/psd.pdf) — a good comment lives at a different _level of abstraction_ than the code.
- [Code Tells You How, Comments Tell You Why](https://blog.codinghorror.com/code-tells-you-how-comments-tell-you-why/)
- [Coding Without Comments](https://blog.codinghorror.com/coding-without-comments/) — when a comment is a smell pointing at code that should be rewritten.
