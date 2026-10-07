# Session handoff: <date>, <time>

The previous session stopped (<reason: a usage limit, an account switch>). A new session continues from here. The repo docs are the source of truth: <lane docs, progress notes>.

## Where we are
- **Lane total:** <N> tasks merged (<list of codes>).
- **Main:** `<sha>` (<last merge>).
- **CI mode:** <remote / local>; runners <state>.
- **Coordination channel:** issue #<N> (label lane-sync). Open ASKs: <list>.

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
