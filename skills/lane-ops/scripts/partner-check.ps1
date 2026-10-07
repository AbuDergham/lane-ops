# What changed in the last N minutes that the coordinator should know about. Used on every heartbeat.
# Shows: the lane-sync channel (others' comments), every issue and PR in the repo that changed, new comments and PR review
# comments by others, GitHub notifications (minus CI noise), and Jira issues updated in the window (optional).
# Prints only the header when nothing changed. A Jira token is read from env vars and never printed.
#
# Usage: pwsh -NoProfile -File partner-check.ps1 -Repo owner/repo -Self your-login [-Minutes 12] [-SyncLabel lane-sync] [-JiraProject KEY]
# Jira (optional): set JIRA_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL (Windows user env vars or process env).
param(
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Self,
    [int] $Minutes = 12,
    [string] $SyncLabel = 'lane-sync',
    [string] $JiraProject = ''
)

function EnvVar([string] $name) {
    $v = [Environment]::GetEnvironmentVariable($name, 'Process')
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($name, 'User') }
    return $v
}

$since = (Get-Date).ToUniversalTime().AddMinutes(-$Minutes)
$iso = $since.ToString('yyyy-MM-ddTHH:mm:ssZ')
"partner-check: last $Minutes min"

# Jira: issues updated in the window, with the last comment's author and first words.
if ($JiraProject) {
    $e = EnvVar 'JIRA_EMAIL'; $k = EnvVar 'JIRA_API_TOKEN'; $b = EnvVar 'JIRA_BASE_URL'
    if ($e -and $k -and $b) {
        $h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${e}:${k}")); Accept = 'application/json'; 'Content-Type' = 'application/json' }
        $body = @{ jql = "project = $JiraProject AND updated >= `"-${Minutes}m`" ORDER BY updated DESC"; fields = @('summary', 'status', 'assignee', 'comment'); maxResults = 20 } | ConvertTo-Json
        try {
            $r = Invoke-RestMethod -Method Post -Uri "$b/rest/api/3/search/jql" -Headers $h -Body $body -TimeoutSec 30
            foreach ($i in $r.issues) {
                $c = $i.fields.comment.comments | Select-Object -Last 1
                $who = if ($c) { $c.author.displayName } else { '-' }
                $txt = if ($c) { (($c.body.content | ForEach-Object { $_.content } | ForEach-Object { $_.text }) -join ' ') } else { '' }
                $txt = $txt.Substring(0, [Math]::Min(90, $txt.Length))
                $as = if ($i.fields.assignee) { $i.fields.assignee.displayName } else { 'unassigned' }
                $sum = $i.fields.summary.Substring(0, [Math]::Min(40, $i.fields.summary.Length))
                "  jira {0} [{1}] {2} | {3} | last comment by {4}: {5}" -f $i.key, $i.fields.status.name, $sum, $as, $who, $txt
            }
        } catch { "  jira: request failed" }
    } else { "  jira: env vars not set" }
}

# The lane-sync channel: others' comments in the window.
$sync = gh issue list -R $Repo --label $SyncLabel --state open --json number --jq '.[0].number' 2>$null
if ($sync) {
    gh api "repos/$Repo/issues/$sync/comments?since=$iso" --jq ".[] | select(.user.login != `"$Self`") | `"  sync #$sync \(.created_at[11:16])Z \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:300])`"" 2>$null
} else { "  sync: no open $SyncLabel issue found" }

# Every issue and PR that changed in the window (both lanes).
gh api "repos/$Repo/issues?state=all&sort=updated&since=$iso&per_page=50" --jq '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"' 2>$null

# New comments by others on any issue or PR (the channel is shown above), and PR review comments.
gh api "repos/$Repo/issues/comments?since=$iso&per_page=50" --jq ".[] | select(.user.login != `"$Self`") | select(.issue_url | endswith(`"/$sync`") | not) | `"  comment #\(.issue_url | split(`"/`") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:200])`"" 2>$null
gh api "repos/$Repo/pulls/comments?since=$iso&per_page=50" --jq ".[] | select(.user.login != `"$Self`") | `"  review-comment PR #\(.pull_request_url | split(`"/`") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(`"\n`"; `" / `") | .[0:160])`"" 2>$null

# Notifications in the window, without CI noise.
gh api "notifications?all=true&since=$iso" --jq '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"' 2>$null
