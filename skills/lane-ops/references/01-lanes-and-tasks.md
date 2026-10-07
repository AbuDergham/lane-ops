# Lanes and tasks

## Splitting the work

- Split by **area of the product**, not by phase, so the lanes touch different modules most of the time. Example: one lane owns sending and automation, the other owns receiving, inbox, billing, platform, API and admin.
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
- **Never take the other lane's tasks without asking.** If your lane runs dry, ask the partner on the channel, or ask the owner.

## Claiming

- The implementer opens a **draft PR at once**, titled `type(scope): title [PLAN-ID] (TICKET)`, and posts a ticket comment: "Claimed by draft PR #N (branch, lane)."
- Move the ticket to In Progress on the claim, In Review when the PR is marked ready, and Done on merge. Every merge gets a comment: "Merged: PR #N, main <sha>. CI: <result>. <what was built, gaps>". Agents sometimes skip the Done step: check after every merge, and fix it yourself.

## Lane cap

- Each Docker lane costs about 3 to 4 GB of RAM and about 4 Docker networks. Start at **2 lanes** on a 32 GB PC, or 3 if CI runs elsewhere. The owner sets the cap.
- Count a lane as active while its agent works or its stack runs. A lane that only waits for CI or review should bring its stack down, keeping the volumes.
- Small follow-up PRs (a fix found in review, a one-line CI fix) can run beside the cap if they need no stack.

## Naming agents

Start every implementer's `description` with its code in brackets: `[R7] Invoice export`, `[HOTFIX-3] Flaky login spec`. The owner reads the session list by these names.
