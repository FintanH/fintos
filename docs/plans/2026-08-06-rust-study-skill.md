# rust-study Skill Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Implement the `rust-study` skill (design: `2026-08-06-rust-study-skill-design.md`) — a guided workflow for learning Rust codebases through exploration, self-written notes, and active recall.

**Architecture:** One lean SKILL.md + note templates in `~/Developer/AgentSkills/personal/rust-study/`, wired into pi via `devSkillNames` in `microvms/pi.nix`. Notes live in `~/Developer/study/<repo>/`. The agent surfaces evidence and verifies; the user writes all "In my words" content.

**Tech Stack:** Pi skills (markdown + frontmatter), Nix home-manager wiring, gitnexus + rustdex tools.

**Important environment facts (verified):**
- `~/Developer/AgentSkills` is a host mount, **not a git repo in the VM** — skill files are created but not committed from the VM
- Dev skills resolve via symlink chain; **editing existing skill content is live, but adding a new skill requires a host `nixos-rebuild`** to appear in `~/.pi/agent/skills/`
- Skill wiring lives at `microvms/pi.nix` (`devSkillNames`, currently lines ~163–172)
- `~/Developer/study/` does not exist yet; the skill creates it on demand

---

## Phase 1: Skill content (files in `~/Developer/AgentSkills`)

### Task 1: Create skill directory and templates

**TDD scenario:** New artifact — verification is existence + content checks (no executable code).

**Files:**
- Create: `~/Developer/AgentSkills/personal/rust-study/templates/concept.md`
- Create: `~/Developer/AgentSkills/personal/rust-study/templates/type.md`
- Create: `~/Developer/AgentSkills/personal/rust-study/templates/overview.md`

**Step 1: Create the directory**

```bash
mkdir -p ~/Developer/AgentSkills/personal/rust-study/templates
```

**Step 2: Write `templates/concept.md`**

```markdown
---
repo: REPO_NAME
commit: DEFAULT_BRANCH_SHA
status: draft
---
# CONCEPT_NAME

## In my words

<!-- USER WRITES THIS. The agent must never edit this section. -->

## Evidence

<!-- Agent-maintained: file:line links, usage sites, verified facts. -->

## Open questions

<!-- User's questions. Migrate substantial ones to questions.md. -->

## Recall

<!-- Q&A pairs. Every answer must cite a code location.
- Q: ...
  A: ... (src/foo.rs:42)
  history:
-->
```

**Step 3: Write `templates/type.md`**

```markdown
---
repo: REPO_NAME
commit: DEFAULT_BRANCH_SHA
status: draft
---
# TYPE_NAME

## In my words

<!-- USER WRITES THIS. The agent must never edit this section. -->

## Evidence

### Definition

<!-- Agent: file:line, generics, key fields/variants. -->

### Invariants

<!-- Agent: invariants visible in code (constructors, debug_asserts, doc comments). -->

### Usage sites (grouped by purpose)

<!-- Agent: construction / mutation / traversal / serialization ..., each with file:line. -->

### Related types

<!-- Agent: links to other type cards, e.g. [[SyncState.md]] or [[../../automerge/types/OpSet.md]]. -->

## Open questions

## Recall

<!-- Q&A pairs; answers cite code locations. -->
```

**Step 4: Write `templates/overview.md`**

```markdown
---
repo: REPO_NAME
commit: DEFAULT_BRANCH_SHA
status: draft
---
# REPO_NAME — Overview

## Mental model

<!-- USER WRITES THIS. The agent must never edit this section. -->

## Architecture (agent-verified)

<!-- Agent: crates, module layout, dependency direction, entry points, main data flow. -->

## Where to start reading

<!-- Agent: suggested reading order with reasons. -->

## Recall
```

**Step 5: Verify**

Run: `ls ~/Developer/AgentSkills/personal/rust-study/templates/`
Expected: `concept.md  overview.md  type.md`

Run: `grep -l "USER WRITES THIS" ~/Developer/AgentSkills/personal/rust-study/templates/*.md | wc -l`
Expected: `3`

*(No commit — AgentSkills is not a git repo in the VM.)*

### Task 2: Write SKILL.md

**TDD scenario:** New artifact — verification via frontmatter and cross-reference checks.

**Files:**
- Create: `~/Developer/AgentSkills/personal/rust-study/SKILL.md`

**Step 1: Write the file with this exact content**

````markdown
---
name: rust-study
description: Guided workflow for learning unfamiliar Rust codebases through exploration, self-written notes, and active recall. Use when studying, exploring, or being quizzed on a Rust codebase, e.g. "let's study automerge", "where is OpSet used?", "quiz me on automerge".
---
# Rust Study

Learn a Rust codebase through evidence-driven exploration, self-authored
notes, and active recall.

**Core principle: the agent finds and verifies; the user understands and
writes.** Never generate study notes wholesale. Surface evidence, prompt the
user to explain in their own words, check their writing against the code, and
maintain note scaffolding.

## Hard rules

