# The 10-minute heartbeat

The coordinator only wakes when something notifies it. Without a heartbeat, a dead monitor or a quiet CI run can leave the whole lane idle for hours. That happened: a green PR sat unmerged for 11 hours overnight.

## Mechanics

- Run `sleep 600` as a **background** command. When it finishes, re-arm it first, then do one check round. Never chain foreground sleeps.
- Keep each round to one or two commands. When nothing changed, say one line, or nothing.
- For a specific event (a PR's checks finishing, a PR merging), start a background `until` loop that polls every 60 seconds and exits on the condition. Kill it when it's no longer needed.

## Checklist for each round

1. **Your open PRs:** `mergeable` state, and each check's state.
   - Green and reviewed: merge it, or make sure its agent is merging.
   - CONFLICTING: find the files (`git merge-tree --write-tree --name-only origin/main <pr-ref>`) and send the agent the list. "Keep both sides" for append-style lists.
   - A check failed: open the job log, find the failing test, and send the agent the exact test name and error. If it failed outside the agent's code, see `07-ci-operations.md`.
   - `UNKNOWN` for more than one round: check locally with `merge-tree`.
2. **Worktrees:** last commit time, uncommitted file count, unpushed commits, and files changed in the last 30 minutes.
   - No change for 30 minutes and no test running: nudge the agent ("reply in one line with what you're doing").
   - Uncommitted work for hours: tell the agent to commit and push work in progress (power cuts happen).
3. **Runners:** online and busy states. If the remote runners go offline, switch to plan B (`07-ci-operations.md`).
4. **Main's push CI:** catches clashes between PRs that were each green on their own.
5. **The other lane:** use the `partner-check` script, which covers:
   - new comments on the lane-sync channel;
   - every issue and PR in the repo that changed in the window;
   - new comments and PR review comments by others;
   - unread notifications;
   - tickets updated by others.

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
