# Coordinating with the other lane

## The channel

- There is always **exactly one open issue labelled `lane-sync`**, titled "Lane sync (coordinators only), from YYYY-MM-DD". Find it with `gh issue list --label lane-sync --state open`. The body is `templates/lane-sync-issue.md`.
- It is only for coordinator-to-coordinator traffic. Humans and long discussions go in PRs or their own issues, with a link posted to the channel.
- **Rotate** it weekly (Monday) or at about 50 comments, to keep the channel small: open the new issue, copy any open ASKs into its first comment, post `INFO: rotated to #N` on the old one, and close the old one. If a heartbeat finds none or two open, take the newest and say so.

## Message format

One comment per message. The first line carries the tag, and the details sit behind a link.

| Tag | Use | Reply |
| --- | --- | --- |
| `[L2→L1] MERGING #N (what)` | about to run the merge | none |
| `[L2→L1] MERGED #N <sha>` | merged | none |
| `[L2→L1] ASK-<n>: question` | needs an answer or action | `ANSWER-<n>` or `ACK-<n>` within one heartbeat |
| `[L1→L2] ANSWER-<n>` / `ACK-<n>` | answer, or "seen, working on it" | none |
| `[Lx→Ly] ALERT: what` | main red, runners down, security, anything blocking both lanes | ACK |
| `[Lx→Ly] INFO: what` | heads-up: a shared-file change, a mode switch, a correction | none |
| `[Lx→Ly] HOTFIX-<n> CLAIMED: title` | claims the next free hotfix number | none |

- ASK numbers: Lane 1 uses odd numbers, Lane 2 even, so they never clash.
- Mark decisions that need a human: `ASK-<n> (needs owner)`. While your owner is away, answer "needs owner, answer in the morning".
- Read only the comments since your last check: `gh api --paginate "repos/<owner>/<repo>/issues/<N>/comments?since=<ISO>&per_page=100"`. Rotation keeps the channel small, but reads must still paginate: a busy day can pass 100 comments before rotation, and a read without `since=` or pagination returns only the first page.
- **After any pause** (a power cut, an account switch, sleep, a usage limit), read from the moment the pause started, not a fixed recent window. A fixed window once missed a request posted two hours earlier.

## Merging by turns

1. Before you merge, read the channel. Honour a `MERGING #N` from the other lane that has no `MERGED #N` yet. If the claim is older than ~30 minutes with no progress, ASK about it; don't just go.
2. **The PR's last green run must include the current main.** If main moved after that run, merge main and re-run before you merge. Two PRs, each green on its old base, broke main together: one renamed a class, the other still used it, and they merged minutes apart. Never tell the other lane "your green run stays valid" after a merge that removes or renames code. Only a docs-only change on main may be waived, and say so explicitly.
3. Post `MERGING #N`, run the merge, then post `MERGED #N <sha>` **right away**. The other lane may be waiting on it.
4. If two of your own PRs are green together, set the order (one first, the other after its MERGED), so neither turns CONFLICTING mid-merge.
5. A lane may post MERGING early ("as soon as CI is green"). If your PR is green now and theirs has only just started CI, **ask** (ASK) to go first. Don't jump the queue.
6. **Fair turns.** If one PR's green run has gone stale three times because others merged first, the other lane holds its merges until that PR lands.
7. When one of your PRs has been rebased again and again on the same hot files, ask for a **merge window** ("hold your merges about 45 minutes after your current one"). Post a line if you need longer, and release the hold if you can't use it.

Once the conflict hot spots are removed (`06-conflict-avoidance.md`), turns rarely cost a rebase. Keep the MERGING/MERGED lines anyway: they cost nothing, and they keep both heartbeats in sync.

## Hotfix numbers

Hotfix tasks have no ticket, but their number becomes a file name (progress notes). **Claim the next free number on the channel before you use it.** Duplicate numbers have happened.

## Shared resources

- **CI runners.** If you route your jobs to the partner's runners, they share a queue. When their queue is long, move yours to your own runners, post INFO ("your queue is yours until it clears"), and post again when you move back.
- **Shared files** (a Support class, a layout block, a seeder, a policy). Before creating one, look at the other lane's open draft PRs for the same file. Two lanes have created the same class name in parallel before.
- **Test fixtures.** Never reuse another spec's fixture values (for example the same recovery codes or the same store slug). Give each spec its own slice.
- **The other lane's tickets.** Tools that write to a tracker can have side effects (for example a helper that always assigns the ticket to its caller). Don't run them on the other lane's tickets; post comments there with a direct call.

## Breaking deadlocks

- **A fix needs a fix.** If your fix for a red main can't pass because of a different failure that the other lane is fixing (and theirs can't pass without yours), propose putting both fixes in one PR: "may we merge your branch into ours, or will you add our one commit to yours?" Let the owner of the bigger change choose.
- **Wrong claims in coordination** (the wrong PR number in a MERGED line, a mistaken diagnosis such as "the runner is starved") can make a lane wait or act for nothing. Correct them at once with INFO.

## Proposing convention changes

A change to a shared working rule (for example how progress notes or test helpers are organised) needs both owners. Post the options, the cost of each (including the one-off conflicts it causes for open PRs), and your owner's preference, then ask for the partner's choice and a time when they have few open PRs. Do it as one hotfix PR by the proposing lane, with the rule docs updated in the same PR.

## Tone

Short, factual, with links. When the partner asks about a failure in your code: give the root cause, the fix commit or PR, and what they need to do ("rebase on <sha>"). When you break main: apologise in one line and give the fix link. Thank them for holds and help.
