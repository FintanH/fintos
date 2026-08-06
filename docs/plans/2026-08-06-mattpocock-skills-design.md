# Design: Add mattpocock/skills to the pi microvm

Date: 2026-08-06
Status: Approved (ready for implementation)

## Goal

Make [mattpocock/skills](https://github.com/mattpocock/skills) available inside
the `pi-vm` microvm so they can be invoked via `/skill:<name>` in pi.

## Context

Skills reach the VM through two existing mechanisms in `microvms/pi.nix`:

1. **openskills** (`programs.openskills.remoteSkills`) — clones GitHub skill
   repos on home-manager activation into `~/.agent/skills` (via
   `--global --universal`). Currently lists `trailofbits/skills`,
   `obra/superpowers`, `mukul975/Anthropic-Cybersecurity-Skills`.
2. **Pi-native** — `stableSkillDirs` (nix store) and `devSkillNames` (live
   virtiofs mount from `~/Developer/AgentSkills`).

Pi discovers skills directly via
`extraSettings.skills = ["~/.claude/skills", "~/.agent/skills"]`.

The user chose the **openskills remoteSkills** mechanism (minimal, consistent
with the existing three repos).

## Key finding: latent headless bug

`openskills install` and `openskills sync` are **interactive by default**. With
no TTY (exactly the `nixos-rebuild` activation context) they render a picker and
abort with "Cancelled by user", installing/syncing nothing. The module's
`|| echo Warning` / `|| true` guards hide this.

Evidence: `~/.agent/skills` and `~/.claude/skills` are empty and
`openskills list` reports "No skills installed" — so the existing three
remoteSkills are not actually installing today.

Both commands accept `-y/--yes` to run non-interactively (install all / sync
all).

## Overlap analysis

- `openskills install <repo> -y` flattens **all 35** SKILL.md files across
  mattpocock's nested `skills/engineering/*`, `skills/productivity/*`, etc. into
  `~/.agent/skills/<name>/`.
- Comparing all 35 mattpocock names against superpowers: **zero name
  collisions**. Nothing overwrites; all skills coexist. Overlap is purely
  *conceptual* (`tdd` vs `test-driven-development`, `code-review` vs
  `requesting/receiving-code-review`, `diagnosing-bugs` vs
  `systematic-debugging`, `grill-*` vs `brainstorming`).
- Provenance is recorded per skill in `.openskills.json`
  (`source: "mattpocock/skills"`) and shown by `openskills list`.

## Decisions

- **Mechanism:** openskills `remoteSkills` (all 35 skills, no curation).
- **Module fix:** add `--yes` to activation commands (general correctness fix;
  also repairs the existing trailofbits/superpowers/mukul975 installs).
- **No pinning:** openskills clones the default branch at activation; mattpocock
  floats to `main` on each rebuild — accepted trade-off, same as existing repos.
- **Differentiation:** guidance note in pi `AGENTS.md`. Policy: **prefer
  mattpocock skills for general engineering; use rust-* skills for
  Rust-specific work.**

## Changes

### 1. `modules/home-manager/programs/openskills.nix`

Add `--yes` to both activation commands:

- `openskillsInstall`: `openskills install <src> --global --universal --yes`
- `openskillsSync`: `openskills sync --yes`

### 2. `microvms/pi.nix`

Add to `programs.openskills.remoteSkills`:

```nix
"mattpocock/skills"
```

### 3. `microvms/pi/agent.md`

Add a "Skill Selection" subsection under "Pi Workflow":

```markdown
## Skill Selection (overlapping skills)
Prefer mattpocock skills for general engineering; use rust-* skills for
Rust-specific work.
- TDD: Rust → rust-tdd; general → tdd
- Debugging → diagnosing-bugs
- Design/requirements dialogue → grill-with-docs (code), grill-me (non-code)
- Code review → code-review
- Planning & specs → to-spec, to-tickets, wayfinder
- Handoff → handoff
- Rust specifics → rust-tdd, rust-functional, rust-types
mattpocock and superpowers skills never share a name, so all remain
available via /skill:<name> regardless of preference.
```

## Out of scope (YAGNI)

- Flake pinning of the skills repo.
- Curated subset / fork.
- Separate discovery path for mattpocock (provenance already in
  `.openskills.json`).

## Verification

After `nixos-rebuild`:

- `openskills list` shows skills from all four repos.
- `~/.agent/skills/` contains the 35 mattpocock directories.
- `/skill:tdd` resolves in pi.

## Data flow (activation)

1. `openskillsInstall` clones each remoteSkill, discovers every `SKILL.md`,
   writes flattened into `~/.agent/skills/<name>/`.
2. `openskillsSync` regenerates the managed skill list in `~/AGENTS.md`.
3. Pi discovers skills via the already-configured `extraSettings.skills` paths;
   no pi change required.

Ordering is guaranteed by the HM activation DAG
(`openskillsSync` runs `entryAfter openskillsInstall`).
