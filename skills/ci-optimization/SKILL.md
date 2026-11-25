---
name: ci-optimization
description: Investigate and benchmark slow or costly CI, or decide what to test when writing or reviewing a CI workflow or script.
---

# Optimize CI

For a workflow test review, go directly to [Choose what to test](#choose-what-to-test). For performance work, start with real runs.

## Start with real runs

1. Check existing measurements, issues, and PRs. Find prior experiments and identify what has changed enough to justify repeating one.
2. Compare recent runs for similar PRs. Find the last required check to finish and the step holding it up. Distinguish runner queue time, setup, execution, and reporting.
3. Trace the decision to the workflow. Identify the exact path or dependency that triggered a job. Support timing claims with step durations and links to run logs.

Set the target before choosing an experiment, such as p95 time to the required verdict or monthly runner cost. Measure verdict time and total runner minutes separately. For latency, report p50 and p95 with the population, period, and included outcomes. Treat missing telemetry as unknown. Check whether the mix of PRs changed before attributing a dashboard trend to an optimization.

When failures or retries drive the wait, measure first-attempt failure rate, pass-on-retry rate, and minutes spent rerunning. Compare attempts on the same revision and keep the original failure visible. Classify confirmed regressions, intermittent failures, runner failures, and unknowns separately. [Google's experience with flaky tests](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html)

## Pick the smallest useful experiment

- **Avoid unnecessary work.** Look for broad triggers, duplicate steps, and results that can be reused. Verify a change that should trigger the check and one that can safely skip it.
- **Cancel superseded PR runs.** Measure runner minutes spent on an earlier revision after a new commit lands. If cancellation would help, cancel older runs of the same workflow for that PR and verify the latest revision receives every required verdict.
- **Keep tests that catch regressions.** Name the behavior and a realistic bug that would fail the test. Consolidate duplicates around the strongest test. When practical, introduce the bug in a controlled experiment and check that the retained test catches it.
- **Reuse valid results.** Before narrowing a suite, check whether its full result is reusable. Every required check needs a verdict on the merge candidate. Reuse a trusted passing result only when all inputs to that check match the candidate, including transitive dependencies, test configuration, and runtime. Otherwise run the check. Verify a cache hit with an unrelated change (e.g., CSS for an API suite) and a miss with a changed input (e.g., a shared API schema).
- **Trace slow setup across steps.** Time checkout, cache transfer and extraction, and service startup at normal concurrency. If a downstream step slows after a large restore, check disk and network load. Measure warm restores and cold misses, including upload cost, against rebuilding. Consider reusing a schema or build artifact keyed to its inputs. [Shopify's fast CI project](https://shopify.engineering/faster-shopify-ci)
- **Fetch what each job consumes.** Count repeated downloads of the same revision across the job matrix. A diff-only job can use the provider's exact base-to-head change list. Use a checkout with the paths and history the job actually reads, and fall back to the complete diff when the API result is incomplete. [Anthropic on avoiding checkouts](https://www.anthropic.com/research/redesigning-source-control) · [OpenAI on concurrent Git fetches](https://openai.com/index/scaling-git-at-openai/)
- **Surface failures sooner.** If red feedback is the problem, benchmark reordering checks against time to the first actionable failure while keeping the required test inventory intact. Check time to green too. [Shopify's test prioritization experiment](https://shopify.engineering/test-budget-time-constrained-ci-feedback)
- **Size and balance the work that remains.** Measure imports, test execution, and resource saturation before changing the runner, worker count, or shards. When shards finish unevenly, balance them using per-file timings from full runs on the default branch.

## Choose what to test

Name the failure a developer or downstream job would observe. If the normal PR run exercises that path and reliably exposes the failure, that run is enough. Add a focused test for a decision CI could silently get wrong.

- Exercise the entry point CI uses. Feed changed paths to the real selector and check which jobs it selects, or inspect the artifact produced by a release build. To check that warnings block a merge, give the repository's typecheck command a warning-only fixture and assert that it fails. Adding the warning flag in the test itself would hide its removal from CI.
- Read the workflow configuration directly when a separate requirement defines the expected value. For example, compare the oldest runtime in the matrix with the minimum the package promises to support. [Shopify's CI matrix test](https://github.com/Shopify/job-iteration/blob/54661e3b19e6da34f46cefa2dcde06a5cf81d2f0/test/ci_matrix_test.rb#L7-L47)
- Drop assertions that only repeat a command line or recheck a pinned tool's built-in behavior. A test of the typecheck verdict should still pass if someone reorders equivalent flags or changes worker count.

## Verify changes to test selection

Freeze the proposed selection before observing outcomes, then run the full suite on the same revision. Compare how many confirmed faulty revisions would still be blocked, how many would be missed, and how much work would be avoided. Count a revision as caught if at least one selected test would report the regression. Report intermittent failures separately and give the number of faulty revisions observed. Run the full suite when selection inputs are missing or ambiguous. [Meta's predictive test selection study](https://arxiv.org/abs/1810.05286)

Limit selection to PR feedback. Account for the full suite on the merge candidate through execution or valid cached results. In a controlled trial, verify that a regression missed by the PR selector still blocks the merge.

## Investigate the merge queue when it dominates

Measure queue wait after approval, time spent validating the combined merge candidate, and time lost to invalidated or rebuilt groups. Compare total runner minutes and merge throughput when changing batch size or concurrency. Preserve required checks on the revision each policy is meant to validate. Check whether a failing PR causes unrelated PRs to rerun. [GitHub's merge queue rollout](https://github.blog/engineering/engineering-principles/how-github-uses-merge-queue-to-ship-hundreds-of-changes-every-day/)

## Measure and decide

Compare baseline and variant on the same code. Keep test inventory, runner class, worker count, coverage mode, and cache conditions fixed except for the variable under test. When replacing a tool, run both on the same known failures and list any diagnostics or tests the replacement misses. For sharding, verify the expected test identities by file, project, and runtime. Each identity should run exactly once per variant. Compare the longest shard and total runner time.

If one outlier drives the result, compare the same files across variants. A few slow files give you specific tests to investigate. A slowdown across most files warrants another paired comparison with fresh runners. Keep the outlier in the report.

Report the before-and-after numbers against the target, the cause of the slowdown, and the evidence for equivalent coverage. When runner rates change, use measured usage and the applicable rates to estimate the monthly cost difference. Label estimates separately. When implementation is requested, open a focused PR if the gain holds and the required checks stay covered. Otherwise, record the result and what evidence would justify revisiting it.

The original case study is [Making OpenClaw CI faster and 95% cheaper](https://vincent.build/openclaw-ci-cost-reduction/).
