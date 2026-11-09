# What changed since the last clean round that the coordinator should know about. Used on every heartbeat.
# Sections: the lane-sync channel (others' comments, by id cursor), every issue and PR in the repo that changed, new
# comments and PR review comments by others, and GitHub notifications (minus CI noise). It uses only the gh CLI and its
# own sign-in; it reads no credentials itself. For ticket systems (Jira and others), use that system's own CLI.
#
# Output follows the heartbeat format in references/03-heartbeat.md ("Output that can't lie"):
#   - every section ends with "== <section>: ok (<n> new)" or "== ALERT: <SECTION> CHECK FAILED: <reason>";
#   - the last line is "== partner-check: done, <n> alert(s)", and the exit code is 1 when any ALERT was printed;
#   - the window reaches back to the last round without alerts (48 h at most), so a failed or missed round loses nothing;
#   - with -Interval, it keeps a run stamp and prints "== ALERT: HEARTBEAT GAP" when the last run is older than twice it.
# State (catch-up mark, channel cursor, run stamp) lives in $env:LANE_OPS_STATE\<owner>_<repo> (default ~\.lane-ops).
#
# Usage: pwsh -NoProfile -File partner-check.ps1 -Repo owner/repo -Self your-login [-Minutes 12] [-SyncLabel lane-sync]
#        [-Interval heartbeat-minutes]
param(
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Self,
    [int] $Minutes = 12,
    [string] $SyncLabel = 'lane-sync',
    [int] $Interval = 0
)

[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = if ($env:LANE_OPS_STATE) { $env:LANE_OPS_STATE } else { Join-Path $HOME '.lane-ops' }
$state = Join-Path $root ($Repo -replace '/', '_')
New-Item -ItemType Directory -Force -Path $state | Out-Null
$script:alerts = 0
$script:fails = 0
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function Alert([string] $text) { "== ALERT: $text"; $script:alerts++ }
# A source that could not be read; only a round that read every source moves the catch-up mark.
function Fail([string] $text) { Alert $text; $script:fails++ }
function StateNum([string] $name, $default) {
    $p = Join-Path $state $name
    if (Test-Path $p) { $v = (Get-Content $p -Raw).Trim(); if ($v -match '^\d+$') { return [long]$v } }
    return $default
}
function SetState([string] $name, $value) { Set-Content -Path (Join-Path $state $name) -Value $value -NoNewline }
function Hhmm([long] $unix) { [DateTimeOffset]::FromUnixTimeSeconds($unix).UtcDateTime.ToString('HH:mm') + 'Z' }
# Error text fit for a status line: one line, no URLs, IP addresses or tokens, at most 80 characters.
function Clean([string] $text) {
    $t = ($text -replace '[\r\n]+', ' ') -replace '[a-zA-Z]+://\S+', '<url>' -replace '\d{1,3}(\.\d{1,3}){3}', '<ip>' -replace '(gh[pousr]_|github_pat_)\w+', '<token>'
    $t.Substring(0, [Math]::Min(80, $t.Length))
}

# A read through gh: a 30 s timeout and one retry after 5 s. Returns @{ ok; out; err }. Only reads go through here;
# a write is never retried blindly.
function ReadGh([string[]] $ghArgs) {
    $err = ''
    foreach ($try in 1, 2) {
        # gh speaks UTF-8; stdout and stderr are told apart inside the job, before they lose their types.
        $job = Start-Job -ScriptBlock {
            param($a)
            [Console]::OutputEncoding = [Text.Encoding]::UTF8
            $o = & gh @a 2>&1 | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { "E $_" } else { "O $_" } }
            [pscustomobject]@{ code = $LASTEXITCODE; out = @($o) }
        } -ArgumentList (, $ghArgs)
        if (Wait-Job $job -Timeout 30) {
            $r = Receive-Job $job; Remove-Job $job
            $lines = @($r.out | Where-Object { $_.StartsWith('O ') } | ForEach-Object { $_.Substring(2) })
            $errs = @($r.out | Where-Object { $_.StartsWith('E ') } | ForEach-Object { $_.Substring(2) })
            if ($r.code -eq 0) { return @{ ok = $true; out = $lines } }
            $err = if ($errs) { $errs -join ' ' } else { "gh exited $($r.code)" }
        } else {
            Stop-Job $job; Remove-Job $job -Force; $err = 'timed out after 30 s'
        }
        if ($try -eq 1) { Start-Sleep -Seconds 5 }
    }
    return @{ ok = $false; err = (Clean $err) }
}
# One section: the read's lines, then its status line. "0 new" only ever comes from a read that succeeded.
function Section([string] $name, [string[]] $ghArgs) {
    $r = ReadGh $ghArgs
    if ($r.ok) { $lines = @($r.out | Where-Object { $_ }); $lines; "== ${name}: ok ($($lines.Count) new)" }
    else { Fail "$($name.ToUpper()) CHECK FAILED: $($r.err)" }
}

