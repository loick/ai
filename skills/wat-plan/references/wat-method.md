# The WAT method

WAT (Workflows, Agents, Tools) separates concerns so **probabilistic AI handles reasoning while deterministic code handles execution** — which is what makes an AI system reliable instead of impressively-wrong. Full version: https://github.com/loick/ai/blob/main/ai-manifesto/WAT.md

## Why separate the layers

Chain enough probabilistic steps and reliability decays fast — five 90%-accurate steps compound to roughly 59% success. Offload each deterministic step to code that's 100% repeatable, and spend the reasoning budget only where judgment earns its keep. The intuition: get the model out of the parts that don't need it.

## The three layers

- **Workflows — specify.** Plain-language SOPs: objective, inputs, which tools to use, outputs, edge cases. This is where acceptance criteria live. A workflow that doesn't say how you'll know it worked cannot be verified.
- **Agents — orchestrate + verify.** The coordinator: reads the workflow, runs tools in order, handles failures, asks when genuinely unsure, and checks its output against the acceptance criteria before handing off. It doesn't improvise what a tool should do.
- **Tools — execute deterministically.** Scripts that do the actual work: API calls, transforms, file and data operations. Consistent, testable, fast. Verification tools live here too — anything whose output is a clean pass/fail is a tool, not a judgment call.

## Agent modality

An agent runs in one of three modes, and which one matters as much as what it does:

- **Interactive (synchronous)** — a human is present and in the loop; foreground, one active task.
- **Asynchronous (background)** — fires and reports; runs unattended, surfacing on completion or when blocked.
- **Scheduled / event-triggered** — invoked by a clock or an event, not a person; residual judgment only, or none.

The direction of travel is *down* that list: as a task becomes understood and repeatable, move it toward scheduled — taking human presence and model reasoning out of each run.

## Where verify lives

Verification isn't a fourth layer; it has the same shape as the work, across three tiers:

- **Deterministic (cheapest, first)** — values in range, links resolve, schema valid, tests pass → a **tool**.
- **Judgment** — does the output meet the workflow's acceptance criteria? → the **agent**.
- **Human (last gate, exceptions only)** — "is this the outcome I actually wanted?" → you.

Push everything objective down into tools; let the agent judge against the criteria; keep yourself the last gate on what the first two can't clear.

## Loop graduation

Once a task is repeatable and understood, have an agent build the deterministic tool / scheduled job, then remove the agent from the hot path. Push what you can to tools; keep the agent only for residual judgment — aim for *less* model in the loop, not zero. Graduated jobs must stay observable and able to escalate back to an agent or human when their assumptions break: a silent broken cron is worse than no automation. And no evaluator that catches regressions before a human would means the loop doesn't leave the hot path.

## How to operate

- **Reuse before you build.** Check for an existing tool before writing a new one.
- **Every failure hardens the system.** Read the full error, fix the tool, verify, then update the workflow so the same failure can't recur.
- **Keep workflows current.** They're instructions to preserve and refine, not scratch paper.
