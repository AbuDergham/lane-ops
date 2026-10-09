# The owner, the budget and continuity

## Talking to the owner

- Reply in the owner's language, in short messages. Use tables for status, and keep technical terms in English.
- Give a status as: what merged (with the count), what's in flight and where it's stuck, what you're doing about it, and the decisions waiting for them.
- Report problems plainly, including your own mistakes ("main went red because of our file name; fixed in #N"). Never claim something is done or verified when it isn't.
- When they ask "is it stuck?", check the real state (commits, files changed, CI jobs, runners) before answering, and explain the causes.

## While the owner is away (agree this upfront)

**Do on your own:**
- merge green and reviewed PRs following the protocol;
- fix test and CI breakage (above all a red main caused by your lane);
- re-run flakes;
- coordinate routine things with the partner;
- start the next ready task within the lane cap;
- clean up.

**Park for the owner:**
- anything that costs money;
- changes the plan or scope;
- deletes beyond your own lane's leftovers;
- trades off security;
- changes a shared convention;
- any partner ASK marked "(needs owner)". Answer that one with "needs owner, answer in the morning".

**Delegation.** An owner may let the other owner's approval stand in for theirs, for example for one night. Record it on the channel each time it's used, and list it in the morning report.

**Morning report** (`templates/morning-report.md`): merged items, in-flight items, problems and how they were solved, partner news, then the **decisions waiting**, each with options and your recommendation.

## Token budget

- Implementers on Sonnet. Coordinator turns short. Heartbeat rounds compact (one or two commands, a one-line report).
- Choose review tiers by risk (`05-review-gate.md`). No large fan-out workflows unless the owner asks for one.
- Resume existing agents (SendMessage) for follow-ups instead of spawning new ones.
- Grep and cut logs; never dump whole files or logs into the conversation.
- The lane cap is a budget lever as well as a RAM lever. The owner sets it.

## Usage limits and handoffs

- When a usage limit is close:
  1. tell every running agent to commit work in progress, push it, and stop;
  2. stop running workflows;
  3. write a **session handoff file** (`templates/session-handoff.md`) in the project folder;
  4. add a one-line pointer in memory;
  5. check that no script or prompt lives only in the session scratchpad. They belong in the project's tools folder from the start.
- For a power cut, follow the protocol in `09-housekeeping.md`.
- A new session or account starts from the handoff file, re-arms one heartbeat, reads the channel from the pause start, and resumes agents with SendMessage where possible.
- Update the handoff file whenever a lane's state changes materially.

## Memory hygiene

- Save working rules the owner gives you (lane cap, naming, protocols, the overnight policy) as feedback memories, with the reason.
- Save project status only when the repo doesn't already record it. Point to the handoff file instead of copying it.
