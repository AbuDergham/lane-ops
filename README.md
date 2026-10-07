# lane-ops

**A Claude Code plugin for running a software build as coordinated lanes of Claude agents.**

One Claude **coordinator** session runs each lane. It picks tasks, launches implementer agents, reviews and merges their PRs, keeps CI healthy, and coordinates with the coordinator of another lane (a partner team on the same repo). A human **owner** directs each lane and makes the decisions that matter.

The playbook comes from a real two-lane build, where two owners each ran a Claude coordinator with 2 to 3 implementer agents, in one GitHub repo, around the clock. It holds what worked and the 30 failure modes we hit, each with its prevention.

## Who it's for

- You run (or plan to run) **parallel Claude agents** on one codebase and want them to stop stepping on each other.
- You **share a repo with a partner** who has their own Claude session, and need a coordination protocol.
- You want the work to **keep going overnight** safely, with a clear line between what Claude decides and what waits for you.

## What's inside

| Part | Covers |
| --- | --- |
| `SKILL.md` | the roles, the 7-step loop, the non-negotiables, a map of the references |
| `references/01-lanes-and-tasks.md` | splitting work into lanes, task fields (Build, Done when, Starts when), picking and claiming, the lane cap |
| `references/02-coordination.md` | the **lane-sync** issue channel, message tags (MERGING/MERGED/ASK/ANSWER/ALERT/INFO), merging by turns, hotfix numbers, breaking deadlocks |
| `references/03-heartbeat.md` | the **10-minute heartbeat**: what to check and the exact commands |
| `references/04-implementers.md` | implementer prompts, worktree lanes, talking to running agents |
| `references/05-review-gate.md` | review tiers by risk, and a security checklist |
| `references/06-conflict-avoidance.md` | finding and removing merge-conflict hot spots, screenshot baselines |
| `references/07-ci-operations.md` | runner routing, re-runs, flakes and real failures, time-of-day tests, red main |
| `references/08-owner-and-budget.md` | rules while the owner is away, the morning report, the token budget, usage limits, handoffs |
| `references/09-housekeeping.md` | lane cleanup, Docker limits, power cuts, stale watchers |
| `references/10-lessons.md` | 30 failure modes and how to prevent them |
| `templates/` | the lane-sync issue body, the implementer prompt, the morning report, the session handoff |
| `scripts/` | `partner-check` (PowerShell and bash, GitHub only, no credentials read) and the `pr-review-light.js` workflow |

## Install

In Claude Code:

```text
/plugin marketplace add AbuDergham/lane-ops
/plugin install lane-ops@lane-ops
```

Or from a shell:

```bash
claude plugin marketplace add AbuDergham/lane-ops
claude plugin install lane-ops@lane-ops
```

Update later with `/plugin marketplace update lane-ops`.

## Use

The skill loads by itself when you talk about running lanes, coordinating with a partner, the heartbeat, or working overnight. Or ask for it: *"use the lane-ops skill to set up two lanes for this repo"*.

To start a project:
1. Write one lane doc per lane (`references/01`).
2. Open the coordination issue from `templates/lane-sync-issue.md`, labelled `lane-sync`.
3. Copy `scripts/` into the project's tools folder and set the parameters (repo, your login).
4. Agree the overnight rules with the owner (`references/08`).
5. Start the heartbeat (`references/03`).

## Requirements

- Claude Code, with sub-agents (the Agent tool) and, for the review workflow, the Workflow tool.
- GitHub with the `gh` CLI signed in; `jq` for the bash script.
- Optional: a ticket tracker (Jira or another) through its own official CLI. The plugin's scripts never read tracker credentials.
- The playbook assumes Docker-based per-lane stacks and GitHub Actions. The ideas carry over to other setups.

## Contributing

Issues and PRs are welcome, especially new failure modes with their prevention (`references/10-lessons.md`).

## License

[MIT](LICENSE)
