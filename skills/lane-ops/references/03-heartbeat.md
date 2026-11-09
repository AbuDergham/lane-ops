# The 10-minute heartbeat

The coordinator only wakes when something notifies it. Without a heartbeat, a dead monitor or a quiet CI run can leave the whole lane idle for hours. That happened: a green PR sat unmerged for 11 hours overnight.

## Mechanics

- Run `sleep 600` as a **background** command. When it finishes, re-arm it first, then do one check round. Never chain foreground sleeps.
- **Exactly one heartbeat timer.** Duplicates double the ticks. Before arming, check that none is already running, and stop any extras.
  - A session cron (if your host has one) can expire, for example after 7 days, without warning. Write the arm time and the expiry into the heartbeat prompt, and re-arm before it expires.
  - A background timer can be reaped under memory pressure. Don't switch that protection off machine-wide to keep one timer alive: a reaped timer is caught by the gap check below.
  - **Paused by the owner:** "exactly one" becomes "zero, by the owner's order". Record who paused it and when, print `== heartbeat: paused by owner since <date>`, and never re-arm on your own.
- **After a pause** (a power cut, an account switch, a usage limit), the first round reads back to the moment the pause started. `partner-check` does this by itself: its window reaches back to the last round without alerts, 48 h at most.
- Keep each round to one or two commands. When nothing changed, say one line, or nothing. But a failed check is never "nothing": see the next section.

## Output that can't lie

A check that fails must never look like a quiet round. This happened in three lanes:
- a Jira helper printed "ok" after "No such host";
- `2>/dev/null` turned a GitHub outage into an empty section;
- a network error read as "a failing check";
- first-page reads and `tail` missed partner posts five times;
- a timer died, and the silence looked like calm.

Every lane's heartbeat follows these rules (agreed by three lanes, 2026-11-09):

**What it prints**
1. **One status line per section:** `== <section>: ok (<n> new)` when it reached its source, or `== ALERT: <SECTION> CHECK FAILED: <reason, ≤80 chars>` when it didn't. An empty section never means "quiet".
2. **"0 new" only from a call that succeeded:** the exit code is 0 and the output parses. Never hide errors with `2>$null` or `2>/dev/null`.
3. **A red main** prints `== ALERT: <REPO> MAIN IS RED: <sha> <conclusion>`.
4. **The last line** is `== <script>: done, <n> alert(s)`. If it's missing, the run was cut short, and that is an ALERT.
5. **The exit code** is 1 if any ALERT was printed.

**Network calls**

6. **Reads** have a 30 s timeout and one retry after 5 s. Only the second failure is an ALERT.
7. **Writes** (transitions, comments, merges) are never retried blindly. Re-read first, so nothing is posted twice. After a write, re-read the result; if it isn't what was asked, exit 1 **and** print an ALERT line.
8. **A network error is never reported as something else**, such as "a failing check" or "permission denied".

**Nothing missed**

9. **Every list call paginates.**
10. **A cursor or a catch-up mark, kept in a file:**
    - where the source has ids, an id cursor, shown in the status line (`cursor=<id>`);
    - otherwise, the time of the last round that read every source, which the next window reaches back to (48 h at most).

    A round where any source failed doesn't move the mark. A round whose only alert is a heartbeat gap does, since it read every source.

**The heartbeat stays alive**

11. **Liveness.**
    - The script keeps a run stamp and prints `== heartbeat: last run <HH:MM>Z (<n> min ago)`. When the last run is older than twice the interval, it prints `== ALERT: HEARTBEAT GAP: <n> min`.
    - The run stamp is separate from the catch-up mark: every run moves the stamp, but only a round that read every source moves the mark.
    - The coordinator checks that exactly one heartbeat is armed at every session start and after any pause.
12. **Report and re-arm.** The coordinator reports every ALERT to its owner in the same turn. It re-arms the way the mechanism needs: a sleep timer every round, a cron before it expires.

**Privacy**

13. **No secrets in any line.** Error text is cut short, with tokens, headers, IP addresses and URLs removed.

