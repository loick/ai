---
name: ci-optimization
description: Investigate slow or costly CI using real workflow runs, benchmark a candidate change, and decide whether it merits a PR.
---

# Optimize CI

## Start with real runs

1. Check existing measurements, issues, and PRs. Find prior experiments and identify what has changed enough to justify repeating one.
2. Compare recent runs for similar PRs. Find the last required check to finish and the step holding it up. Distinguish runner queue time, setup, execution, and reporting.
3. Trace the decision to the workflow. Identify the exact path or dependency that triggered a job. Support timing claims with step durations and links to run logs.

Measure time to the required verdict and total runner minutes separately. For p50 or p90, state the population, period, and included outcomes. Treat missing telemetry as unknown. Check whether the mix of PRs changed before attributing a dashboard trend to an optimization.

## Pick the smallest useful experiment

- **Avoid unnecessary work.** Look for broad triggers, duplicate steps, and results that can be reused. Verify a change that should trigger the check and one that can safely skip it.
- **Keep tests that catch regressions.** Name the behavior and a realistic bug that would fail the test. Consolidate duplicates around the strongest test. When practical, introduce the bug in a controlled experiment and check that the retained test catches it.
- **Reuse valid results.** Before narrowing a suite, check whether its full result is reusable when the effective inputs match. Verify an expected cache hit and a miss after changing a real input.
- **Speed up the remaining work.** Measure setup, checkout, imports, and test execution before changing the runner, worker count, or shards. When test selection is uncertain, record the proposed selection while the full suite runs and compare it with the observed outcomes. Run the full suite when selection inputs are missing or ambiguous.

## Measure and decide

Run the baseline and variant against the same code with the same test inventory, runner class, worker count, coverage mode, and cache conditions. Change one variable at a time. For sharding, verify the expected test identities by file, project, and runtime. Each identity should run exactly once per variant. Compare the longest shard and total runner time.

If one outlier drives the result, compare the same files across variants. A few slow files give you specific tests to investigate. A slowdown across most files warrants another paired comparison with fresh runners. Keep the outlier in the report.

Report what was slow, why the proposed change should help, how you verified equivalent coverage, and the before-and-after numbers. Label estimated savings separately. When implementation is requested, open a focused PR if the gain holds and the required checks stay covered. Otherwise, record the result and what evidence would justify revisiting it.

Source: [How we cut OpenClaw's CI compute cost](https://vincent.build/openclaw-ci-cost-reduction/).
