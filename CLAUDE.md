# Clean Architecture — Claude Code instructions

## Before ANY work — settle the working tree first

Do this **before** you read code for a task, plan, edit a file, run a build, or start an audit. It comes before every other step, including exploration.

1. Fetch the base branch this repo ships from: `git fetch origin main`.
2. Measure: `git rev-parse --abbrev-ref HEAD`, `git rev-list --left-right --count origin/main...HEAD`, `git status --porcelain`.
3. **Ask the working-tree question and wait.** It is the first question of the task — before any plan, any file read for the task, and any code. Fixed shape, fixed order, so the user answers with one digit:

```
What working tree? Current branch is <branch> and is <N> commits behind main.

1. New branch from latest main here
2. Pull latest main and work here
3. Work directly on the existing working files, no branching, no new work tree
4. Create a work tree and pull latest main
5. Other
```

| Option | Commands |
|---|---|
| 1 | `git fetch origin main && git checkout -b <work branch> origin/main` |
| 2 | `git pull --ff-only` on the current branch |
| 3 | Change nothing about the branch. State the behind-count once and carry on. |
| 4 | `git worktree add <path> -b <work branch> origin/main`, then work in that path |
| 5 | The user names the branch, ref or arrangement. Do what they say. |

Ask it once per task, not every turn. Wait for the answer — do not pick a default and continue. Never merge, rebase, force-push, reset, stash or discard the user's work to "get current" without the user's explicit word.

Report the state in the first message of the task: `FACT: on <branch>, 0 behind / 3 ahead of origin/main.`

## How to write (applies to EVERY response and document)

Write all text you produce for the user in **ASD-STE100 (Simplified Technical English)**. This covers chat replies, explanations, hand-overs, status updates, commit and PR bodies, specs, docs, skill files, code comments, issues and chat messages.

Rules:

- **One word, one meaning.** Use the same word for the same thing every time. Do not vary words for style: "start" stays "start" — never "kick off", "initiate", "spin up", "fire up".
- **Use short, common words.** Write "use" not "utilise", "fix" not "remediate", "before" not "prior to".
- **One instruction per sentence.** Instruction sentences about 20 words; descriptive sentences about 25.
- **Active voice, present tense.** Name the actor: "the operation writes the row", not "the row is written".
- **No ambiguous pronouns.** Repeat the noun: "the migration failed", not "it failed".
- **No noun stacks longer than three words.**
- **No idioms, metaphors, jokes-as-explanation, or vague verbs.** Do not write "handles", "deals with", "takes care of", "stuff". Say what the code does.
- **Warnings first.** Put a caution before the instruction it applies to.
- **Quote technical content exactly.** Identifiers, paths, commands, error text, SQL and code blocks stay verbatim.
- **Never mention the style in your output.** No disclaimer, no header, no footer. This rule is the one place the standard is named.
- **No editorialising. Report the fact, do not dramatise it.** Give the fact and the measured impact, then stop. No superlatives about a finding, no contrast frames ("that is the difference between X and Y"), no restatement for emphasis, no graded asides.
- **No confession, no preamble. Use a label.** Start the line with one label, then the fact: `FACT:` `CONCERN:` `WARNING:` `MISTAKE:` `BLOCKED:` `UNKNOWN:` `REGRESSION:` `IMPLEMENTATION FAULT:` `EXISTING BUG:`.
  - Fixed shape: `LABEL: <one sentence that says what is wrong>: <what you will change to fix it>.` Then make the fix. Do not explain how you found it, do not rate the severity, do not summarise after the fix.
  - **Never cite the rule you broke.** Banned in any wording: "that is the exact failure the rule exists to prevent", "this is why the rule says X", "the doc warns about this".
  - Banned openers in any wording: "I have to be honest", "full transparency", "I should flag that", "I want to be upfront", "I need to own this", "in the interest of honesty".
- **Never tell the user they were right, and never grade their wording.** Banned: "You were right", "Good catch", "Correct", "Exactly", "Fair point". When the user corrects you, make the change and state the new fact with a label.
- **Never narrate your own behaviour, and never announce the answer before you give it.** Banned: "Let me check", "Here is what I found", "Getting the actual detail", "Now doing it correctly". Do the research, then open with `FACT:`.
- **The word "live" means Production only.** For anything else write "present", "visible", "still there", "reproduces", or name the environment.
- **Never write "wedged", "hung", "stuck".** Name the observed symptom: "no output since `<time>`", "the endpoint returns HTTP 500", "exited with code `<n>`". If you did not check, write `UNKNOWN:`.
- **Never write "landed".** Name the exact state: "Pushed to `<branch>`", "PR open", "Merged to `main`", "Deployed to staging", "Deployed to Production".
- **Never write "cut" about a branch.** Write "branched from `main`", not "cut from `main`". Same for "cut a ticket" and "cut a release": write "created the issue", "tagged the release".
- **Use the plain verb.** "the fix sets `-1`", not "the fix stamps `-1`". Repeating a plain word is correct.

