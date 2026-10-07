# The review gate

Every PR passes an independent review before it merges. The gate has caught real bugs that CI missed: a rate limit that could be raced, a code that could leak into logs, cross-tenant notification leaks, a missing index behind keyset pagination, a "pay to reactivate" message on suspensions that payment can't lift, and a suspended account still allowed through the API.

## Tiers

| PR kind | Review |
| --- | --- |
| Small fix, docs, tests only, a small follow-up | Read the diff yourself (`git diff origin/main...<pr-ref>`) |
| Feature with no sensitive surface | Read the core files yourself; use the light workflow if it is large |
| Security, auth, money, tenancy, public API, sanitizers, admin actions, rate limits | `scripts/pr-review-light.js`: one reviewer covering conformance, tests and security, then a skeptic only for majors and blockers |

- Run the review **in parallel with CI**, as soon as the PR is ready. Don't wait for green.
- **Majors:** send them all, with file, line, scenario and fix. When the fix comes back, read its diff yourself, then say "review passed".
- **Minors only:** say "review passed after these fixes; no re-review needed", and let the agent merge when green.
- Findings go in one message, so the agent fixes them in **one push** (each push costs a CI round).

## Running the light workflow

```text
Workflow({ scriptPath: "<tools>/pr-review-light.js",
           args: { pr: 148, repo: "<path>", task: "<task code and title>: <binding sources>. Check especially: <the 6-10 risks specific to this task>" } })
```

Put the task-specific risks in `task`. The reviewer is only as good as the brief.

## What to look for (checklist)

- **Tenant isolation:** the tenant comes from the session or token, never from a request parameter. IDs from another tenant answer 404. New routes, jobs and API endpoints are in the isolation harness.
- **Authorization:** checked in the service as well as the route. Destructive admin actions get step-up or re-auth.
- **Races:** check-then-act on shared state goes under a lock or an atomic conditional update, proven by a concurrency test that loops. Framework rate limiters can lose a hit on the very first increment, so use locks for hard caps.
- **Idempotency:** writes, payment fulfilment and webhook replays can't double-apply.
- **Money:** integer minor units per currency (3 decimals for JOD), one rounding, tax through one engine, immutable order snapshots, gap-free invoice numbers allocated inside the transaction.
- **Input and output:** allow-list HTML sanitizing (on save and render), SSRF checks on any user-supplied URL (including non-canonical IPs and names that resolve to loopback), encoded JSON-LD, escaped XML.
- **Secrets and logs:** codes, tokens and SQL bindings never reach logs or exception chains.
- **Provider-ban-sensitive actions** (messaging providers): rate-limit them per account and per number, on every entry point (web and API).
- **Performance traps:** keyset pagination needs an index behind its order. Watch for N+1 queries and full-table counts on hot paths.
- **User messages:** don't tell users to do something that can't work (for example "pay to unlock" for a non-billing suspension). Don't disclose internal reasons (for example "abuse") in page data.
- **Tests:** they fail without the change; they don't depend on the time of day, shared fixtures or test order; and screenshot baselines are updated when a page changes on purpose.

## Reading a diff quickly yourself

```bash
git fetch -q origin +pull/<n>/head:refs/remotes/review/pr<n>
git diff --stat origin/main...review/pr<n> | tail -1
git show review/pr<n>:<path> | sed -n '/function handle/,/^    }/p'
```