`scripts/partner-check.sh` and `.ps1` follow rules 1–6, 8–11 and 13 for GitHub. Run them with `-i <minutes>` (or `-Interval`) on the heartbeat's own call to get the run stamp and the gap ALERT. Their state lives in `$LANE_OPS_STATE` (default `~/.lane-ops`). Your ticket and CI checks follow the same rules.
- For a specific event (a PR's checks finishing, a PR merging), start a background `until` loop that polls every 60 seconds and exits on the condition. Kill it when it's no longer needed.

## Checklist for each round

1. **Your open PRs:** `mergeable` state, and each check's state.
   - Green and reviewed: merge it, or make sure its agent is merging. If main moved after its last green run, merge main and re-run first (`02-coordination.md`).
   - CONFLICTING: find the files (`git merge-tree --write-tree --name-only origin/main <pr-ref>`) and send the agent the list. "Keep both sides" for append-style lists.
   - A check failed: open the job log, find the failing test, and send the agent the exact test name and error. If it failed outside the agent's code, see `07-ci-operations.md`.
   - `UNKNOWN` for more than one round: check locally with `merge-tree`.
2. **Worktrees:** last commit time, uncommitted file count, unpushed commits, and files changed in the last 30 minutes.
   - No change for 30 minutes and no test running: nudge the agent ("reply in one line with what you're doing").
   - Uncommitted files with a last commit older than an hour: tell the agent to commit and push work in progress now (power cuts happen). Every implementer pushes WIP at least hourly.
3. **Runners:** online and busy states. If the remote runners go offline, switch to plan B (`07-ci-operations.md`).
4. **Main's push CI:** catches clashes between PRs that were each green on their own.
5. **The other lane:** use the `partner-check` script, which covers:
   - new comments on the lane-sync channel;
   - every issue and PR in the repo that changed in the window;
   - new comments and PR review comments by others;
   - unread notifications.

   Check tickets updated by others with your tracker's own CLI.

   Answer ASKs addressed to you within this round. Tell the owner anything new.
6. **Tickets:** every task merged since the last round is Done, with a "Merged:" comment.
7. **After any merge:** housekeeping (`09-housekeeping.md`).

## Useful commands

```bash
# your PRs: draft, mergeable, checks
for n in $(gh pr list --state open --author <you> --json number --jq '.[].number'); do
  echo "#$n $(gh pr view $n --json isDraft,mergeable,title --jq '"d=\(.isDraft) \(.mergeable) \(.title[0:24])"') | $(gh pr checks $n 2>&1 | awk '{printf "%s:%s ", $1,$2}')"
done

# runners
gh api repos/<owner>/<repo>/actions/runners --jq '[.runners[]|"\(.name):\(.status)\(if .busy then "*" else "" end)"]|join(" ")'

# worktree activity
d=../repo-<lane>; echo "last $(git -C $d log -1 --format=%ad --date=format:%H:%M) uncommitted $(git -C $d status --short | wc -l) unpushed $(git -C $d log --oneline @{u}.. | wc -l) changed30m $(find $d/app $d/tests -newermt '-30 minutes' -type f | wc -l)"

# why a check failed (php example)
job=$(gh pr checks <n> --json name,link --jq '.[]|select(.name=="php-tests")|.link' | sed -E 's#.*/job/([0-9]+).*#\1#')
gh api repos/<owner>/<repo>/actions/jobs/$job/logs | sed -E 's/\x1b\[[0-9;]*m//g' | grep -E 'FAILED|Tests:|Failed asserting|##\[error\]'

# wait for one PR's checks to finish (run in the background)
until s=$(gh pr checks <n> --json state --jq '[.[].state]|map(select(.=="PENDING" or .=="QUEUED" or .=="IN_PROGRESS"))|length') && [ "$s" = "0" ]; do sleep 60; done
```

## When the agent's report and reality differ

Trust the repo. Agents report from stale state: a "deadlock" that was a typo, a fix "in PR X" that is really in PR Y. Correct the agent with the facts and a precise next step.