1. **Never write or edit an "In my words" or "Mental model" section.** Those
   belong to the user. If they contain an error, quote the contradicting code
   and let the user resolve it.
2. Every factual claim you record in a note must cite a code location
   (`file:line`) or doc.
3. Only set `status: reviewed` in a note's frontmatter after you have
   fact-checked the user's prose against the current code.

## Notes location

All notes live under `~/Developer/study/`:

```
~/Developer/study/
├── _family/              # cross-cutting concepts spanning repos
│   ├── overview.md       # how the repos relate
│   └── concepts/
└── <repo>/
    ├── overview.md       # from templates/overview.md
    ├── concepts/<name>.md    # from templates/concept.md
    ├── types/<Name>.md       # from templates/type.md
    ├── reading-log.md    # append-only dated journal
    └── questions.md      # open questions; check off when resolved
```

Create directories and skeleton files on demand from `templates/` (relative
to this skill directory), substituting `REPO_NAME`, `DEFAULT_BRANCH_SHA`,
and the concept/type name.

## Session start (always)

1. Identify the repo being studied (the cwd, or ask).
2. Resolve the default branch: `git symbolic-ref refs/remotes/origin/HEAD`
   (fall back to `main`/`master`). **Never use bare HEAD as the reference
   point.**
3. If the working tree is not on the default branch, warn: studying a side
   branch may be unintentional. Continue only if the user confirms.
4. `git fetch origin` (if network allows), then compare each note's `commit`
   frontmatter against the default-branch tip. List stale notes and offer
   re-verification; do not silently trust them.
5. Read `questions.md` and the last `reading-log.md` entry to recall where
   the user left off, and say so.
6. If rustdex has no index for this repo, offer to index it
   (`rustdex_index`). Use gitnexus tools when the repo is indexed; otherwise
   degrade to `rg` and reading — never treat missing tools as a blocker.

## Session types

Recognize these from natural requests; confirm if ambiguous.

### Orient ("give me an overview", first visit)

1. Scan README, docs, workspace `Cargo.toml`, crate layout.
2. Deliver a spoken breadth-first walkthrough: crates, dependency direction,
   main data flow, entry points. Crate level first; drill only where the
   user points. Answer interruptions with evidence.
3. Create `overview.md` from the template. Fill only the agent sections.
   Prompt the user to write "Mental model" now or later.
4. Seed `questions.md` with anything that looked interesting or unclear.

### Type archaeology ("where and how is `X` used?")

1. Gather with rustdex/gitnexus (or `rg`): definition, visible invariants,
   all usage sites grouped by purpose (construction, mutation, traversal,
   serialization, ...), lifecycle.
2. Present with `file:line` references; answer follow-ups.
3. Create `types/<Name>.md` from the template, fill the Evidence sections,
   then prompt the user to write "In my words" and at least two Recall
   questions.

### Deep read ("let's read module `Y`")

1. The user picks the target. Read alongside them; answer "why is this like
   this?" with evidence (git log/blame counts as evidence).
2. Actively hunt for refactoring observations together: smells,
   simplifications, API awkwardness.
3. Append a dated entry to `reading-log.md` containing what was read, the
   user's insights (their words), and a `### Refactoring observations`
   subsection. Verify any factual claims before recording.

### Recall ("quiz me [on <repo>]")

1. Collect `## Recall` entries from the requested scope (one repo, or all of
   `~/Developer/study/`). Prioritize questions with no history or recent ✗.
2. Ask one question at a time. Grade the user's answer **against the code**,
   not just the stored answer.
3. Append `YYYY-MM-DD ✓/✗` to each question's history line. For ✗, offer to
   revisit the source together.

## Cross-repo rules

- A concept lives in the repo that implements it; `_family/` is only for
  relationships between repos and shared vocabulary. When in doubt:
  repo-local with cross-links.
- Link between notes with relative markdown links, e.g.
  `[[../../automerge/types/SyncState.md]]`.
