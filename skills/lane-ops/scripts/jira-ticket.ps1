# Assign a Jira ticket to the token's account, move it to a status, and/or add a comment.
# Reads JIRA_EMAIL, JIRA_API_TOKEN and JIRA_BASE_URL from the process or Windows user environment; never prints the token.
# Usage: pwsh -NoProfile -File jira-ticket.ps1 -Key KEY-28 [-Status "In Progress"] [-Comment "Claimed by draft PR #12 (branch, lane)"]
#        Status is matched against the ticket's available transitions by target name ("To Do", "In Progress", "In Review", "Done").
param(
    [Parameter(Mandatory)] [string] $Key,
    [string] $Status = '',
    [string] $Comment = ''
)
function EnvVar([string] $name) {
    $v = [Environment]::GetEnvironmentVariable($name, 'Process')
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($name, 'User') }
    return $v
}
$e = EnvVar 'JIRA_EMAIL'; $k = EnvVar 'JIRA_API_TOKEN'; $b = EnvVar 'JIRA_BASE_URL'
if (-not ($e -and $k -and $b)) { Write-Error 'JIRA_EMAIL, JIRA_API_TOKEN or JIRA_BASE_URL is not set'; exit 1 }
$h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${e}:${k}")); Accept = 'application/json' }
try {
    $me = Invoke-RestMethod -Uri "$b/rest/api/3/myself" -Headers $h -TimeoutSec 30
    Invoke-RestMethod -Method Put -Uri "$b/rest/api/3/issue/$Key/assignee" -Headers $h -ContentType 'application/json' -Body (@{ accountId = $me.accountId } | ConvertTo-Json) -TimeoutSec 30 | Out-Null
    if ($Status) {
        $tr = (Invoke-RestMethod -Uri "$b/rest/api/3/issue/$Key/transitions" -Headers $h -TimeoutSec 30).transitions | Where-Object { $_.to.name -eq $Status } | Select-Object -First 1
        if ($tr) { Invoke-RestMethod -Method Post -Uri "$b/rest/api/3/issue/$Key/transitions" -Headers $h -ContentType 'application/json' -Body (@{ transition = @{ id = $tr.id } } | ConvertTo-Json) -TimeoutSec 30 | Out-Null }
        else { Write-Warning "no transition to '$Status' from the current status" }
    }
    if ($Comment) {
        $adf = @{ body = @{ type = 'doc'; version = 1; content = @(@{ type = 'paragraph'; content = @(@{ type = 'text'; text = $Comment }) }) } }
        Invoke-RestMethod -Method Post -Uri "$b/rest/api/3/issue/$Key/comment" -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes(($adf | ConvertTo-Json -Depth 10))) -TimeoutSec 30 | Out-Null
    }
    $i = Invoke-RestMethod -Uri "$b/rest/api/3/issue/${Key}?fields=status,assignee,summary" -Headers $h -TimeoutSec 30
    '{0}: [{1}] assignee={2} | {3}' -f $Key, $i.fields.status.name, $i.fields.assignee.displayName, $i.fields.summary
} catch {
    "${Key}: error $($_.Exception.Response.StatusCode) $($_.ErrorDetails.Message)"
    exit 1
}
