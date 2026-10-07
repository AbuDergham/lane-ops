<!-- Fill every <PLACEHOLDER>. Keep the security paragraph specific to the task. Launch with: Agent(description: "[<CODE>] <Title>", model: sonnet, run_in_background: true) -->

Implement task <CODE> · <PLAN-ID> <Title> (ticket <TICKET>) in the <PROJECT> repo, test first. Be economical with tokens, and keep moving.

Sources (binding): the <CODE> section of <LANE_DOC>; <CONTRACT_DOC>, including every amendment note that touches <PLAN-ID> or <its topics>. Implement EVERY file the contract's file list assigns to <PLAN-ID> (report any you skip, with the reason). Also read the <PLAN-ID> row in <PLAN_DOC>, the relevant <SPEC> sections, and <AUDIT_DOC>. <If Closes: Look up <IDs> in <FINDINGS_DOC>; the tests must prove those bug classes cannot happen.> <If follow-ups exist: Read the follow-ups aimed at <PLAN-ID> (grep -rn "target <PLAN-ID>" docs/progress); they are part of this task.> Build on <merged dependencies> exactly as merged (extend, don't duplicate).

Scope: <Build>. Done when: <Done when>.

Security and correctness: <the 6 to 10 concrete expectations for THIS task: tenant source, authorization in service and route, races plus a concurrency test, idempotency, money rules, sanitizing, SSRF, logging, rate limits on ban-sensitive actions, isolation harness coverage, translations>.

PROGRESS NOTES: do NOT edit <FROZEN_PROGRESS_LOG>. Write docs/progress/tasks/<PLAN-ID>.md in the docs/progress/README.md format; the file name must be the exact task ID. New test helpers go in tests/Support/Helpers/<Module>.php. Any deviation from the contract must be justified in your note's Decisions section and applied to the contract in the same PR. After merging main, if the lock files changed, reinstall dependencies in your lane.

COORDINATION: the channel with the other lane is the open issue labelled lane-sync. Before you merge, check it; hold while an other-lane "MERGING #N" line from the last ~30 minutes has no "MERGED #N" yet. Then post "[L2→L1] MERGING #<n>", merge, and post "[L2→L1] MERGED #<n> <sha>". Before creating a shared file (a Support class, a layout block, a seeder, a policy), check the other lane's open draft PRs for the same file. Shared append-style files often conflict: when merging main, keep both sides. If you change a page that a screenshot test covers (for example a new nav item), regenerate that baseline in your lane and say so in your note.

Working style: never wait blindly on a background monitor for more than 5 minutes; check the status directly, and act at once when CI is green. Commit and push work in progress at least every hour. Before marking the PR ready, make sure it is MERGEABLE. Never use rm -rf. Run the affected tests locally with a low process count; CI runs the full suite. Bring your lane stack down whenever you only wait for CI or review. If lane setup fails with "address pools have been fully subnetted", tell the coordinator and keep writing code; never remove Docker networks yourself. Never touch the owner's default dev stack (no installs or migrations there), its database or volumes, or the CI runners. Never open an extra PR without asking the coordinator.

Tickets: after opening the draft PR, run: <TICKET_CMD> -Key <TICKET> -Comment "Claimed by draft PR #<n> (branch <BRANCH>, lane <lane>)." When you mark it ready, run it with -Status "In Review". After it merges, run it with -Status "Done" -Comment "Merged: PR #<n>, main <sha>. CI: <result>. <2 to 3 sentences on what was built and any gaps>."

WHERE: <REPO_PATH> (pull main first). Use a worktree and a lane (<LANE_SETUP_CMD>). Branch <BRANCH>. Claim it right away with a draft PR titled "<type>(<scope>): <title> [<PLAN-ID>] (<TICKET>)". Push the final commit before marking it ready. When CI is green, send the coordinator a message (SendMessage to "main") with the PR number and a 3- or 4-line summary of the risky parts (<list them>). Do NOT merge until it replies "review passed". Then merge with <MERGE_CMD> from the main checkout (re-run on a timeout; on a conflict merge main in, keep both sides, re-test, push), confirm MERGED, pull main, run migrations in the main checkout, and clean up the lane completely: the stack down with volumes; the worktree; the branch; the lane's dependency volumes; its secrets and backup folders; its images; its log files; any watcher you started. Write files with the editor tools, not shell here-strings. Conventional Commits ending with:
<COMMIT_TRAILER>
The PR description ends with:
<PR_FOOTER>

Report in under 60 words: done or blocked; final main commit hash; CI result; skipped files.
