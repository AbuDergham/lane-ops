# CI operations

## Facts that bite

- **Draft PRs skip CI.** Make your workflow skip drafts, to save runner time. Mark a PR ready only once it is MERGEABLE.
- **A CONFLICTING PR gets no `pull_request` run at all.** Without a heartbeat check on `mergeable`, a lane can wait a day for CI that never starts.
- **Re-running a run reuses its original merge commit.** If main gained a fix since then (for example a flaky-spec fix), a re-run won't have it: merge main and push instead.
- **Queued jobs keep the runner labels they got at creation.** After changing the routing, cancel and re-run to move them.
- Merge with a script that checks the newest real run on the head commit, not a stale or cancelled one. Optionally make it refuse a PR whose newest green run predates main's head (`02-coordination.md`).

## Runner routing

- Route jobs by PR author with repository variables (for example a JSON map from author to runner label), so each person's jobs go to their own runners or to hosted runners.
- **Never run someone else's jobs on the owner's private runners.** That's a security rule: their code would run on the owner's machine.
- Keep an x86 runner for image builds if the main runners are ARM (or the reverse).
- Keep a small mode script: `remote` (normal), `local` (plan B, when the remote runners are off or saturated), `hosted` (when the owner's PC is off), and `status`.

## Local runners are slower than they look

- On a developer PC with lane stacks running, a PHP test suite that takes 10 minutes on dedicated runners can take more than 30, and hits the job timeout after **every test has passed**. A cancelled job with "N passed" in its log is a timeout, not a failure.
- So: bring lane stacks down while CI runs locally, cap how many local runners run at once, and move back to the remote runners as soon as their queue allows (tell the partner on the channel).
- Cancel your own runs that will fail anyway (for example while main is red), so they don't hold runners.
- **Know which runner ran the failing job** (the runner name in the job) before you diagnose load.
- **Before blaming capacity, check shared helpers.** When many unrelated specs time out together, look first for a shared setup helper the PR changed (for example a signup or checkout step that every spec passes through). If you already blamed the runners on the channel, correct it quickly with INFO.

## Flakes or real failures

1. Find the exact failing test in the job log.
2. If it fails 2 out of 2 on your branch but passes on main's latest push run, it's **yours**.
3. If it fails on main's push run too, it belongs to the **owner of that test**. Post ALERT with the run ID, and offer to fix it.
4. If it fails only at certain hours, it's a **time-of-day dependency** (see below).
5. If it passes on a re-run and fails rarely, treat it as a flake: re-run once, and file a follow-up if it repeats.
6. Don't fix the other lane's spec yourself without an ANSWER.

## Time-of-day tests

- Features such as quiet hours, send windows or business hours make tests fail at night. Either switch the feature off in the test's setup, or pin the clock.
- **Pinning the clock can break other checks.** Webhook freshness and signature timestamps will reject "stale" events. Moving the clock to 10:00 can make a real-time webhook look 10 hours old. Prefer switching the time-dependent feature off for that test, and run the failing test locally in a lane before pushing the fix.

## Concurrency tests

- Run the racing part in a loop (several rounds with fresh keys), so the race fires reliably instead of rarely.
- They fail more under host load. If one fails only when run with the full suite, look for shared state first (cache fixtures, event listeners firing from seeders) before blaming load.

## Screenshots

See `06-conflict-avoidance.md`. A navigation change re-baselines the screenshots that include the nav, in every locale.

## Red main

1. Find which merge broke it (main's push runs and the failing test).
2. **The fix-forward owner is the lane that wrote the failing test or code**, even when the other lane's merge exposed it. If that is your lane: post ALERT on the channel at once, fix it in **one tiny PR**, cancel your own runs that will fail anyway, merge, and post MERGED with the sha.
3. The other lane holds its merges, or explicitly accepts that one known failure. Tell it when the fix lands.
4. If a fix depends on another fix (yours and the other lane's), merge them into one PR (`02-coordination.md`).
5. Give the partner the exact fix commit, so their agents rebase and don't skip tests.
