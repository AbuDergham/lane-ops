#!/usr/bin/env bash
# What changed since the last clean round that the coordinator should know about (bash version; needs gh, and GNU or
# BSD date). Sections: the lane-sync channel (others' comments, by id cursor), every issue and PR that changed, new
# comments and PR review comments by others, and GitHub notifications (minus CI noise). It uses only the gh CLI and its
# own sign-in; it reads no credentials itself. For ticket systems (Jira and others), use that system's own CLI.
#
# Output follows the heartbeat format in references/03-heartbeat.md ("Output that can't lie"):
#   - every section ends with "== <section>: ok (<n> new)" or "== ALERT: <SECTION> CHECK FAILED: <reason>";
#   - the last line is "== partner-check: done, <n> alert(s)", and the exit code is 1 when any ALERT was printed;
#   - the window reaches back to the last round without alerts (48 h at most), so a failed or missed round loses nothing;
#   - with -i, it keeps a run stamp and prints "== ALERT: HEARTBEAT GAP" when the last run is older than twice -i.
# State (catch-up mark, channel cursor, run stamp) lives in $LANE_OPS_STATE/<owner>_<repo> (default ~/.lane-ops).
#
# Usage: partner-check.sh -r owner/repo -s your-login [-m 12] [-l lane-sync] [-i heartbeat-interval-min]
set -u
REPO=""; SELF=""; MIN=12; LABEL="lane-sync"; EVERY=""
while getopts "r:s:m:l:i:" o; do case $o in r) REPO=$OPTARG;; s) SELF=$OPTARG;; m) MIN=$OPTARG;; l) LABEL=$OPTARG;; i) EVERY=$OPTARG;; *) exit 2;; esac; done
if [ -z "$REPO" ] || [ -z "$SELF" ]; then echo "usage: $0 -r owner/repo -s login [-m min] [-l label] [-i interval-min]"; exit 2; fi

STATE="${LANE_OPS_STATE:-$HOME/.lane-ops}/${REPO//\//_}"
mkdir -p "$STATE" || { echo "== ALERT: PARTNER-CHECK CHECK FAILED: cannot create its state folder"; echo "== partner-check: done, 1 alert(s)"; exit 1; }
ERRF="$STATE/last-error"
ALERTS=0; FAILS=0
NOW=$(date -u +%s)

iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }
num() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
alert() { echo "== ALERT: $1"; ALERTS=$((ALERTS + 1)); }
# A source that could not be read; only a round that read every source moves the catch-up mark.
fail() { alert "$1"; FAILS=$((FAILS + 1)); }
# Error text fit for a status line: one line, no URLs, IP addresses or tokens, at most 80 characters.
clean() { tr '\r\n' '  ' | sed -E 's#[a-zA-Z]+://[^ ]+#<url>#g; s#[0-9]{1,3}(\.[0-9]{1,3}){3}#<ip>#g; s#(gh[pousr]_|github_pat_)[A-Za-z0-9_]+#<token>#g' | cut -c1-80; }

# A read through gh: a 30 s timeout and one retry after 5 s. Prints gh's output and succeeds, or leaves the cleaned
# error in $ERRF and fails. Only reads go through here; a write is never retried blindly.
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout 30"
read_gh() {
  local try out rc
  for try in 1 2; do
    out=$($TO gh "$@" 2>"$ERRF.raw"); rc=$?
    if [ $rc -eq 0 ]; then printf '%s' "$out"; return 0; fi
    { cat "$ERRF.raw"; [ $rc -eq 124 ] && echo "timed out after 30 s"; [ -s "$ERRF.raw" ] || echo "gh exited $rc"; } | clean > "$ERRF"
    [ $try -eq 1 ] && sleep 5
  done
  return 1
}
# One section: the read's lines, then its status line. "0 new" only ever comes from a read that succeeded.
section() {
  local name=$1 out n=0; shift
  if out=$(read_gh "$@"); then
    if [ -n "$out" ]; then printf '%s\n' "$out"; n=$(printf '%s\n' "$out" | wc -l | tr -d ' '); fi
    echo "== $name: ok ($n new)"
  else
    fail "$(upper "$name") CHECK FAILED: $(cat "$ERRF")"
  fi
}

# The heartbeat's own run stamp (with -i): a dead timer can't report itself, so the next run does.
if [ -n "$EVERY" ]; then
  LAST=$(num "$(cat "$STATE/last-run" 2>/dev/null)" "")
  if [ -n "$LAST" ]; then
    AGO=$(( (NOW - LAST) / 60 ))
    echo "== heartbeat: last run $(iso "$LAST" | cut -c12-16)Z ($AGO min ago)"
    [ "$AGO" -gt $((EVERY * 2)) ] && alert "HEARTBEAT GAP: $AGO min"
  else
    echo "== heartbeat: first run"
  fi
  echo "$NOW" > "$STATE/last-run"
