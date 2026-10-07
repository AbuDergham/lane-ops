# Avoiding conflicts

Each conflict costs a full CI round (often 30 to 40 minutes), because a CONFLICTING PR gets no CI until main is merged in. With two lanes merging all day, a single shared hot spot can cost hours: one PR was rebased five times in one night.

## Find the hot spots

- Keep a tally: whenever a PR conflicts, list the files (`git merge-tree --write-tree --name-only origin/main <pr-ref>`). The same files keep coming back.
- Typical hot spots are **append-at-the-end** files:
  - a central progress log, including its "Last updated" line;
  - a single test-helpers file;
  - central enums (audit actions, notification types);
  - central language files;
  - tests that list every enum value;
  - a go-live checklist;
  - the main navigation layout.

## Remove them, cheapest first

1. **One note file per task.** Replace the shared progress log with `docs/progress/tasks/<TASK>.md`: a fixed shape (title, Date, Done table row, Decisions log, Follow-ups) and an arch test that checks the name matches the task-ID pattern and the sections. Freeze the old log: nobody edits it, not even its date line. A small script renders all the notes as one table.
2. **Per-module test helpers.** Add `tests/Support/Helpers/<Module>.php`, loaded by a glob in the existing autoload entry. Leave the old file alone, so open PRs still apply.
3. **Per-module registries** for enums, language entries and nav items. Each module declares its own audit actions, notification types and texts in its own files. The central lists and tests are assembled from those sources. Stored values must not change.
4. **Sorted insertion.** Where per-module files are too big a change, sort the entries alphabetically and add the rule "insert in order, never at the end". This makes conflicts rare, but they don't disappear.

Any convention change needs both owners. Time it for a moment with few open PRs: every open PR touching those files conflicts once when the change lands.

## Screenshot baselines

- Pages that show the navigation (sidebar or header) are in screenshot tests. **Every new nav item changes them.** A baseline that sits close to the tolerance fails at the next change.
- Whoever changes the nav updates the baselines (all locales) in the lane with the project's snapshot-update command, and says so in the task note. When both lanes add nav items at the same time, the one that lands second regenerates the baseline on top of the first.
- Before regenerating, look at the diff image (the CI artifact) to confirm the change is the intended one.

## Semantic clashes

Two PRs can each be green on their own and still break main together (new nav items, enum lists, shared fixtures). Watch main's push CI after every merge. When it goes red, the lane whose merge broke it fixes it first, with ALERT and INFO on the channel.
