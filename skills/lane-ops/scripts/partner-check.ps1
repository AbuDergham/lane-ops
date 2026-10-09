# What changed in the last N minutes that the coordinator should know about. Used on every heartbeat.
# Shows: the lane-sync channel (others' comments), every issue and PR in the repo that changed, new comments and PR review
# comments by others, and GitHub notifications (minus CI noise). It uses only the gh CLI and its own sign-in; it reads no
# credentials itself. For ticket systems (Jira and others), use that system's own CLI, which manages its own sign-in.
#
# Usage: pwsh -NoProfile -File partner-check.ps1 -Repo owner/repo -Self your-login [-Minutes 12] [-SyncLabel lane-sync]
param(
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Self,
    [int] $Minutes = 12,
    [string] $SyncLabel = 'lane-sync'
)

$iso = (Get-Date).ToUniversalTime().AddMinutes(-$Minutes).ToString('yyyy-MM-ddTHH:mm:ssZ')
"partner-check: last $Minutes min"

# The lane-sync channel: others' comments in the window.
$sync = gh issue list -R $Repo --label $SyncLabel --state open --json number --jq '.[0].number' 2>$null
if ($sync) {
    gh api --paginate "repos/$Repo/issues/$sync/comments?since=$iso&per_page=100" --jq ".[] | select(.user.login != `"$Self`") | `"  sync #$sync \(.created_at[11:16])Z \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:300])`"" 2>$null
} else { "  sync: no open $SyncLabel issue found" }

# Every issue and PR that changed in the window (both lanes).
gh api "repos/$Repo/issues?state=all&sort=updated&since=$iso&per_page=50" --jq '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"' 2>$null

# New comments by others on any issue or PR (the channel is shown above), and PR review comments.
gh api "repos/$Repo/issues/comments?since=$iso&per_page=50" --jq ".[] | select(.user.login != `"$Self`") | select(.issue_url | endswith(`"/$sync`") | not) | `"  comment #\(.issue_url | split(`"/`") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:200])`"" 2>$null
gh api "repos/$Repo/pulls/comments?since=$iso&per_page=50" --jq ".[] | select(.user.login != `"$Self`") | `"  review-comment PR #\(.pull_request_url | split(`"/`") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:160])`"" 2>$null

# Notifications in the window, without CI noise.
gh api "notifications?all=true&since=$iso" --jq '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"' 2>$null
