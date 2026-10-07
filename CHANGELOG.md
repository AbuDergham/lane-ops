# Changelog

## 1.0.1 (2026-10-07)

- Removed `jira-ticket.ps1` and the Jira part of `partner-check`. The plugin's scripts now read no credentials at all; `partner-check` uses only the `gh` CLI's own sign-in. Use your ticket tracker's official CLI for tickets.
- Added the plugin icon (`.claude-plugin/icon.png`).
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
