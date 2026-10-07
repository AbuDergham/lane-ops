export const meta = {
  name: 'pr-review-light',
  description: 'Light review of one PR: one reviewer covering conformance, tests and security, then a skeptic only for major or blocker findings',
  phases: [
    { title: 'Review', detail: 'one reviewer, all lenses' },
    { title: 'Verify', detail: 'one skeptic for the majors only' },
  ],
}

// Run with the Workflow tool:
//   Workflow({ scriptPath: "<path>/pr-review-light.js",
//              args: { pr: 148, repo: "D:\\path\\to\\repo", task: "<CODE title>: <binding sources>. Check especially: <task-specific risks>",
//                      sources: "<optional: the project's binding docs, e.g. docs/plans/pN/contract.md and docs/rules.md>", skeptic: true } })
// args: { pr: number, repo: string, task: string, sources?: string, skeptic?: boolean }
const PR = args && args.pr
const REPO = (args && args.repo) || '.'
const TASK = (args && args.task) || 'the task'
const SOURCES = (args && args.sources) || 'the task\'s contract or spec and the repo\'s working rules (find them under docs/)'
const SKEPTIC = !(args && args.skeptic === false)

const CONTEXT = `You are an independent reviewer of pull request #${PR} (${TASK}) in the repo at ${REPO}. Read the PR with gh pr view ${PR} and gh pr diff ${PR} (run from ${REPO}). To read whole files at the PR head: git -C ${REPO} fetch -q origin +pull/${PR}/head:refs/remotes/review/pr${PR} and git -C ${REPO} show review/pr${PR}:<path>. Never check out the branch, edit files, push, comment, or run docker.
Binding sources: ${SOURCES}.
Be economical: read only the diff and the files you need. Report only concrete, real defects in THIS PR's changes, each with file and line, a one-sentence scenario and a concrete fix. Keep strings short, with no code blocks and no backslashes. At most 8 findings, most important first. An empty list is a valid answer.`

const FINDINGS = { type: 'object', properties: { findings: { type: 'array', items: { type: 'object', properties: {
  title: { type: 'string' }, severity: { type: 'string', enum: ['blocker', 'major', 'minor'] }, file: { type: 'string' }, line: { type: 'integer' },
  scenario: { type: 'string' }, fix: { type: 'string' } }, required: ['title', 'severity', 'file', 'scenario', 'fix'] } } }, required: ['findings'] }
const VERDICTS = { type: 'object', properties: { verdicts: { type: 'array', items: { type: 'object', properties: {
  index: { type: 'integer' }, real: { type: 'boolean' }, reason: { type: 'string' } }, required: ['index', 'real', 'reason'] } } }, required: ['verdicts'] }

phase('Review')
const res = await agent(`${CONTEXT}\nCover in one pass: conformance to the binding sources (every file and Done-when item; names and signatures), test quality (tests fail without the change; no time-of-day or shared-fixture dependence), and security (tenant isolation, authorization, validation, injection, SSRF, secrets in logs, races, idempotency, rate limits on abuse-sensitive actions, missing indexes behind pagination).`, { label: 'review', phase: 'Review', schema: FINDINGS })
const all = (res && res.findings) || []
const majors = all.filter(f => f.severity !== 'minor')
let confirmedMajors = majors
if (SKEPTIC && majors.length) {
  const v = await agent(`${CONTEXT}\nYou are the skeptic. Try to refute each finding against the PR's actual code; real only if confirmed. Findings (index from 0): ${JSON.stringify(majors)}`, { label: 'verify', phase: 'Verify', schema: VERDICTS })
  const verdicts = (v && v.verdicts) || []
  confirmedMajors = majors.filter((f, i) => { const d = verdicts.find(x => x.index === i); return d && d.real })
}
return { pr: PR, findings: [...confirmedMajors, ...all.filter(f => f.severity === 'minor')] }
