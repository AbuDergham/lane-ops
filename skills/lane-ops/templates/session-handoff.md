# Session handoff: <date>, <time>

The previous session stopped (<reason: a usage limit, an account switch, a power cut>). A new session continues from here. The repo docs are the source of truth: <lane docs, progress notes>.

## Where we are
- **Lane total:** <N> tasks merged (<list of codes>).
- **Main:** `<sha>` (<last merge>).
- **CI mode:** <remote / local>; runners <state>.
- **Coordination channel:** issue #<N> (label lane-sync). Open ASKs: <list>.

## Pause and resume (fill this in for a power cut or a planned stop)
| Field | Value |
| --- | --- |
| Paused at | <ISO time>. On resume, read the channel from this moment, not a fixed window. |
| Agents | <agent ID and code for each; what was done for it: WIP commit `<sha>`, pushed, stack down> |
| Containers before the pause | <the exact stacks and containers to restore, and nothing more> |
| Stopped | <lane stacks (volumes kept), local CI runners, the heartbeat, the container engine and its VM> |

**Resume:** start the engine and restore exactly the containers listed; resume each agent with a message that says what was done for it; re-arm **one** heartbeat; read the channel from "Paused at"; re-run cancelled CI.

## In flight
### <CODE> <title>: PR #<n>, <TICKET> (<ticket status>)
| Field | Value |
| --- | --- |
| Branch | `<branch>` |
| Head | `<sha>`, <pushed / N unpushed commits> |
| Worktree | `<path>`; lane stack <up / down> |
| Review | <passed / findings pending / not done> |
| CI | <state of each check> |
| Next | <exact next step> |

## Next tasks (lowest code whose blockers are merged)
<table of code, blocker status>

## How we work
<point to the lane-ops skill; list only project-specific settings: lane cap, merge command, ticket command, partner-check command, attribution lines, language>

## Parked
<owner inputs, parked ideas, paused work>
