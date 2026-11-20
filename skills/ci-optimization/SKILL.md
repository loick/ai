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

When failures or retries drive the wait, measure first-attempt failure rate, pass-on-retry rate, and minutes spent rerunning. Compare attempts on the same revision and keep the original failure visible. Classify confirmed regressions, intermittent failures, runner failures, and unknowns separately. [Google's experience with flaky tests](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html)

## Pick the smallest useful experiment

- **Avoid unnecessary work.** Look for broad triggers, duplicate steps, and results that can be reused. Verify a change that should trigger the check and one that can safely skip it.
- **Keep tests that catch regressions.** Name the behavior and a realistic bug that would fail the test. Consolidate duplicates around the strongest test. When practical, introduce the bug in a controlled experiment and check that the retained test catches it.
- **Reuse valid results.** Before narrowing a suite, check whether its full result is reusable when the effective inputs match. Verify an expected cache hit and a miss after changing a real input.
- **Trace slow setup across steps.** Time checkout, cache transfer and extraction, and service startup at normal concurrency. If a downstream step slows after a large restore, check disk and network load. Measure warm restores and cold misses, including upload cost, against rebuilding. Consider reusing a schema or build artifact keyed to its inputs. [Shopify's fast CI project](https://shopify.engineering/faster-shopify-ci)
- **Fetch what each job consumes.** Count repeated downloads of the same revision across the job matrix. A diff-only job can use the provider's exact base-to-head change list. Use a checkout with the paths and history the job actually reads, and fall back to the complete diff when the API result is incomplete. [Anthropic on avoiding checkouts](https://www.anthropic.com/research/redesigning-source-control) · [OpenAI on concurrent Git fetches](https://openai.com/index/scaling-git-at-openai/)
- **Surface failures sooner.** If red feedback is the problem, benchmark reordering checks against time to the first actionable failure while keeping the required test inventory intact. Check time to green too. [Shopify's test prioritization experiment](https://shopify.engineering/test-budget-time-constrained-ci-feedback)
- **Size and balance the work that remains.** Measure imports, test execution, and resource saturation before changing the runner, worker count, or shards.

## Verify changes to test selection

Freeze the proposed selection before observing outcomes, then run the full suite on the same revision. Compare how many confirmed faulty revisions would still be blocked, how many would be missed, and how much work would be avoided. Count a revision as caught if at least one selected test would report the regression. Report intermittent failures separately and give the number of faulty revisions observed. Run the full suite when selection inputs are missing or ambiguous. [Meta's predictive test selection study](https://arxiv.org/abs/1810.05286)

## Investigate the merge queue when it dominates

Measure queue wait after approval, time spent validating the combined merge candidate, and time lost to invalidated or rebuilt groups. Compare total runner minutes and merge throughput when changing batch size or concurrency. Preserve required checks on the revision each policy is meant to validate. Check whether a failing PR causes unrelated PRs to rerun. [GitHub's merge queue rollout](https://github.blog/engineering/engineering-principles/how-github-uses-merge-queue-to-ship-hundreds-of-changes-every-day/)

## Measure and decide

Run the baseline and variant against the same code with the same test inventory, runner class, worker count, coverage mode, and cache conditions. Change one variable at a time. For sharding, verify the expected test identities by file, project, and runtime. Each identity should run exactly once per variant. Compare the longest shard and total runner time.

If one outlier drives the result, compare the same files across variants. A few slow files give you specific tests to investigate. A slowdown across most files warrants another paired comparison with fresh runners. Keep the outlier in the report.

Report what was slow, why the proposed change should help, how you verified equivalent coverage, and the before-and-after numbers. Label estimated savings separately. When implementation is requested, open a focused PR if the gain holds and the required checks stay covered. Otherwise, record the result and what evidence would justify revisiting it.

The original case study is [Making OpenClaw CI faster and 95% cheaper](https://vincent.build/openclaw-ci-cost-reduction/).