# The heartbeat's own run stamp (with -Interval): a dead timer can't report itself, so the next run does.
if ($Interval -gt 0) {
    $last = StateNum 'last-run' $null
    if ($null -ne $last) {
        $ago = [math]::Floor(($now - $last) / 60)
        "== heartbeat: last run $(Hhmm $last) ($ago min ago)"
        if ($ago -gt 2 * $Interval) { Alert "HEARTBEAT GAP: $ago min" }
    } else { '== heartbeat: first run' }
    SetState 'last-run' $now
}

# The window: the last -Minutes, or back to the last round without alerts when that is older (48 h at most).
$from = $now - 60 * $Minutes
$from = [math]::Max([math]::Min($from, (StateNum 'mark' $from)), $now - 48 * 3600)
$iso = [DateTimeOffset]::FromUnixTimeSeconds($from).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
"partner-check: $Repo since $(Hhmm $from) $([math]::Floor(($now - $from) / 60)) min"

# The lane-sync channel: others' comments after the id cursor, every page.
$sync = ''
$r = ReadGh @('issue', 'list', '-R', $Repo, '--label', $SyncLabel, '--state', 'open', '--json', 'number', '--jq', '.[0].number')
if (-not $r.ok) { Fail "SYNC CHECK FAILED: $($r.err)" }
elseif (-not ($r.out -join '').Trim()) { "== sync: ok (no open $SyncLabel issue)" }
else {
    $sync = ($r.out -join '').Trim()
    $cur = StateNum 'sync-cursor' 0
    $rows = ReadGh @('api', '--paginate', "repos/$Repo/issues/$sync/comments?since=$iso&per_page=100", '--jq',
        ".[] | select(.id > $cur) | `"\(.id)\t\(.user.login)\t\(.created_at[11:16])Z\t\(.body | gsub(`"[\r\n]+`"; `" / `") | .[0:300])`"")
    if (-not $rows.ok) { Fail "SYNC CHECK FAILED: $($rows.err)" }
    else {
        $n = 0
        foreach ($row in @($rows.out | Where-Object { $_ })) {
            $f = $row -split "`t", 4
            if ([long]$f[0] -gt $cur) { $cur = [long]$f[0] }
            if ($f[1] -ne $Self) { "  sync #$sync $($f[2]) $($f[1]): $($f[3])"; $n++ }
        }
        SetState 'sync-cursor' $cur
        "== sync #${sync}: ok ($n new, cursor=$cur)"
    }
}

# Every issue and PR that changed in the window (both lanes).
Section 'repo' @('api', '--paginate', "repos/$Repo/issues?state=all&sort=updated&since=$iso&per_page=100", '--jq',
    '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"')

# New comments by others on any issue or PR (the channel is shown above), and PR review comments.
$syncKey = if ($sync) { $sync } else { 'none' }
Section 'comments' @('api', '--paginate', "repos/$Repo/issues/comments?since=$iso&per_page=100", '--jq',
    ".[] | select(.user.login != `"$Self`") | select(.issue_url | endswith(`"/$syncKey`") | not) | `"  comment #\(.issue_url | split(`"/`") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(`"[\r\n]+`"; `" / `") | .[0:200])`"")
Section 'review-comments' @('api', '--paginate', "repos/$Repo/pulls/comments?since=$iso&per_page=100", '--jq',
    ".[] | select(.user.login != `"$Self`") | `"  review-comment PR #\(.pull_request_url | split(`"/`") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(`"[\r\n]+`"; `" / `") | .[0:160])`"")

# Notifications in the window, without CI noise.
Section 'notifications' @('api', '--paginate', "notifications?all=true&since=$iso", '--jq',
    '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"')

# Only a round that read every source moves the catch-up mark (a heartbeat gap alone does not hold it back).
if ($script:fails -eq 0) { SetState 'mark' $now }
"== partner-check: done, $($script:alerts) alert(s)"
exit ([int]($script:alerts -gt 0))
