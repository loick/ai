---
name: wat-plan
description: >-
  Plans a repeatable task the WAT way — decomposes it into Workflows (the SOP + acceptance criteria), Tools (deterministic execution), and an Agent (residual judgment + its modality), with verification tiers and a starter eval plan. A design assistant that teaches the method as it runs and produces a design spec, not code. Use when structuring an automation, agent, or recurring process, deciding what to make deterministic vs leave to the model, or graduating a repeated task out of an agent's hands. Triggers: "plan this the WAT way", "decompose into workflows/agents/tools", "design this automation", "how should I structure this agent", "graduate this loop", "wat plan".
metadata:
  domain: workflow
  tags: "wat, workflow, agents, tools, automation, planning"
  consumers: "claude-code"
---

# WAT Plan

Turn a repeatable task into a WAT design: **Workflows** specify, an **Agent** orchestrates and verifies, **Tools** execute deterministically. The point is to get the model out of the parts that don't need it, so the system is reliable instead of impressively-wrong.

This skill produces a **design spec, not code**. It teaches the method as it goes, so the plan and the reasoning behind it travel together.

## When to use

- Structuring a new automation, agent, or recurring workflow
- Deciding which steps to make deterministic tools vs leave to model judgment
- Graduating a task you now do repeatedly out of an agent's hands into a tool or scheduled job
- Any time "how should I build this agent/pipeline?" comes up

## Method

Read `references/wat-method.md` first — the self-contained rubric (the three layers, where verification lives, agent modalities, loop graduation). Judge the task against it; link the full manifesto for depth: https://github.com/loick/ai/blob/main/ai-manifesto/WAT.md

Surface the method as you work — name the layer you're placing each step in, so the user learns WAT by watching their own task get decomposed, not by reading a doc.

## What to produce

Interview the user for what you can't infer — don't invent the task's details. Then draft:

1. **Workflow (the SOP).** Objective, required inputs, which tools to use, expected outputs, edge cases — and explicit **acceptance criteria**: how you'll know it worked. A workflow with no acceptance criteria can't be verified; don't hand-wave this one.
2. **Tools vs agent.** Walk each step and place it: a deterministic **tool** (API call, transform, validator — anything with a clean pass/fail) or the **agent's residual judgment** (decisions that genuinely need a model). Push everything objective down into tools; keep the agent for what's actually left.
3. **Agent modality.** Interactive (human present), async/background (fires and reports), or scheduled/event-triggered (no per-run agent). Note the graduation direction: as the task becomes understood, it moves down that list — less human presence and less model per run.
4. **Verification tiers.** Deterministic (a tool: values in range, schema valid, tests pass) → judgment (the agent, against the acceptance criteria) → human (last gate, exceptions only). Put everything objective in the cheapest tier.
5. **Starter eval plan.** Deterministic evals (tool-call checks, forbidden-keyword, error-absence) + one LLM-as-judge for the fuzzy criteria + a seed dataset drawn from real inputs and recent failures. No evaluator that catches regressions before a human would → the loop doesn't leave the hot path.

## How to work

- **Reuse before you build.** Check for an existing tool before proposing a new one.
- **Be honest about the residue.** Name what stays judgment and can't be made deterministic — don't dress a fuzzy step up as a tool.
- **Match rigidity to the task.** A reproducible job (release, migration) wants a tight, executable SOP; a judgment task wants goals and constraints, not step-by-step.

## Output

Present the spec in chat. Offer to save it to a file the user names — don't force a path or location.

## What this does not own

- Writing the tool code or scaffolding files — this is the design, not the implementation.
- Standing up infrastructure, schedulers, or eval harnesses — it plans them.