fi

# The window: the last -m minutes, or back to the last round without alerts when that is older (48 h at most).
FROM=$((NOW - MIN * 60))
MARK=$(num "$(cat "$STATE/mark" 2>/dev/null)" "$FROM")
[ "$MARK" -lt "$FROM" ] && FROM=$MARK
[ "$FROM" -lt $((NOW - 48 * 3600)) ] && FROM=$((NOW - 48 * 3600))
ISO=$(iso "$FROM")
echo "partner-check: $REPO since ${ISO:11:5}Z $(( (NOW - FROM) / 60 )) min"

# The lane-sync channel: others' comments after the id cursor, every page.
if SYNC=$(read_gh issue list -R "$REPO" --label "$LABEL" --state open --json number --jq '.[0].number'); then
  if [ -z "$SYNC" ]; then
    echo "== sync: ok (no open $LABEL issue)"
  else
    CUR=$(num "$(cat "$STATE/sync-cursor" 2>/dev/null)" 0)
    if ROWS=$(read_gh api --paginate "repos/$REPO/issues/$SYNC/comments?since=$ISO&per_page=100" \
        --jq ".[] | select(.id > $CUR) | \"\(.id)\t\(.user.login)\t\(.created_at[11:16])Z\t\(.body | gsub(\"[\r\n]+\"; \" / \") | .[0:300])\""); then
      N=0
      if [ -n "$ROWS" ]; then
        OTHERS=$(printf '%s\n' "$ROWS" | awk -F'\t' -v me="$SELF" -v n="$SYNC" '$2 != me { printf "  sync #%s %s %s: %s\n", n, $3, $2, $4 }')
        [ -n "$OTHERS" ] && { printf '%s\n' "$OTHERS"; N=$(printf '%s\n' "$OTHERS" | wc -l | tr -d ' '); }
        CUR=$(printf '%s\n' "$ROWS" | cut -f1 | sort -n | tail -1)
        echo "$CUR" > "$STATE/sync-cursor"
      fi
      echo "== sync #$SYNC: ok ($N new, cursor=$CUR)"
    else
      fail "SYNC CHECK FAILED: $(cat "$ERRF")"
    fi
  fi
else
  fail "SYNC CHECK FAILED: $(cat "$ERRF")"
  SYNC=""
fi

# Every issue and PR that changed in the window (both lanes).
section repo api --paginate "repos/$REPO/issues?state=all&sort=updated&since=$ISO&per_page=100" \
  --jq '.[] | "  \(if .pull_request then "pr" else "issue" end) #\(.number) [\(.state)\(if .pull_request.merged_at then ",merged" else "" end)] \(.user.login): \(.title[0:60]) (upd \(.updated_at[11:16])Z)"'

# New comments by others on any issue or PR (the channel is shown above), and PR review comments.
section comments api --paginate "repos/$REPO/issues/comments?since=$ISO&per_page=100" \
  --jq ".[] | select(.user.login != \"$SELF\") | select(.issue_url | endswith(\"/${SYNC:-none}\") | not) | \"  comment #\(.issue_url | split(\"/\") | last) \(.created_at[11:16])Z \(.user.login): \(.body | gsub(\"[\r\n]+\"; \" / \") | .[0:200])\""
section review-comments api --paginate "repos/$REPO/pulls/comments?since=$ISO&per_page=100" \
  --jq ".[] | select(.user.login != \"$SELF\") | \"  review-comment PR #\(.pull_request_url | split(\"/\") | last) \(.path):\(.line // .original_line) \(.user.login): \(.body | gsub(\"[\r\n]+\"; \" / \") | .[0:160])\""

# Notifications in the window, without CI noise.
section notifications api --paginate "notifications?all=true&since=$ISO" \
  --jq '.[] | select(.reason != "ci_activity") | "  gh \(.reason) \(.subject.type): \(.subject.title[0:70]) (\(.updated_at[11:16])Z)"'

# Only a round that read every source moves the catch-up mark (a heartbeat gap alone does not hold it back).
[ $FAILS -eq 0 ] && echo "$NOW" > "$STATE/mark"
rm -f "$ERRF.raw"
echo "== partner-check: done, $ALERTS alert(s)"
exit $(( ALERTS > 0 ? 1 : 0 ))
