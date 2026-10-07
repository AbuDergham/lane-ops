# Lessons: failure modes and how to prevent them

Each line: what happened, then the prevention, which is already built into the other references.

## Stalls and lost time

1. **The lane slept overnight.** Agents waited on monitors that had died, and the coordinator only wakes on notifications. → The 10-minute heartbeat; no blind waits longer than 5 minutes.
2. **A green PR sat unmerged for hours.** → Every heartbeat merges green and reviewed PRs, or makes their agent merge.
3. **A conflicting PR waited a day for CI that never starts.** → Check `mergeable` on every round.
4. **Work committed but never pushed, then a power cut.** → WIP push every hour; after a power cut, WIP-commit before resuming.
5. **An agent idle with its stack up for 40 minutes.** → Nudge after 30 minutes with no file changes and no test CPU.
6. **A stale watcher ran for 16 hours** (waiting on a log that cleanup deleted). → Kill watchers during housekeeping.
7. **Agents act on stale information** (a typo'd PR number, a fix "in PR X" that was really in PR Y). → Correct them at once with facts.

## Conflicts

8. **Every merge conflicted every open PR** (a shared progress log and its "Last updated" line, a shared helpers file). → One note file per task; per-module helpers.
9. **Shared enums, language files and enum tests conflicted on nearly every merge.** One PR was rebased five times. → Per-module registries, or sorted insertion; ask for a merge window meanwhile.
10. **The nav changed, so a screenshot baseline broke for whoever landed second**, and an old baseline sat right at the tolerance. → Whoever changes the nav re-baselines, after checking the diff image.

## Main went red

11. **A note file had a name that wasn't a task ID**, so the format arch test broke main for both lanes. → Validate names locally (run the arch group before pushing); one tiny fix PR.
12. **A test failed only after 22:00** (quiet hours held a reply). → No time-of-day dependence in tests.
13. **The first fix for 12 was wrong:** pinning the clock made a real-time webhook look 10 hours old, so it was rejected. → Run the failing test locally in a lane before pushing a fix; prefer switching the time feature off for that test.
14. **Two fixes depended on each other across lanes.** → Combine them into one PR, by agreement.
15. **Two e2e specs shared the same recovery codes**, so whichever ran second was stuck at the 2FA prompt. → Each spec owns its own fixture slice.
16. **Two PRs each green on their own clashed on main.** → Watch main's push CI after merges.

## Correctness bugs the review gate caught

17. **A rate limiter's first hit could be raced:** 11 requests got through a cap of 10. → Locks taken in sorted key order; looped concurrency tests.
18. **A verification code could reach the logs** through the SQL bindings of an exception. → Catch, rethrow sanitized, never chain.
19. **"Pay to reactivate" was shown for suspensions that payment can't lift.** → Message by reason.
20. **A suspended account could still use the public API** (a follow-up hidden in another task's notes). → Grep the follow-ups aimed at the next task (`target <TASK>`) and fold them into its prompt.
21. **Keyset pagination had no index behind it.** → Review checklist item.
22. **A seeder fired real notifications** for states that never happened, which broke an unrelated test. → Seed with events off.

## CI and infrastructure

23. **Local runners were 3 times slower under load:** jobs timed out after every test had passed. → Stacks down during CI; prefer the remote runners; read "cancelled with N passed" as a timeout.
24. **Re-runs didn't include the latest main.** → Merge main and push instead.
25. **Docker ran out of network pools.** → Stacks down while waiting; remove idle networks with approval; plan smaller pools.
26. **An agent installed a dependency in the owner's default stack.** → Forbid it in every prompt.
27. **An agent opened an extra PR without asking.** → Forbid it; review it if it's valid.
28. **An agent's delete command made it stop and ask.** → Never `rm -rf`; use fresh temporary folders.
29. **Visible console windows popped up on Windows**, from a CLI's telemetry helper. → Disable telemetry; use `bin\bash.exe`.
30. **A usage limit hit in the middle of the work.** → Agents WIP-commit and stop; write a handoff file; resume from it.