- When evidence involves a symbol from another studied repo: link to its
  note if it exists; otherwise add a stub line to that repo's
  `questions.md` (create the repo's study dir if needed).

## Session end (always)

Update `questions.md` (add new, check off resolved) and state where to
resume next time.

## Companions

When studying CRDT internals (e.g. automerge), also load the
`crdt-development` skill for domain context.
````

**Step 2: Verify frontmatter and structure**

Run: `head -5 ~/Developer/AgentSkills/personal/rust-study/SKILL.md`
Expected: frontmatter with `name: rust-study` and a `description:` line containing trigger phrases.

Run: `grep -c "templates/" ~/Developer/AgentSkills/personal/rust-study/SKILL.md`
Expected: `>= 1` (template references present)

**Step 3: Cross-check consistency with templates**

Run: `grep -o "In my words\|Mental model" ~/Developer/AgentSkills/personal/rust-study/templates/*.md ~/Developer/AgentSkills/personal/rust-study/SKILL.md | sort -u | wc -l`
Expected: non-zero; confirm SKILL.md's protected-section names match the template headings exactly (`In my words` in concept/type, `Mental model` in overview).

*(No commit — AgentSkills is not a git repo in the VM.)*

---

## Phase 2: Wiring (fintos repo — this worktree)

### Task 3: Register the skill in `microvms/pi.nix`

**TDD scenario:** Modifying config — verify evaluation before and after.

**Files:**
- Modify: `microvms/pi.nix` (`devSkillNames` list, ~line 163)

**Step 1: Add the entry**

In `microvms/pi.nix`, extend `devSkillNames`:

```nix
      devSkillNames = [
        "radicle-dev/rust-tdd"
        "radicle-dev/rust-functional"
        "radicle-dev/rust-types"
        "radicle-dev/crdt-development"
        "radicle-dev/distributed-systems"
        "radicle-dev/git-internals"
        "radicle-dev/radicle-cobs"
        "Rust/rust-skills-rules"
        "personal/rust-study"
      ];
```

**Step 2: Format**

Run: `nix fmt` (alejandra, per repo convention)
Expected: exits 0; `git diff` shows only the intended change (plus any formatting).

**Step 3: Evaluate the config (if flake eval is available in the VM)**

Run: `nix flake check --no-build 2>&1 | tail -5` (or `nix eval` of the relevant attr)
Expected: no evaluation errors mentioning `pi.nix`. If evaluation is not possible in the VM, note this and rely on the host rebuild in Task 4.

**Step 4: Commit**

```bash
git add microvms/pi.nix
git commit -m "pi-vm: register personal/rust-study dev skill"
```

### Task 4: CHECKPOINT — host rebuild (manual)

**TDD scenario:** Manual verification gate.

**Step 1: Ask the user to rebuild on the host** (`nixos-rebuild switch` for the pi-vm host config, per their usual workflow) and restart the VM/session if required.

**Step 2: Verify the symlink chain exists**

Run: `ls -la ~/.pi/agent/skills/personal/ && readlink -f ~/.pi/agent/skills/personal/rust-study`
Expected: `rust-study` symlink resolving to `/home/fintohaps/Developer/AgentSkills/personal/rust-study`

**Step 3: Verify pi lists the skill**

In a fresh pi session, the `<available_skills>` list (or `/skill:rust-study`) includes `rust-study` with the description from the frontmatter.

**Do not proceed to Phase 3 until this checkpoint passes.**

---

## Phase 3: Validation (first real use)

### Task 5: Smoke test — Orient session on automerge

**TDD scenario:** End-to-end behavior test of the skill.

**Step 1: Clone the target (if not present)**

```bash
ls ~/Developer/automerge 2>/dev/null || git clone https://github.com/automerge/automerge ~/Developer/automerge
```

**Step 2: In a fresh pi session in `~/Developer/automerge`, invoke `/skill:rust-study` and say "give me an overview".**

Expected behavior checklist (from the design's success criteria):
- [ ] Resolves default branch via `origin/HEAD`, not bare HEAD; warns if on a side branch
- [ ] Offers rustdex indexing; degrades gracefully if gitnexus is absent
- [ ] Walkthrough is breadth-first (crate level first)
- [ ] Creates `~/Developer/study/automerge/overview.md` from the template with agent sections filled and "Mental model" left for the user
- [ ] Creates/seeds `~/Developer/study/automerge/questions.md`
- [ ] Session ends by updating `questions.md` and stating a resume point

**Step 3: Verify note files**

Run: `ls ~/Developer/study/automerge/ && grep -A2 "^## Mental model" ~/Developer/study/automerge/overview.md`
Expected: `overview.md` and `questions.md` exist; the "Mental model" section contains only the placeholder comment (agent did not write it).

### Task 6: Smoke test — one type card end-to-end

**Step 1: In the same session, ask "where and how is `Automerge` used?" (or another core type).**

Expected: evidence presented with `file:line` refs; `types/Automerge.md` skeleton created; user prompted to write "In my words" + ≥2 Recall questions.

**Step 2: Write the note as the user, then ask the agent to review.**

Expected: agent fact-checks the prose against code, flips `status: draft` → `reviewed` only after verification, and any correction quotes code rather than editing the user's words.

**Step 3: Record friction**

Any awkwardness in the flow → edit SKILL.md directly (edits are live, no rebuild needed) and note the change.

### Task 7: Deferred check — Recall session

After ≥2 days of real use: run "quiz me on automerge". Success = at least one genuine knowledge gap surfaced and its ✗ logged into the note's history line. If quizzing feels weak, that is the trigger to split out a dedicated `rust-quiz` sibling skill (per the design's evolution path).

---

## Consistency notes resolved during planning

- **Design said "commit skill to git"** — impossible from the VM (AgentSkills is a non-git host mount); versioning of skill files happens on the host. Only the `pi.nix` wiring is committed here.
- **Design implied the skill is instantly available** — false for *new* skills; requires `devSkillNames` + host rebuild (Task 3–4). Content edits after that are live.
- **Skill namespace** — `personal/` is new; it needs no special handling since `devSkillNames` entries are arbitrary `<dir>/<skill>` paths under the mount.