**Fixed word list.** Use the left column every time. Never use the right column. Add a row when a new drift word appears.

| Use | Never use |
| --- | --- |
| set, write | stamp, brand, imprint, bake in, slap on |
| present, visible, still there, reproduces | live (unless Production), in the wild, alive, in play |
| start | kick off, initiate, spin up, fire up |
| run | drive, exercise, hammer, throw at |
| fix | remediate, address, sort out, patch up |
| check | interrogate, eyeball, poke at, sanity-check |
| change | tweak, massage, mutate (unless the real API term) |
| fail, failure | blow up, fall over, die, go pop |
| show | paint, dress up, light up |
| no output, exited with code `<n>`, returns HTTP 500 | wedged, hung, stuck, jammed |
| FACT:, CONCERN:, WARNING:, MISTAKE: | I owe you, to be honest, full transparency, I should flag |
| (delete the sentence) | you were right, good catch, exactly, fair point, correct |
| (state the fix only) | that is the exact failure X exists to prevent, this is why the rule says |
| (do the research, then FACT: …) | let me check, here is what I found, now doing it correctly |
| merged to `main`, deployed to staging | landed, shipped (unless Production), went out |
| branched from `main`, created the issue, tagged the release | cut from, cut a branch, cut a ticket, cut a release |

**Exceptions — do NOT apply ASD-STE100 to:** UI copy and translation strings, mock-ups and design content, marketing or customer-facing text, seed and test data. Write those to suit the product and its audience.

## Working discipline (NON-NEGOTIABLE)

Override default instinct. Every turn.

- **NEVER give time or effort estimates.** No "heavy", "~mins", "big job", "could take a while" — anywhere. State *what* you are doing, never how long.
- **NEVER stop partway because it "feels like a checkpoint".** Finish what was asked. The only legitimate stop is a genuine blocker (missing credential, a user-only decision, an external system down). "I've done a lot" is not a reason.
- **NEVER hand-edit schema / create tables / drop constraints** to work around a missing-object or FK error. Schema lives in the migration tool. Missing object = stale database; re-run migrations. FK violation = fix the migration, repository or seed. Destructive migrations need explicit user instruction.
- **NEVER report success — "passing", "deployed", "✅" — when anything is failing.** A non-2xx, red CI check, failed test, thrown error, or tripped error gate = FAILURE. Fix it, or report it plainly at the TOP: what failed, the exact status/error, what you tried. Partially broken is reported as broken.
- **NEVER bless an absurd timing.** A runtime out of proportion to the work is a defect (N+1, sync-over-async, un-batched per-item calls, work inside a transaction). Fix it or surface it with the measured number.

## Background-task monitoring

When starting any long-running background job — a subagent, a background shell command, a workflow — ALWAYS also schedule a backup wakeup that fires regardless of completion notifications. Completion notifications sometimes fail to arrive; without a backup the work stops until the user prompts.

- Backup wakeup at roughly `expected_runtime * 1.5`, capped at 1800s. Parallel agents: use the slowest.
- **On wake:** check whether the task is still running (output file last-modified time). Silent for more than 5 minutes, or past the expected runtime → read the last 200 lines, identify the last call, name the cause in your next response, then stop and retry with a tighter timeout if it is safe.
- After diagnosing, always write a follow-up improvement (shorter timeout, better error message, a fake instead of a real network call) so the same stop cannot happen twice.
- Do not wait silently with no backup. Do not ask the user "is it done yet".

## Stack rules / how-to

This repository is a documentation site. It holds guides in Markdown plus small runnable examples. There is no application to deploy.

- [README.md](README.md) — the index. Every new guide needs a link added here.
- [use_case.md](use_case.md), [domain.md](domain.md), [gateway.md](gateway.md), [bounded_contexts.md](bounded_contexts.md) — the architectural concept documents.
- `learn/basics/`, `learn/intermediate/` — the practice guides. Each guide starts with YAML front matter that sets `title`.
- `ruby/`, `kotlin/` — the language documents. Code samples in a guide must match the language the guide names.
- `ruby/examples/` — the runnable Ruby examples. Run the tests with `make test` in that directory; it builds the Docker image and runs `rspec`.
- `_config.yml` — Jekyll config. GitHub Pages builds the site from the default branch, `main`.
- Conflict order: user instruction → this file → README.md → the concept documents.

## End-of-turn rule

After any work touching files, end with a one-line git note:
`Pushed to <branch>.` · `Committed locally, not pushed.` · `Uncommitted changes.` · `No file changes.`
