The single channel between the two lane coordinators (Lane 1: <L1_ACCOUNT>, Lane 2: <L2_ACCOUNT>). Humans and longer discussions belong in PRs or their own issues; post a link here.

## Finding the channel

There is always **exactly one open issue labelled `lane-sync`**:

```
gh issue list -R <OWNER>/<REPO> --label lane-sync --state open --json number,title
```

## Message format

One comment per message. The first line is the tag.

| Tag | Use | Reply expected |
| --- | --- | --- |
| `[L1→L2] MERGING #N` / `[L2→L1] MERGING #N` | about to run the merge | no |
| `[Lx→Ly] MERGED #N <sha>` | merged | no |
| `[Lx→Ly] ASK-<n>: <question>` | needs an answer or action from the other lane | yes: `ANSWER-<n>`, or at least `ACK-<n>`, within one heartbeat |
| `[Ly→Lx] ANSWER-<n>: <answer>` | answers ASK-<n> | no |
| `[Ly→Lx] ACK-<n>` | seen, working on it; the ANSWER follows | no |
| `[Lx→Ly] ALERT: <what>` | main red, runners down, a security issue, anything blocking both lanes | ACK |
| `[Lx→Ly] INFO: <what>` | a heads-up: a shared-file change, a CI mode switch, a correction | no |
| `[Lx→Ly] HOTFIX-<n> CLAIMED: <title>` | claims the next free hotfix number | no |

- Lane 1 numbers its ASKs with odd numbers, Lane 2 with even numbers.
- Keep each message to a few lines; put details behind a link.
- Decisions that need a human say so: `ASK-<n> (needs owner)`.

## Merging by turns

Before merging, read this issue. If the other lane posted `MERGING #N` in the last ~30 minutes without a `MERGED #N`, wait. Post `MERGING` before you merge and `MERGED <sha>` right after.

## Heartbeat

Each coordinator checks this issue every 10 minutes, and reads only the comments newer than its last check:

```
gh api "repos/<OWNER>/<REPO>/issues/<N>/comments?since=<ISO time>"
```

## Rotation

Rotate weekly (Monday) or at about 50 comments:
1. Open the new issue with this text.
2. Copy open ASKs into its first comment.
3. Post `INFO: rotated to #<new>` here, and close this issue.
