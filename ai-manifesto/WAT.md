# WAT (Workflows, Agents, Tools)

WAT is the architecture that makes the [Manifesto](./MANIFESTO.md) buildable. It separates concerns so that **probabilistic AI handles reasoning while deterministic code handles execution**, which is what makes an AI system reliable instead of impressively-wrong.

> **Source & attribution:** the core Workflows / Agents / Tools split comes from Nate Herk and the [AI Automation Society](https://www.skool.com/ai-automation-society/about) community — a practitioner's framework, not a formal standard. This write-up is *inspired by* it but adapts and extends it: the way verification is distributed across the three layers, and the agent-modality axis below, are our own additions, not part of the original.

---

## Why separate the layers

When AI handles every step directly, errors compound *downward*. To illustrate: if each step were 90% accurate and errors were independent, five steps would compound to **0.9⁵ ≈ 59%** success. The real numbers vary (errors aren't truly independent, and 90% is a stand-in) but the direction holds: chain enough probabilistic steps and reliability decays fast. Offload each deterministic step to code that's 100% repeatable, and you keep your reasoning budget for the decisions where judgment actually earns its keep.

That's the intuition behind WAT: **get the model out of the parts that don't need it.**

## The three layers

**Workflows: the instructions (specify).**
Plain-language SOPs, written the way you'd brief a teammate. Each defines the objective, the required inputs, which tools to use, the expected outputs, and how to handle edge cases. This is your **specify** layer, and it's where your acceptance criteria live. *A workflow that doesn't say how you'll know it worked cannot be verified.*

**Agents: the decision-maker (orchestrate + verify).**
The intelligent coordinator. It reads the relevant workflow, runs the tools in the right order, handles failures, asks when genuinely unsure, and checks its own output against the workflow's acceptance criteria before handing anything off. It connects intent to execution without trying to do everything itself. When something needs pulling from a system, the agent doesn't improvise it; it reaches for the tool built for that.

An agent runs in one of three *modalities*, and which one matters as much as what the agent does:

- **Interactive (synchronous):** a human is present and in the loop; it's the foreground, one-active-task mode.
- **Asynchronous (background):** fires and reports — runs unattended, surfacing on completion or when it's blocked.
- **Scheduled / event-triggered:** invoked by a clock or an event rather than a person; residual judgment only, or none at all. This is the end state of a graduated loop.

The direction of travel is *down* that list: as a job becomes understood and repeatable, you move it from interactive toward scheduled — taking human presence and model reasoning out of each run. That's what "graduating the loop" below actually does.

**Tools: the execution (do the work, deterministically).**
Scripts that do the actual work: API calls, transformations, file and data operations. Consistent, testable, fast. Verification tools live here too (a link-checker, a schema validator, a test): anything whose output is a clean pass/fail is a tool, not a judgment call.

## Where "verify" lives

Verification isn't a fourth layer. It has the **same shape as the work**, distributed across all three:

| Tier | What it checks | Who does it |
| --- | --- | --- |
| **Deterministic** (cheapest, first) | Facts a human can't reliably eyeball: values in range, links resolve, schema valid, tests pass | a **Tool** |
| **Judgment** | Does the output meet the workflow's declared acceptance criteria? | the **Agent** |
| **Human** (last gate, exceptions only) | "Is this the outcome I actually wanted?" | you |

Push everything objective down into tools; let the agent judge against the criteria; keep yourself as the last gate on what the first two tiers couldn't clear. This holds whether the output is a pull request or a newsletter; only *which tier does the heavy lifting* changes.

## How to operate

- **Reuse before you build.** Check for an existing tool before writing a new one. Only create when nothing fits.
- **Every failure hardens the system.** Read the full error, fix the tool, verify the fix, then update the workflow so the same failure can't recur. A broken run is a chance to make the machine more robust, not a one-off patch.
- **Keep workflows current.** They evolve as you learn better methods and hit new constraints. Don't overwrite them casually; they're instructions to preserve and refine, not scratch paper.
- **Graduate the loop.** Once a job is repeatable and understood, it belongs in a tool or a scheduled run, not in an agent's hands each time. Keep it observable, and let it escalate back to an agent when its assumptions break.

## What goes where

- **Deliverables** land in the place they'll actually be used (a shared doc, a PR, a dashboard), not in a local scratch folder.
- **Intermediates** are disposable; anything regenerable stays local and temporary.
- **Secrets** live in one place (env), never scattered through the tools.
