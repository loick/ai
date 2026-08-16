# Playbook

The [Manifesto](./MANIFESTO.md) is the mindset. This is where the numbers, gates, and mechanics live: the tunable dials. Expect these to change as models and tooling improve; the principles won't, these will.

Engineer-facing unless noted.

---

## Contents

- [Parallelism](#parallelism)

**Review & PR flow**
- [Verification & review](#verification--review)
- [Small PRs](#small-prs)
- [How much to delegate](#how-much-to-delegate)
- [AI-approved merges](#ai-approved-merges-when-the-human-is-skipped)
- [The hard floor](#the-hard-floor-always-a-human)
- [PR ownership](#pr-ownership)
- [Pairing (never solo)](#pairing-never-solo)
- [Review SLA](#review-sla)
- [Draft & standby hygiene](#draft--standby-hygiene)
- [Tickets](#tickets)
- [Project forecasting](#project-forecasting-management)

**Security**
- [Security & confidentiality](#security--confidentiality)

**Running agents in production**
- [Loop graduation](#loop-graduation-wat)
- [Agent evals & observability](#agent-evals--observability)
- [Model selection](#model-selection)
- [Shared setup](#shared-setup)

- [Sources & further reading](#sources--further-reading)

---

## Parallelism

- Keep **one active task** holding your focus. Everything else runs in the background.
- Aim for **≥3 background tasks in flight** (investigations, small fixes, prep for future work). This is a rule of thumb (popularized as "3–5 parallel worktrees"), not a quota.
- The ceiling is **your review capacity**, not the tooling. Community rules of thumb put it around ~4–8 concurrent, but treat that as a rough calibration, not a studied limit: when you can't verify the outputs, stop launching more.
- Good background candidates: cleanup, spikes, research, mechanical refactors, small independent bug fixes. Bad candidates: anything needing heavy specification or deep verification, which belong in the foreground.

## Verification & review

The order is always **cheapest first, human last**:

1. **Deterministic checks** (tests, linters, CI, type checks). Anything with a pass/fail answer.
2. **Self-review**: you are the first human to read your own PR. Always. If you didn't read it, why should the reviewer?
3. **AI review**: an automated review pass before another person is involved.
4. **Human review**: the last gate, on what the first three couldn't clear.

Mechanics:
- Most AI review bots only run on **ready** PRs, not drafts. So: self-review → flip draft to ready → AI review → human. Flipping to ready is your signal that *you've* validated it.
- Every workflow / spec must declare its **acceptance criteria** up front: the definition of "done and correct." No criteria, no verification.
- **Give context, proportional to the PR.** Fill the PR template honestly (problem, why-now, plan): a one-line copy fix needs a sentence, a non-trivial change needs the plan. Show it works: screenshot/GIF/video for visual changes, command or test output for behavior. Evidence lets the reviewer confirm in seconds instead of reverse-engineering intent.
- A reviewer may **bounce a PR back** if there's no self-review or no context. That's legitimate and non-hostile, and the review clock pauses until it's fixed. This protects reviewer time.
- **AI code is the dangerous kind to review:** it reads as plausible, so reviewers catch its debt *less* reliably than hand-written debt. Lean harder on self-review and evidence, not less.

## Small PRs

- Target **~400 net added lines**, excluding generated code (lockfiles, schema clients, translation catalogs, dead-code deletion). The bar: a reviewer holds it in ~10–20 min. Up to **600 is acceptable with human review**; beyond that, split it. (Auto-merge uses a stricter cap, see below.)
- Long-lived feature branches are discouraged; they make a small, reviewable PR impossible. For dependent or unfinished work, use **stacked PRs** or **feature flags**.
- A **feature flag is debt, not a free switch**: whoever adds one owns removing it, as part of the same project. Don't leave flags lying around.
- Merging not-yet-used code is fine **with guardrails**: it's inert or behind a flag, the PR explains the plan, it ships with tests that exercise it, and it belongs to an active project.
- **Review capacity doesn't scale with AI's output volume.** When reviewers can't keep pace, shrink the changeset; don't lighten the review. The failure mode (code merging unread) is already common in the wild, not hypothetical.

## How much to delegate

Don't set an agent's autonomy by how smart the model is. Set it by two properties of the *task*:

- **Verifiability**: is there a cheap check that proves the output right, or does it need human judgment?
- **Reversibility**: is a mistake cheap to undo, or irreversible (data loss, money moved, a breach)?

Four levels fall out:

- **Self-driving** (verifiable + reversible): dep bumps, lint, formatting. No gate.
- **Delegate + post-check** (verifiable + costly to undo): most code. AI proposes/merges within the gates below; sample-audit.
- **Human-in-loop** (hard to verify + reversible): agent drafts, a human decides.
- **Human-only** (hard to verify + costly to undo): the hard floor.

Trusting agents more because the models got smarter is like skipping the seatbelt because you bought a nicer car. Capability isn't the axis; verifiability and reversibility are.

## AI-approved merges (when the human is skipped)

Use an AI reviewer that is **independent of the agent that wrote the code**: the author's own model shares its blind spots. Standardize the config company-wide; **the rules carry the safety, the AI carries the judgment within them** (standardizing concentrates the single point of failure, so trust the bounds, not the verdict). For consequential PRs, escalate to a **multi-lens review** (several reviewers with different instructions/models, e.g. a qa-swarm-style pass) before a human sees it. Diversity only counts if the reviewers genuinely differ: identical reviewers share one blind spot, and agents tend to converge on the same wrong call, so N copies of one reviewer is false diversity (cost without coverage). Auto-merge with no human only when **all** hold:

- **Under the size cap** (~400 net lines, excl. generated): this gates *reviewability*, and is deliberately stricter than the human-review target (600) above.
- The AI reviewer **rates it low-risk**.
- It touches **no hard-floor path** (below).
- **No structural tripwire**: doesn't span multiple modules, change a public interface, or touch more than a few files. Requires a human regardless of the "low-risk" rating.
- Deterministic checks are green.

**Size gates reviewability, not safety. Small does not mean safe: a one-line change can require a human.**

## The hard floor: always a human

This is the **hard-to-verify *and* costly-to-undo** quadrant: always human, no matter how small or how confident the AI. The domains below are examples of that quadrant, not an exhaustive list:

- **Data migrations**: a bad one is data loss / downtime, not a revert.
- **Sensitive-data egress**: PHI or user data leaving to any third-party sink (analytics, logging, CRM). A miss is a reportable breach.
- **Money**: billing, credits, payment logic.
- **By content, regardless of size:** authorization/permission logic, money-adjacent math, concurrency/async, destructive or bulk data operations. (Judged by *content*, not file path: a typo in an auth file doesn't need a human; auth *logic* does.)

Enforce it mechanically, not by memory. The dangerous PR is the one whose author doesn't realize it touched a floor:
- A path/pattern-based **required-review gate** on sensitive paths forces a human, overriding AI auto-merge.
- **CODEOWNERS** for routing (it *requests* the owning team; only the required-review rule *blocks*).
- **Sample-audit** a slice of auto-merged PRs to catch a company-wide blind spot or reviewer drift before it bites.

## PR ownership

- **You own your PR end to end**: what goes into it, and when it lands.
- **Approve** is the reviewer's job ("good to go whenever you're ready"); **merge** is the author's ("go now"). Only the author knows the prerequisites are met (a dependent PR, a flag flip, a migration, a last check).
- **Don't commit to or merge a PR you don't own**, human or AI. Pointing your agent at someone else's branch is the same override, and worse: it collides with the context their own in-flight session holds. Comment freely; push only if invited.
- Exceptions (delegation, not override): the author asks you; the author is unreachable, the PR is approved, and it's blocking others (merge and leave a note, baton passed not grabbed); an incident (whoever's driving the fix merges).

## Pairing: never solo

*Pairing*: co-ownership of a project by **at least** two people (never one; more than two is fine).

- **Never solo on a project. Always ≥2 people context-aware.**
- The second person engages **early** (challenging the approach at kickoff, reviewing the architecture/design), *not* parachuting in at review time. Cold discovery in the PR defeats the purpose.
- Your pairing partner is the **default reviewer** and owns the review SLA for that feature; not exclusive, anyone can review as fallback.
- **Precondition:** this needs protected time for context-sharing. If that isn't committed, don't half-adopt; fall back to plain review + strong PR context. A half-committed pairing is *worse* than none: you keep the SLA cost and lose the warm-context benefit.

## Review SLA

- **Reviewing an open PR outranks starting your next task**: an unreviewed PR blocks a teammate.
- First response within **~2h** during overlapping working hours, for small ready PRs. Not "review in the minute"; a full review takes longer.
- Stay reachable; notifications however you like. The rule is responsiveness, not a specific tool.

## Draft & standby hygiene

- A **draft** means "actively building, not ready for review." Not a backlog item, a saved idea, or a parking lot.
- If work won't progress this week, it doesn't belong as an open draft; move it to a tracked issue. The code isn't lost (it's on the branch); reopen when you resume.
- Ask promptly for approval once ready; don't let approved PRs sit unmerged.
- Nudge stale PRs by who holds the ball: inactive drafts (~5 business days) → nudge the author & close; ready-and-waiting → shorter clock, nudge the reviewer / pairing partner.

## Tickets

- **Hard gate:** no PR merges without a **linked, categorized ticket**. Enforced mechanically (branch protection / CI), not by goodwill.
- Tickets are always a **receipt** of the work, created as it lands, filed into the right project (`1 ticket = 1 task`). They can also be an *order* (self-written for planning, or an incoming bug/request); what's never handed down is the task *breakdown*.
- **Automate the receipt:** generate the ticket from PR metadata so the gate costs the engineer ~nothing. Enforcement guarantees the record exists; automation guarantees it's honest (a tedious manual gate just produces junk "misc" tickets that poison your data).
- **Categorize** every ticket (e.g. run vs. build) so the measurement is usable.
- How you *plan* below the ticket is yours (Linear, a Claude session, a PR stack). That's personal organization, not team reporting.

## Project forecasting (management)

- Manage at the **project level**, not the task level. Don't refine or slice tickets for engineers.
- Estimate the project roughly. **Smaller projects iterate better**: bias toward small.
- **Re-forecast the release date on a cadence** (every X days). A rolling re-estimate is honest; a percentage-complete is not, because tickets vary in size and scope always grows at the end, so a % manufactures false deadlines.
- Report progress as **milestone state** (defined → in progress → shipped), not as a percentage.
- For status: a real conversation or a look at done-vs-project beats any dashboard number.

## Security & confidentiality

The agent widens the attack surface: what you send out, what it reads in, and what you let it run. Gate each.

- **Classify the data, then decide the sink.** Know what class a task touches (public / internal / customer-PII / regulated) and which providers and tools are approved for each. Default-deny: a sink not approved for that class doesn't get the data. The everyday leak is mundane — pasting a production database export, a private key, or a customer's records into a general-purpose chat or an unapproved IDE assistant. This is the upstream twin of the egress hard-floor below.
- **Prefer providers that don't train on your inputs**, and check retention and data-residency terms *before* routing real data through them. A seat/enterprise agreement typically carries these guarantees; ad-hoc third-party gateways typically don't, and routing through one can silently strip them.
- **Grant agents and loops least privilege.** An agent inherits whatever access you hand it — scope credentials to the task, prefer read-only, time-box them. A graduated, unattended loop is the sharp case: it holds its access around the clock with no human watching, so its blast radius *is* its standing permissions. Give a loop the narrowest scope that still does the job, and review that scope when the job changes.
- **Keep regulated data inside its compliance perimeter.** When data falls under a regime (PII → GDPR, cardholder → PCI, health → HIPAA and regional equivalents), every provider, tool, and MCP that processes it is a **sub-processor** and must clear the same bar: certification/attestation, a data-processing agreement, an approved hosting region. A partner not certified for that data class doesn't get the data, however convenient the integration. Your compliance perimeter doesn't stop at the agent's edge.
- **Treat everything an agent reads as untrusted input.** Issues, PR descriptions, web pages, tool outputs, and file contents can carry prompt-injection payloads. Scale the gate to the blast radius: the more an agent can do (write access, shell, money/data paths), the less it may act on unvetted content without a human. Pair broad permissions with narrow, trusted inputs.
- **Vet skills, MCP servers, and tools like dependencies, not plugins.** They run with your credentials and see your context. Pin sources, review before install, prefer first-party over unofficial gateways, and re-check on update. A remote skill/MCP list *is* a supply chain.
- **Secrets in one place (env); never in prompts, logs, or generated code.** Scan AI output for hardcoded secrets and the usual vulnerability classes before merge, plausible-looking insecure code is exactly what AI produces most readily (this is why self-review and layered review matter, see above).
- **Egress stays a hard-floor path** (see [The hard floor](#the-hard-floor-always-a-human)): sensitive data leaving to any third-party sink is human-gated regardless of PR size.

## Loop graduation (WAT)

- **Graduation is a shift down the agent-modality ladder,** not just "build a tool": interactive agent (human present) → async/background agent (fires and reports) → scheduled/event-triggered run (no per-run agent). Each rung down removes human presence *and* model reasoning from the hot path. To graduate a loop is to move it one rung once it's repeatable and understood.
- Repeatable loop → have an agent build the deterministic **tool** / **scheduled job**, then remove the agent from the hot path.
- Push what you can to deterministic tools; keep the agent only for residual judgment. Mixed agent+tool is fine; aim for *less* model in the loop, not zero.
- Graduated jobs must stay **observable** and be able to **escalate back to an agent/human** when their assumptions break. A silent broken cron is worse than no automation.
- Watch **maintainability, not just correctness.** AI output drifts toward more code and less reuse, and complexity compounds until it eats the velocity gain. Track complexity/duplication over time as its own gate, alongside "does it still work."
- See [WAT.md](./WAT.md) for the architecture.

## Agent evals & observability

Reviewing PRs says nothing about whether a *graduated* agent (a loop, a cron, a WAT job) still behaves once it runs unattended. Build the evaluator before you trust it:

- **Deterministic evals**: tool-call verification, forbidden-keyword checks, call-count and error-absence. Cheap; run every time.
- **One LLM-as-judge** for the fuzzy criteria (did it satisfy the request? any PII leak?).
- **A dataset** seeded from real inputs + recent bugs; grow it from each new failure.
- **A trace-review ritual**: periodically read real runs to discover evaluators you didn't know you needed.

Graduation rule (the *Graduate your loops* principle): no evaluator that catches regressions before a human would means the agent doesn't leave the hot path.

## Model selection

**Per task:**
- **Cheap/fast models** for mechanical, high-volume, low-stakes work.
- **Strongest model** for judgment, planning, and verification.
- Using a lot of tokens is not a sign of doing it right: the wrong (expensive) model on a trivial task burns tokens *and* does worse. Match the model to the stakes.

**Where to set it (don't rely on discipline):**
- Bake the model into each **agent's definition** (frontmatter `model:`), so the right one is the default: search/explore agents on a cheap model, reviewer/architect agents on the strongest. Set once, forget.
- Override per-call only for exceptions. If you're routinely typing "use the cheap model for this," the agent's default is wrong; fix the definition.
- The biggest lever is **subagent fan-out**: running 5 parallel grunt-work agents on your top model is pure waste. Cheap model for the fan-out, strong model for the synthesis.

**Org-level billing & backend (ops decision, upstream of everything above):**
- **Seat subscription** (team/enterprise): flat per-seat cost. For heavy users this *is* the token optimization, since usage doesn't scale linearly. Optimize inside it with model selection + prompt caching. Don't route around it.
- **Metered API** (pay-per-token): here a router/aggregator can help send trivial work to cheaper models. Only makes sense on metered billing.
- **Routing through a third-party aggregator on top of a seat subscription means paying twice**: the aggregator is metered and bypasses the flat rate you already bought.
- Managed cloud backends (running the models inside your own cloud account) exist mainly for centralized billing, committed spend, and compliance/data-residency, not for cost arbitrage. Prefer officially supported backends over unofficial gateways, which can break tooling features.

## Shared setup

- One shared set of **skills, context, and company knowledge** (via `CLAUDE.md`, a plugin/marketplace, or an internal knowledge base), so a capability one person builds is one the whole team has.
- Everyone touching AI gets the basic literacy: **skills, MCP, agents, tools.** Not optional.
- **Writing a skill (match rigidity to the task):** for judgment tasks, give goals, constraints, and context the agent can't discover, *not* step-by-step procedures; over-specifying strips the intelligence you're paying for. For work that must be reproducible (releases, migrations, benchmarks), do the opposite: an executable procedure with hard gates, fixed contracts, and preflight checks, so every run is identical. Either way, tell agents to check for an existing implementation before writing new; their default is to write fresh, which inflates duplication.
- **Fight skill rot:** put durable structure in the skill, but point to the live source for volatile content (docs, schemas, API specs) instead of embedding it; version skills, give each an owner, keep them synced in CI. A stale skill is worse than none.

## Sources & further reading

The data-backed claims above (the verification gap, quality drift, the delegation gap) draw on, among others. Figures are as reported by each source:

- New Relic, [*2026 State of AI Coding*](https://newrelic.com/resources/report/2026-state-of-ai-coding): teams shipping AI code without line-by-line verification, and rising production incidents.
- Addy Osmani, [*Agentic Code Review*](https://addyosmani.com/blog/agentic-code-review/): Faros AI data across ~22k developers on code churn and defect rates.
- [*More Code, Less Reuse*](https://arxiv.org/abs/2601.21276) (MSR 2026) and [*Speed at the Cost of Quality*](https://arxiv.org/pdf/2511.04427): AI-driven duplication and complexity drift, and why reviewers rate AI code more favorably than its quality warrants.
- Michaela Greiler, [*Code Review Surrender and Exploitation*](https://www.michaelagreiler.com/codereview-surrender-exploitation/): the two ways review breaks under AI volume.
- Anthropic, [agentic coding trends](https://pathmode.io/blog/orchestration-era-needs-intent) (the ~60% use / ~20% full-delegation gap) and Frontier Red Team [multi-agent conformity findings](https://techcrunch.com/2026/08/13/anthropic-set-ai-agents-loose-on-the-same-task-they-started-a-turf-war/).
- LMSYS, [*Agent-Assisted SGLang Development*](https://www.lmsys.org/blog/2026-07-02-agent-assisted-sglang-development): skills as executable procedures with hard gates for reproducible work.
- PostHog, [*Product for Engineers*](https://newsletter.posthog.com/): the delegation matrix, agent evals, and context/skill design.
