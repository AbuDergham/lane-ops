---
name: lane-ops
description: Run a software build as parallel "lanes". Each lane is led by a Claude coordinator session that drives implementer agents; a human owner directs; another team (a partner with its own Claude coordinator) runs the other lane in the same repo. Use when you plan or run multi-lane or multi-partner delivery on GitHub with PRs, CI and tickets. It covers splitting work into lanes, the 10-minute heartbeat, the lane-sync coordination issue, implementer prompts, review gates, merging by turns, avoiding conflicts, CI runner operations, working while the owner sleeps and the morning report. Triggers include "two lanes", "lane sync", "heartbeat", "coordinate with my partner", "run the build overnight", "مسارين", "شريكي", "النبض", "قناة التنسيق".
---

# Lane ops: running a build as coordinated lanes

A playbook for one Claude **coordinator** session per lane. Implementer agents do the coding; the coordinator picks the work, reviews it, merges it, keeps CI and the repo healthy, talks to the other lane's coordinator, and reports to the human **owner**. It was distilled from a real two-lane build, where two owners each ran one Claude coordinator with 2 to 3 Sonnet implementers on a shared GitHub repo.

## Roles

- **Owner (human).** Sets direction and priorities. Owns decisions about money, scope, plans, security trade-offs, destructive actions and anything outward-facing beyond routine coordination. May be asleep.
- **Coordinator (this session).** Never codes large features itself. It launches implementers, reviews their PRs, merges, runs the heartbeat, coordinates with the other lane, cleans up, and reports in the owner's language.
- **Implementers (sub-agents, Sonnet by default).** One task each, in an isolated worktree and stack ("lane"). They claim, build test-first, open a PR, wait for "review passed", merge, and clean up.
- **Partner coordinator.** The other lane's Claude session. Reached only through the lane-sync channel (an issue). Never instruct its agents directly.

## The loop

1. **Pick** the lowest-numbered task in your lane whose "Starts when" blockers are merged. Handoffs come first. Never take the other lane's tasks without asking; trades go both ways, by agreement. See `references/01-lanes-and-tasks.md`.
2. **Launch** an implementer with the prompt template (`templates/implementer-prompt.md`), named `[CODE] Title`. Stay within the lane cap, by default 2 to 3, set by the machine and the owner.
3. **Heartbeat** every 10 minutes (`references/03-heartbeat.md`). Watch PR state, CI, idle or unpushed agents, the runners, the partner's activity and the tickets.
4. **Review** when the implementer reports the PR ready, in parallel with CI. Read the diff yourself for small changes; run the light review workflow for security, money, tenancy or public API work (`references/05-review-gate.md`). Send the findings with file and line, or reply "review passed" once CI is green on a head that includes the current main.
5. **Merge by turns:** check that the PR's last green run includes the current main, announce MERGING and MERGED on the lane-sync channel, and hold while the other lane is mid-merge (`references/02-coordination.md`).
6. **Clean up** after every merge: the lane stack, worktree, branch, volumes, images and stale watcher processes (`references/09-housekeeping.md`).
7. **Report** in short messages to the owner. When the owner is away, follow `references/08-owner-and-budget.md` and leave a morning report (`templates/morning-report.md`).

## Non-negotiables

- Merge only through the repo's merge script (or `gh pr merge` after every required check is green on a run that includes the current main), never by pushing to main.
- A CONFLICTING PR gets no CI. Make the agent merge main at once.
- Never route other people's CI jobs to the owner's private runners.
- Secrets never go in git, chat or logs. Ticket and API tokens live only in environment variables.
- Agents never touch the owner's default development stack, never delete or edit files outside their own worktree and lane resources, never `rm -rf`, never remove Docker networks or other projects' resources, and never open extra PRs without asking. Prompts live in a durable project folder, not the session scratchpad.
- Main red because of your lane is the top priority: post ALERT, fix it in one small PR, tell the partner.
- No tests that depend on the time of day, shared fixtures between specs, or blind waits longer than 5 minutes.

## Reference map

| Need | Read |
| --- | --- |
| Split work, task fields, picking and claiming, trading tasks, early starts, lane cap | `references/01-lanes-and-tasks.md` |
| Lane-sync channel, reading after a pause, message tags, merging by turns, the green-run rule, fair turns, hotfix numbers, deadlocks | `references/02-coordination.md` |
| The 10-minute heartbeat (one timer) and its commands | `references/03-heartbeat.md` |
| Implementer prompts (durable folder, head plus shared tail), worktrees, nudging and resuming agents | `references/04-implementers.md` |
| Review tiers, what to check, delta reviews, big refactors, the other lane's PRs, plan rounds | `references/05-review-gate.md` |
| Conflict hot spots and how to remove them, semantic clashes | `references/06-conflict-avoidance.md` |
| CI: runners, re-runs, flakes, timeouts, screenshots, red main and its fix-forward owner | `references/07-ci-operations.md` |
| Owner away, delegation, the morning report, the token budget, usage limits, handoffs | `references/08-owner-and-budget.md` |
| Cleanup, Docker limits, the power-cut protocol, stale watchers, the repository README | `references/09-housekeeping.md` |
| Failure modes we hit, and how to prevent them | `references/10-lessons.md` |

## Bundled files

- `templates/`: the lane-sync issue body, the implementer prompt, the morning report, the session handoff.
- `scripts/partner-check.ps1` and `scripts/partner-check.sh`: one command for the heartbeat's "what changed" view (the lane-sync channel, every issue and PR changed in the window, new comments, review comments, notifications). They use only the `gh` CLI's own sign-in and read no credentials. For tickets, use your tracker's own CLI (for example Atlassian's CLI for Jira).
- `scripts/pr-review-light.js`: a workflow script (one reviewer covering all lenses, then a skeptic for the majors only) for the Workflow tool.

Copy the scripts into the project's tools folder and set their parameters; don't edit them in place in the plugin cache.
