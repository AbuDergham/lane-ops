# Changelog

## 1.1.0 (2026-10-09)

Lessons from a second multi-day, two-lane run, folded into the existing rules. Lessons learned grow from 30 to 45.

- Merging:
  - a PR's last green run must include the current main; merge main and re-run if it moved;
  - fair turns: after a PR's green run goes stale three times, the other lane holds;
  - an old MERGING claim with no progress gets an ASK, not a skip;
  - the fix-forward owner of a red main is the lane that wrote the failing code or test.
- Coordination:
  - after any pause, read the channel from the pause start, with `since=` and pagination;
  - lanes trade tasks both ways, under the owning lane's contract and review;
  - design approval before UI code built by the other lane;
  - next-sprint early starts, with a merged contract and a session cap;
  - don't run ticket helpers with side effects on the other lane's tickets;
  - owners may delegate approvals, recorded on the channel.
- Reviews:
  - review only the delta after fixes;
  - prove big refactors mechanically (value comparisons, built bundle keys);
  - check static readers of source files;
  - derive enum-pinning tests from the registry;
  - name repeating bug classes and add them to the checklist (cleanup in catch blocks);
  - cap plan and contract review rounds at two or three;
  - don't approve the other lane's drafts on the forge.
- Implementers: prompts live in a durable project folder, built from a per-task head and a shared tail; never delete or edit outside your own worktree; hourly WIP pushes checked on the heartbeat.
- Heartbeat: exactly one timer.
- CI: check the job's runner name and shared setup helpers before blaming capacity.
- Housekeeping: a power-cut protocol (on battery, then resume); writing the repository README by inventory with a verifier.
- Templates: the implementer prompt (green-run rule, worktree-only deletes, durable folder, head and tail); the session handoff (pause and resume notes); the lane-sync issue; the morning report.
- Scripts: partner-check reads the channel with pagination.

## 1.0.1 (2026-10-07)

- Removed `jira-ticket.ps1` and the Jira part of `partner-check`. The plugin's scripts now read no credentials at all; `partner-check` uses only the `gh` CLI's own sign-in. Use your ticket tracker's official CLI for tickets.
- Added the plugin icon.
- Housekeeping notes: the lane-folder check is described in prose.


## 1.0.0 (2026-10-07)

First public release.

- The `lane-ops` skill: roles, the 7-step loop, non-negotiables, a reference map.
- References:
  - lanes and tasks;
  - coordination (the lane-sync channel, merging by turns);
  - the 10-minute heartbeat;
  - implementers;
  - the review gate;
  - conflict avoidance;
  - CI operations;
  - owner and budget;
  - housekeeping;
  - 30 lessons learned.
- Templates: the lane-sync issue, the implementer prompt, the morning report, the session handoff.
- Scripts: `partner-check` (PowerShell and bash), `jira-ticket.ps1`, and the `pr-review-light.js` workflow.
