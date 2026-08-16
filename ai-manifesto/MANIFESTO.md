# AI Manifesto

**Your job is the whole loop: specify, orchestrate, verify.**

The agent only takes the middle. Both ends stay yours, and they're the ones people quietly drop. Handing a task to an agent doesn't shrink your job; it moves it up a level. You say what's needed, you direct the work, and you prove the result is right. Skip the first and you get a confident answer to the wrong question. Skip the last and you ship whatever the agent felt like.

This is how I recommend using AI, for engineers and non-engineers alike. It's a mindset, not a rulebook. The concrete numbers, gates, and mechanics live in the **Playbook**; the architecture that makes it buildable lives in **WAT**.

---

## Where your effort goes

**1. Spend more of your effort on intent and verification than on implementation.**
Writing the thing is the cheap, increasingly-commoditized part. The expensive, human work is on either side of it: knowing what to ask for and iterating on it, then proving the result is right (reviewing, fixing, iterating again). That's where your time and attention should concentrate. Implementation still needs you; it just shouldn't be where most of your effort goes. And good intent isn't reasoning in a vacuum: pull production signal into the spec (traces, error rates, real usage) so you're specifying against reality, not assumptions. As agents get faster, spec quality becomes the ceiling, not implementation speed: a factory that builds faster than you can specify sits idle. Raise the ceiling by drafting specs from real artifacts (meeting transcripts, past PRs, error traces) for a human to validate, rather than writing them cold.

**2. Verify against criteria you set in advance.**
You cannot verify what you never specified. "Looks right" is not verification, it's a vibe. Decide what "done and correct" means *before* the work, then check against it. Push everything objective into automated checks (they catch what human eyes can't), let the agent judge the rest against your criteria, and stay the last gate on anything consequential. Where you let automation approve something on its own, that isn't a bypass of your judgment; it's the gate you configured in advance, acting for you. One thing this can't escape: passing your criteria proves you built the thing *right*, not that you asked for the right thing. A check only ever confirms conformance to the spec, never that the spec was correct. That question is answered *before* you build, by a second mind challenging the approach, not by the verification loop after.

