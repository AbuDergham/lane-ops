#!/usr/bin/env bash
# What changed in the last N minutes that the coordinator should know about (bash version; needs gh, jq, curl).
# Shows: the lane-sync channel (others' comments), every issue and PR that changed, new comments and review comments by
# others, GitHub notifications (minus CI noise), and Jira issues updated in the window (optional; never prints the token).
#
# Usage: partner-check.sh -r owner/repo -s your-login [-m 12] [-l lane-sync] [-j JIRAKEY]
# Jira (optional): export JIRA_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL.
set -u
REPO=""; SELF=""; MIN=12; LABEL="lane-sync"; JIRA=""
while getopts "r:s:m:l:j:" o; do case $o in r) REPO=$OPTARG;; s) SELF=$OPTARG;; m) MIN=$OPTARG;; l) LABEL=$OPTARG;; j) JIRA=$OPTARG;; *) exit 2;; esac; done
[ -z "$REPO" ] || [ -z "$SELF" ] && { echo "usage: $0 -r owner/repo -s login [-m min] [-l label] [-j JIRAKEY]"; exit 2; }

if date -u -d "-${MIN} minutes" +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
  ISO=$(date -u -d "-${MIN} minutes" +%Y-%m-%dT%H:%M:%SZ)          # GNU date
else
  ISO=$(date -u -v-"${MIN}"M +%Y-%m-%dT%H:%M:%SZ)                    # BSD/macOS date
fi
echo "partner-check: last $MIN min"

if [ -n "$JIRA" ]; then
  if [ -n "${JIRA_EMAIL:-}" ] && [ -n "${JIRA_API_TOKEN:-}" ] && [ -n "${JIRA_BASE_URL:-}" ]; then
    body=$(jq -n --arg jql "project = $JIRA AND updated >= \"-${MIN}m\" ORDER BY updated DESC" '{jql:$jql, fields:["summary","status","assignee","comment"], maxResults:20}')
    curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H 'Content-Type: application/json' -X POST "$JIRA_BASE_URL/rest/api/3/search/jql" -d "$body" |
      jq -r '.issues[]? | . as $i | ($i.fields.comment.comments | last) as $c |
        "  jira \($i.key) [\($i.fields.status.name)] \($i.fields.summary[0:40]) | \($i.fields.assignee.displayName // "unassigned") | last comment by \($c.author.displayName // "-"): \(([$c.body.content[]?.content[]?.text] | join(" "))[0:90])"' 2>/dev/null || echo "  jira: request failed"
  else echo "  jira: env vars not set"; fi
fi

SYNC=$(gh issue list -R "$REPO" --label "$LABEL" --state open --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$SYNC" ]; then
  gh api "repos/$REPO/issues/$SYNC/comments?since=$ISO" --jq ".[] | select(.user.login != \"$SELF\") | \"  sync #$SYNC \(.created_at[11:16])Z \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:300])\"" 2>/dev/null
else echo "  sync: no open $LABEL issue found"; fi

gh api "repos/$REPO/issues?state=all&sort=updated&since=$ISO&per_page=50" --jq '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"' 2>/dev/null
gh api "repos/$REPO/issues/comments?since=$ISO&per_page=50" --jq ".[] | select(.user.login != \"$SELF\") | select(.issue_url | endswith(\"/${SYNC:-none}\") | not) | \"  comment #\(.issue_url | split(\"/\") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:200])\"" 2>/dev/null
gh api "repos/$REPO/pulls/comments?since=$ISO&per_page=50" --jq ".[] | select(.user.login != \"$SELF\") | \"  review-comment PR #\(.pull_request_url | split(\"/\") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:160])\"" 2>/dev/null
gh api "notifications?all=true&since=$ISO" --jq '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"' 2>/dev/null
