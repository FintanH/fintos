# Design: `rust-study` — a skill for learning Rust codebases

**Date:** 2026-08-06
**Status:** Validated design, not yet implemented
**First target:** the automerge family of repositories

## Motivation

When joining unfamiliar codebases, effective learning is a mixture of:
browsable overviews with interactive Q&A, self-written notes, active recall
(quizzing), type archaeology ("where and how is this used?"), and deep code
reading with an eye for refactoring improvements. Existing third-party skills
(alexanderop/walkthrough, graphify, wtfismyrepo, codebase-onboarding) each
cover part of this; none combine self-authored notes + recall + the Rust-aware
tooling already available in this environment (gitnexus, rustdex).

## Decisions

- **Structure:** one lean skill + a well-specified notes convention
  ("C evolving to B"). Quizzing starts as a behavior of this skill; if it
  needs more, it graduates to a sibling `rust-quiz` skill sharing the same
  notes convention.
- **Notes location:** central study directory `~/Developer/study/<repo>/`
  (survives re-clones, keeps the repo family together, never pollutes
  upstream repos).
- **Authorship:** the user writes the notes; the agent assists.
  *The agent finds and verifies; the user understands and writes.*

## Architecture

**Location:** `~/Developer/AgentSkills/personal/rust-study/SKILL.md`
(editable on host, live in the pi VM).

The agent:

1. **Surfaces evidence** — architecture summaries, type usage sites, call
   flows — via gitnexus, rustdex, and plain reading
2. **Prompts the user to explain** — after exploring a concept, asks the user
   to write the note in their own words
3. **Checks accuracy** — reads user notes against the code and flags
   misconceptions with citations; never silently edits the user's prose
4. **Maintains structure** — creates note skeletons (frontmatter, headings,
   `## Recall` stubs) so the user only writes content, never scaffolding

## Session types

Invoked naturally in conversation:

1. **Orient** (first visit / refresh): index with rustdex (and gitnexus if
   available), scan README/docs/Cargo layout, deliver a spoken architecture
   walkthrough. Creates `overview.md` skeleton (agent-verified facts; the
   "mental model" section is the user's). Seeds `questions.md`.
2. **Type archaeology** ("where and how is `Transaction` used?"): gather
   definition, invariants, usage sites grouped by purpose, lifecycle — with
   file:line references. Ends by creating a `types/<Name>.md` skeleton and
   prompting the user to write summary + Recall questions.
3. **Deep read**: read a module together; answer "why?" questions with
   evidence; explicitly hunt for refactoring observations, recorded in
   `reading-log.md` (user's words, agent-verified).
4. **Recall** ("quiz me"): read `## Recall` sections, ask oldest/weakest
   first, grade answers *against the code*, log results back into the note.
   Scopes to one repo or the whole family.

Every session ends by updating `questions.md` and noting where to resume.

## Notes convention (the contract)

```
~/Developer/study/
├── _family/              # cross-cutting: sync protocol, ecosystem map...
│   ├── overview.md       # constellation map: how the repos relate
│   └── concepts/
├── <repo>/
│   ├── overview.md          # architecture map; "mental model" is the user's
│   ├── concepts/<name>.md   # one concept per file
│   ├── types/<Name>.md      # one type card per file
│   ├── reading-log.md       # append-only, dated session journal with
│   │                        #   "Refactoring observations" subsections
│   └── questions.md         # open questions, checked off when resolved
└── ...
```

Concept and type notes share a template:

```markdown
---
repo: automerge
commit: <default-branch sha when studied>   # staleness detection
status: draft | reviewed                    # reviewed = agent fact-checked
---
# <Name>

## In my words          ← user writes; agent never touches
## Evidence             ← agent-maintained: file:line links, usage sites
## Open questions       ← user's; migrated to questions.md when big
## Recall               ← Q&A pairs; each answer cites code
- Q: ...
  A: ... (src/foo.rs:42)
  history: 2026-08-06 ✗, 2026-08-10 ✓
```

**Rules:**

- `status: reviewed` is set only after the agent verifies "In my words"
  against the code; accuracy-checking is an explicit step.
- Recall answers must cite code locations so quizzes are graded against
  reality, not the note.
- **Staleness:** on session start, resolve the default branch
  (`origin/HEAD`); warn if the working tree is not on it ("you're on
  `experiment/op-tree` — studying a branch, is that intentional?").
  Compare note `commit` fields against the latest default-branch tip and
  list stale notes, offering re-verification. Never compare against bare
  `HEAD`, to avoid silently studying a side branch.

**Cross-repo references:**

- Plain relative markdown links, e.g.
  `[[../automerge/types/SyncState.md]]` — clickable in any editor.
- When evidence in one repo involves a symbol from another studied repo,
  link to that repo's note if it exists, otherwise add a stub line to that
  repo's `questions.md` — cross-repo gaps surface naturally.
- A concept lives in the repo that *implements* it; `_family/` is only for
  relationships between repos and genuinely shared vocabulary. When in
  doubt: repo-local with cross-links (cheap to promote later).

## Tool integration (priority order)

1. **rustdex** — "where is X defined/used", semantic queries; index on first
   Orient session
2. **gitnexus** — call graphs, impact analysis, execution flows; used when
   available, degrades gracefully to `rg` + reading (no hard dependency)
3. **cargo doc / rustdoc** — doc comments are evidence; check before
   explaining
4. **crdt-development** skill — companion to load when studying automerge
   internals

## Edge cases

- *Repo moved since last study:* stale-note listing per the staleness rule
  above; offer re-verification rather than silently trusting notes.
- *Contradiction during accuracy check:* agent quotes the code; the user
  resolves it.
- *Huge repos:* Orient is breadth-first (crate level), drilling only where
  the user points.

## Validation

The first real session on `automerge` is the test:

1. An Orient session produces an overview the user actually understands
2. One type card written end-to-end with the collaborative flow feeling
   natural
3. A quiz three days later catches a real gap

Friction gets fixed in SKILL.md — a living document.

## Deliverables

1. `~/Developer/AgentSkills/personal/rust-study/SKILL.md`
2. Templates in the skill dir (`templates/concept.md`, `templates/type.md`,
   …) referenced by relative path
3. This design doc

## Alternatives considered

- **Install alexanderop/walkthrough** — good visual mental models, but
  generative rather than self-authored; weak on recall and Rust-specific
  type archaeology.
- **Graphify / wtfismyrepo / codebase-onboarding** — each covers a slice;
  gitnexus + rustdex already cover the tooling layer locally.
- **One skill with explicit modes / family of skills from day one** —
  rejected for YAGNI; the notes convention is the stable contract that
  allows splitting later.
