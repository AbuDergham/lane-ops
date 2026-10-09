# The review gate

Every PR passes an independent review before it merges. The gate has caught real bugs that CI missed: a rate limit that could be raced, a code that could leak into logs, cross-tenant notification leaks, a missing index behind keyset pagination, a "pay to reactivate" message on suspensions that payment can't lift, a suspended account still allowed through the API, and a catch block that deleted files whose rows had already committed. The light tier (one reviewer plus a skeptic for majors) kept finding real bugs run after run.

## Tiers

| PR kind | Review |
| --- | --- |
| Small fix, docs, tests only, a small follow-up | Read the diff yourself (`git diff origin/main...<pr-ref>`) |
| Feature with no sensitive surface | Read the core files yourself; use the light workflow if it is large |
| Security, auth, money, tenancy, public API, sanitizers, admin actions, rate limits | `scripts/pr-review-light.js`: one reviewer covering conformance, tests and security, then a skeptic only for majors and blockers |

- The implementer messages you when it marks the PR ready. Start the review then, **in parallel with CI**; don't wait for green. Say "review passed" only once CI is green on a head that includes the current main.
- **Majors:** send them all, with file, line, scenario and fix. When the fix comes back, review **only the delta** (the diff from the reviewed head to the new head) and the key lines of the major fix, then say "review passed". Don't review the whole PR again.
- **Minors only:** say "review passed after these fixes; no re-review needed", and let the agent merge when green.
- Findings go in one message, so the agent fixes them in **one push** (each push costs a CI round).

## Running the light workflow

```text
Workflow({ scriptPath: "<tools>/pr-review-light.js",
           args: { pr: <n>, repo: "<path>", task: "<task code and title>: <binding sources>. Check especially: <the 6-10 risks specific to this task>" } })
```

Put the task-specific risks in `task`. The reviewer is only as good as the brief.

## What to look for (checklist)

- **Tenant isolation:** the tenant comes from the session or token, never from a request parameter. IDs from another tenant answer 404. New routes, jobs and API endpoints are in the isolation harness.
- **Authorization:** checked in the service as well as the route. Destructive admin actions get step-up or re-auth.
- **Races:** check-then-act on shared state goes under a lock or an atomic conditional update, proven by a concurrency test that loops. Framework rate limiters can lose a hit on the very first increment, so use locks for hard caps.
- **Idempotency:** writes, payment fulfilment and webhook replays can't double-apply.
- **Money:** integer minor units per currency (including currencies with 3 decimals), one rounding, tax through one engine, immutable order snapshots, gap-free invoice numbers allocated inside the transaction.
- **Input and output:** allow-list HTML sanitizing (on save and render), SSRF checks on any user-supplied URL (including non-canonical IPs and names that resolve to loopback), encoded JSON-LD, escaped XML.
- **Secrets and logs:** codes, tokens and SQL bindings never reach logs or exception chains.
- **Cleanup in catch blocks:** a catch that deletes stored files must not also wrap after-commit callbacks. Otherwise a failed notification deletes files whose rows already committed. This class came back three times across two lanes.
- **Provider-ban-sensitive actions** (calls to external providers that can suspend you): rate-limit them per account or per resource, on every entry point (web and API).
- **Performance traps:** keyset pagination needs an index behind its order. Watch for N+1 queries and full-table counts on hot paths.
- **User messages:** don't tell users to do something that can't work (for example "pay to unlock" for a non-billing suspension). Don't disclose internal reasons (for example "abuse") in page data.
- **Tests:** they fail without the change; they don't depend on the time of day, shared fixtures or test order; they derive enumerations from the registry instead of pinning a shared list; and screenshot baselines are updated when a page changes on purpose.

**When a bug class repeats,** name it in your reviews of the other lane's PRs too, and add it to this checklist and to the reviewer's brief.

## Big mechanical refactors

- For a refactor across hundreds of files (for example splitting a shared enum or registry into per-module files), ask the implementer for a **mechanical equivalence proof** instead of reading line by line: a before/after comparison of every value, label and merged text array, plus the keys of the built front-end bundle.
- Check consumers that parse files statically, not only code that executes them (`06-conflict-avoidance.md`).

## Reviewing the other lane's PRs

- The owning lane reviews any of its tasks that the other lane builds, before merge (`01-lanes-and-tasks.md`).
- **Don't approve drafts on the forge.** If the other lane calls a PR a draft for joint review, comment instead of approving. If you approved early, dismiss your review, so it can't merge before both owners sign off.

## Plans and contracts

Review rounds on a plan or contract converge. **Cap them at two or three.** After that, fix only cross-lane items and regressions before merge, and record the rest as "settled by the implementing task in its decisions log, by agreement".

## Reading a diff quickly yourself

```bash
git fetch -q origin +pull/<n>/head:refs/remotes/review/pr<n>
git diff --stat origin/main...review/pr<n> | tail -1
git show review/pr<n>:<path> | sed -n '/function handle/,/^    }/p'
git diff <reviewed-sha>..review/pr<n>   # only the delta since your last review
```
