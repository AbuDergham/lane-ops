# lane-ops

A Claude Code plugin with one skill, **`lane-ops`**: a playbook for running a software build as parallel **lanes**.

Each lane has one Claude **coordinator** session. The coordinator launches implementer agents, reviews and merges their PRs, keeps CI healthy, and coordinates with the other lane's coordinator (a partner team on the same repo). A human **owner** directs each lane.

It was distilled from a real two-lane build. It is generic: it contains no project, company or person names, and no URLs or credentials.

## What's inside

```
skills/lane-ops/
  SKILL.md                      the loop, the roles, the non-negotiables, a reference map
  references/
    01-lanes-and-tasks.md       splitting work, task fields, picking and claiming, the lane cap, agent names
    02-coordination.md          the lane-sync channel, message tags, merging by turns, hotfix numbers, deadlocks
    03-heartbeat.md             the 10-minute heartbeat checklist and commands
    04-implementers.md          the prompt rules, the lane lifecycle, talking to running agents
    05-review-gate.md           review tiers and the security checklist
    06-conflict-avoidance.md    hot spots, per-task notes, per-module registries, screenshots
    07-ci-operations.md         runners, re-runs, flakes, timeouts, time-of-day tests, red main
    08-owner-and-budget.md      owner-away rules, the morning report, the token budget, usage limits, handoffs
    09-housekeeping.md          cleanup, Docker limits, power cuts, stale watchers
    10-lessons.md               30 failure modes and how to prevent them
  templates/
    lane-sync-issue.md          body for the coordination issue
    implementer-prompt.md       the full implementer prompt, with placeholders
    morning-report.md           the report for the owner
    session-handoff.md          a handoff for a new session or account
  scripts/
    partner-check.ps1 / .sh     the heartbeat's "what changed" view (GitHub and optional Jira)
    jira-ticket.ps1             assign, move and comment on Jira tickets (the token comes from env vars)
    pr-review-light.js          the review workflow (one reviewer, then a skeptic for majors) for the Workflow tool
```

## Install (private repo)

Your machine needs git access to this repo (for example `gh auth login`, or SSH keys).

```text
/plugin marketplace add AbuDergham/lane-ops
/plugin install lane-ops@lane-ops
```

From a shell:

```bash
claude plugin marketplace add AbuDergham/lane-ops
claude plugin install lane-ops@lane-ops
```

To share it with a partner, give them read access to this repo, and they run the same two commands.

## Use

The skill loads by itself when you talk about running lanes, coordinating with a partner, the heartbeat, or working overnight. You can also ask for it directly ("use the lane-ops skill").

For a new project:
1. Write the lane docs (`references/01`).
2. Open the lane-sync issue from `templates/lane-sync-issue.md`.
3. Copy `scripts/` into the project's tools folder and set the parameters.
4. Agree the overnight rules with the owner (`references/08`).
5. Start the heartbeat.

## Updating

Edit, commit and push. Then run `/plugin marketplace update lane-ops` on each machine.