**3. Be the first reviewer of your own output, and let review be layered.**
Never make someone else your first line of defense. The order is always you → AI → others: your work passes your own review, then an AI review, before another person spends a minute on it, and that's a matter of respect, not just efficiency. Handing someone work you haven't read and validated yourself (especially work you didn't even write) asks them to do the reading you skipped. Give AI clear criteria for what it may approve on its own; everything else, and the final judgment, stays human. Human attention is the scarcest thing you have; don't spend someone else's on what a check, an agent, or your own eyes could have caught. And mind the trap unique to AI output: it reads as plausible, so a glance passes it, which means "looks fine" hides debt a reviewer would catch in hand-written code. That plausibility is exactly why self-review and evidence matter more, not less.

**4. You own what you ship, even when an agent made it.**
Creating it makes it yours: whether you wrote it, a loop produced it, or an agent did, you're responsible for getting it right, for addressing what review surfaces, and for landing it. "The AI wrote it" is never an excuse; an agent's output under your name is your output. Ownership doesn't transfer to the tool.

## Throughput

**5. Parallelism flipped from vice to virtue.**
Before AI, doing many things at once meant losing focus: the tools weren't built for it and neither were we. Now it's the opposite. Keep **one** active task holding your attention, and send agents wide in the background to prepare future work, investigate, and clear the small stuff. The parallelism happens outside your head, not inside it. But throughput has a ceiling, and it isn't the tooling: it's how much you can actually verify. Every agent you launch is output you'll owe a review, so widen the fan-out only as far as your verification keeps pace. Past that line you aren't parallelizing, you're accumulating unreviewed work, which is the one thing principles 1–3 say you must never do.

**6. Graduate your loops.**
Agents are for the novel; scripts are for the repeated. When you find yourself doing the same thing twice, use an agent to build the deterministic version (a script, a scheduled job) and get the agent out of the hot path. Push every part you *can* to deterministic tools; keep the agent only for the judgment that's genuinely left. A loop is only safe to self-drive once you have an evaluator that catches regressions before a human would; no evaluator, no leaving the hot path. Graduated jobs still need eyes: a script has no judgment, so when the world shifts under it, it must be observable and able to escalate back to a human.

## How we coordinate

**7. Work at project altitude.**
Frame what you're trying to achieve and why, not the task-by-task breakdown. How the work gets sliced is the doer's business, human or agent. Tickets are always a **receipt** of the work. They can also be an order, whether the engineer wrote it for their own planning or it came in from elsewhere (a reported bug, a request). What's not handed down is the *breakdown*: how the work gets sliced and sequenced is the doer's call, not a plan prescribed from above. Grooming to that depth is slow and low-value anyway: two engineers handed the same goal will produce different tickets and build it different ways, so there's no single "right" decomposition worth dictating. A rolling re-estimate of the project beats a false percentage-complete every time.

**8. Never go solo on anything that matters.**
At least two people stay context-aware on a project: for the bus factor, and because a second mind challenges the approach before it's built, not after. A fleet of agents doesn't count: working alone with ten agents is still working alone (bus factor of one, and nothing questioning your thinking). The second person can engage lightly (challenge the plan at kickoff, review the design) but they engage *early*, not cold at the end.

**9. If you manage: manage projects, not tasks.**
Frame the goal and estimate roughly (smaller projects iterate better). Review the design doc where architecture is at stake, not to approve an engineer's work but to keep the technical approach coherent with what the rest of the team is building: catching divergence, cross-system impact, and duplicated effort before they're baked in. Past that, let the engineer own the how. Don't refine tickets or slice work for people; trust them to raise blockers, and check in on outcomes, not activity.

## Leverage and judgment

**10. Literacy is not optional.**
Skills, MCP, agents, tools: everyone touching AI needs the working knowledge, engineer or not. You can't orchestrate what you don't understand.

**11. Promote the capabilities that help everyone.**
Personal skills and MCPs are fine: keep the ones that only fit your own workflow. But the moment a skill, MCP, or agent would help others, promote it to the org level (a shared plugin, a marketplace, the company knowledge base) instead of leaving it in your setup. Otherwise everyone re-solves the same problem five times and drifts five different ways. A capability that could be everyone's shouldn't stay one person's.

**12. Match the model to the task.**
Use the right model for the job: cheap and fast for the mechanical and high-volume, the strongest one you have for judgment, planning, and verification. The most expensive model on a trivial task wastes tokens and often does worse.

**13. Token usage is a conversation, not a scoreboard.**
Tokens are not a measure of success, same as commits and lines of code before them. Burning a lot of tokens doesn't mean you're effective; it can mean the opposite: the wrong model on the wrong task. Burning almost none isn't obviously good either; it may mean you're leaving a real productivity opportunity on the table. So the number doesn't rank people; it *starts questions*. Why so high, wrong tool for the job? Why so low, why isn't AI enhancing this workflow? Use it to open a conversation, never to put an engineer in a box.

## Trust and confidentiality

**14. Guard what you feed the models, what they read, and what you grant them.**
The agent is a new surface for old risks. Treat everything you send a model as leaving your perimeter: proprietary code, customer data, and secrets don't belong in a context you don't control — pasting a production export or an API key into a general-purpose assistant is the everyday version of the leak, and "it's only a prompt" is how confidential data becomes someone else's training set. Treat everything the agent *reads* as untrusted input, too: a malicious issue, web page, or tool result can hijack it, so the more power an agent holds (write access, a shell, money or data paths), the less it should act on unvetted content without a human in the way. Mind the rights you grant: an agent inherits whatever access you give it and an unattended loop holds that access around the clock, so scope it to the minimum, and keep regulated data inside its compliance perimeter — every provider, tool, and MCP in the chain is a processor that must clear the same bar, and untrusted partners don't get the data. Every skill, MCP, or tool you install is code running with your access, so vet it like a dependency, not a plugin. Secrets live in one place, never in prompts, logs, or generated code.
