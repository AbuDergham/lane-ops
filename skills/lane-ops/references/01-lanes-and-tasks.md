# Lanes and tasks

## Splitting the work

- Split by **area of the product**, not by phase, so the lanes touch different modules most of the time. Example: Lane 1 owns feature area A end to end, Lane 2 owns feature area B.
- Give each lane a **code prefix**: Lane 1 tasks are S1, S2 and so on, Lane 2 tasks are R1, R2 and so on. Keep the plan's own IDs too (for example P2-04). Map every code to a ticket key.
- Write one **lane doc** per lane, plus an index doc (`LANES.md`) that both owners approve. Changes to the split are PRs that both owners approve.

## Fields of a task

Each task in a lane doc has:

| Field | Meaning |
| --- | --- |
| Code · plan ID · title (ticket) | for example `R4 · P2-03 Password reset (TICKET-23)` |
| Feature, size | the area, and S, M or L |
| Build | what to build, in one or two lines |
| Done when | observable acceptance criteria (tests must prove them) |
| Closes | IDs of known bugs or audit findings whose class the tests must make impossible |
| Starts when | blockers: tasks in this lane or the other lane that must be merged first |
| Unblocks | what this task frees |
| Owner inputs | things only the owner can supply (legal texts, prices, credentials). Build behind a placeholder, with a go-live checklist row |

The binding sources for an implementer are the lane doc section, the phase **contract** (with its amendment notes), the plan row, and any audit doc. A deviation from the contract must be justified in the task's Decisions section and applied to the contract in the same PR.

## Picking

- Take the **lowest code whose blockers are all merged**. Handoffs (tasks that unblock the other lane) come first.
- If a lower task is blocked on an open PR in either lane, skip to the next ready one and say so.
- If a ready task would collide with your own open PR (same module or page), prefer a non-overlapping ready task first.
- **Never take the other lane's tasks without asking.** If your lane runs dry, offer spare capacity on the channel ("is there anything we can take?"), or ask the owner. See "Trading tasks" below.
- **Next sprint, early start.** A lane that finishes early may start next-sprint tasks that depend on nothing in the other lane. Two conditions: the next sprint's contract is merged first, and both lanes agree a cap on concurrent sessions, so shared CI isn't crowded.

## Trading tasks

- Trades go both ways. Offer spare capacity, and accept the other lane's offers.
- The lane that builds a task follows the **owning lane's contract** and gets the owning lane's review before merge.
- Record the move in the lanes file, the tracker and the channel. The giving lane hands over a short note of what its planner already found (files, risks, open questions).
- **Design approval before UI code.** For a screen-heavy task built by the other lane, ask for a one-page design plan first: layout, components, states (empty, loading, error), right-to-left and phone behaviour if relevant, and backend touch points. Answer "GO design" or the changes before any code starts.

## Claiming

- The implementer opens a **draft PR at once**, titled `type(scope): title [PLAN-ID] (TICKET)`, and posts a ticket comment: "Claimed by draft PR #N (branch, lane)."
- The implementer moves the ticket: to In Progress when its draft PR claims the task (not at launch), to In Review when the PR is marked ready, and to Done on merge. Every merge gets a comment: "Merged: PR #N, main <sha>. CI: <result>. <what was built, gaps>". Agents sometimes skip the Done step: check after every merge, and fix it yourself.

## Lane cap

- Each Docker lane costs about 3 to 4 GB of RAM and about 4 Docker networks. Start at **2 lanes** on a 32 GB PC, or 3 if CI runs elsewhere. The owner sets the cap.
- Count a lane as active while its agent works or its stack runs. A lane that only waits for CI or review should bring its stack down, keeping the volumes.
- Small follow-up PRs (a fix found in review, a one-line CI fix) can run beside the cap if they need no stack.

## Naming agents

Start every implementer's `description` with its code in brackets: `[R7] Invoice export`, `[HOTFIX-3] Flaky login spec`. The owner reads the session list by these names.
