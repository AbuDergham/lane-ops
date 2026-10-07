# Implementers

## Launching

- Use the Agent tool in the background, with `model: sonnet` unless the task is unusually subtle. Set `description: "[CODE] Title"`.
- Fill the prompt from `templates/implementer-prompt.md`. Include:
  - the binding sources;
  - the full scope, Done-when and Closes;
  - the security expectations specific to this task (spell them out; don't just say "be secure");
  - the progress-note rule;
  - the coordination rules;
  - the working-style rules below;
  - the ticket commands;
  - the exact branch, PR title and lane setup;
  - the merge-after-"review passed" gate;
  - the full cleanup list;
  - the commit and PR attribution lines;
  - a short report format ("under 60 words").
- Move the ticket to In Progress when you launch.

## Working-style rules (put them in every prompt)

- **Test first.** Tests must fail without the change. A Closes item needs a test that makes the bug class impossible.
- **Never wait blindly** on a background monitor for more than 5 minutes; check the state directly, and act as soon as CI is green.
- **Commit and push work in progress at least every hour.**
- **MERGEABLE before ready:** a conflicting PR gets no CI, so merge main first.
- After merging main, if the lock files changed, reinstall dependencies in the lane. A stale vendor or `node_modules` volume breaks local runs.
- **Bring the lane stack down** whenever you only wait for CI or review (`down --remove-orphans`, keeping the volumes).
- Run only the affected test groups locally (with a low process count when other lanes run). CI runs the full suite.
- Write files with the editor tools, not shell here-strings: PowerShell backticks have corrupted code spans before.
- Never `rm -rf`; use unique temporary folders. Never remove Docker networks or other projects' resources. Never install or migrate in the owner's default stack. Never open an extra PR without asking the coordinator.
- If lane setup fails with "address pools have been fully subnetted", tell the coordinator and keep writing code.

## The lane lifecycle

1. `git worktree add ../repo-<lane> -b <branch> origin/main`, then the project's lane setup (its own compose project name, port offset, database, cache prefix and secrets folder).
2. Claim the task with a draft PR and a ticket comment. Build, test and push.
3. Mark the PR ready, then message the coordinator with the PR number and a 3- or 4-line summary of the risky parts.
4. After "review passed", follow the merge protocol (`02-coordination.md`): pull main, run migrations in the main checkout, set the ticket to Done with a comment.
5. **Full cleanup:**
   - the stack down with volumes;
   - the worktree and the local and remote branch;
   - the lane's dependency volumes;
   - the lane's secrets and backup folders;
   - the lane's images;
   - its log files;
   - any background watcher it started.

## Talking to running agents

- `SendMessage` to the agent ID resumes it with its whole context. That is cheaper than a new agent for follow-ups (review fixes, conflict lists, a related small fix).
- Make messages precise: the failing test name and error, the conflicting file list, line numbers, and the next step. End with what it should do after that ("merge when green, following the protocol").
- If you already said "review passed after these fixes", say it again when you check the fix. Agents wait for the literal phrase.
- When you tell an agent something wrong (for example the wrong PR number for a fix), correct it at once.
- An agent that "finished" with background work still running may resume by itself. If it has been silent for more than 30 minutes, nudge it.
- If an agent stops to explain a risky command it ran (for example a delete in a temporary folder), tell it to carry on safely and repeat the rule. Don't leave it hanging.

## When agents go out of scope

- An unrequested extra PR: review it like any other. If it's valid, let the agent merge it, and remind it to ask first next time.
- Changes to the other lane's modules: allowed only at the call sites the contract assigns to the task. Otherwise, ask the partner on the channel.
- A product-behaviour change that differs from your brief but follows the contract (for example "fail queued sends" instead of "hold and release" on suspension): the contract wins. Tell the owner as an FYI, and make it a contract change if they want otherwise.
