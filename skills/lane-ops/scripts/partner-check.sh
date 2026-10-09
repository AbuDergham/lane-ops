#!/usr/bin/env bash
# What changed in the last N minutes that the coordinator should know about (bash version; needs gh and jq).
# Shows: the lane-sync channel (others' comments), every issue and PR that changed, new comments and review comments by
# others, and GitHub notifications (minus CI noise). It uses only the gh CLI and its own sign-in; it reads no credentials
# itself. For ticket systems (Jira and others), use that system's own CLI, which manages its own sign-in.
#
# Usage: partner-check.sh -r owner/repo -s your-login [-m 12] [-l lane-sync]
set -u
REPO=""; SELF=""; MIN=12; LABEL="lane-sync"
while getopts "r:s:m:l:" o; do case $o in r) REPO=$OPTARG;; s) SELF=$OPTARG;; m) MIN=$OPTARG;; l) LABEL=$OPTARG;; *) exit 2;; esac; done
if [ -z "$REPO" ] || [ -z "$SELF" ]; then echo "usage: $0 -r owner/repo -s login [-m min] [-l label]"; exit 2; fi

if date -u -d "-${MIN} minutes" +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
  ISO=$(date -u -d "-${MIN} minutes" +%Y-%m-%dT%H:%M:%SZ)          # GNU date
else
  ISO=$(date -u -v-"${MIN}"M +%Y-%m-%dT%H:%M:%SZ)                    # BSD/macOS date
fi
echo "partner-check: last $MIN min"

SYNC=$(gh issue list -R "$REPO" --label "$LABEL" --state open --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$SYNC" ]; then
  gh api --paginate "repos/$REPO/issues/$SYNC/comments?since=$ISO&per_page=100" --jq ".[] | select(.user.login != \"$SELF\") | \"  sync #$SYNC \(.created_at[11:16])Z \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:300])\"" 2>/dev/null
else echo "  sync: no open $LABEL issue found"; fi

gh api "repos/$REPO/issues?state=all&sort=updated&since=$ISO&per_page=50" --jq '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"' 2>/dev/null
gh api "repos/$REPO/issues/comments?since=$ISO&per_page=50" --jq ".[] | select(.user.login != \"$SELF\") | select(.issue_url | endswith(\"/${SYNC:-none}\") | not) | \"  comment #\(.issue_url | split(\"/\") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:200])\"" 2>/dev/null
gh api "repos/$REPO/pulls/comments?since=$ISO&per_page=50" --jq ".[] | select(.user.login != \"$SELF\") | \"  review-comment PR #\(.pull_request_url | split(\"/\") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(\"\n\"; \" / \") | .[0:160])\"" 2>/dev/null
gh api "notifications?all=true&since=$ISO" --jq '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"' 2>/dev/null
