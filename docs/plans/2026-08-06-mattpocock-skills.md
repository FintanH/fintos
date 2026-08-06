# Add mattpocock/skills to the pi microvm — Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Make all 35 [mattpocock/skills](https://github.com/mattpocock/skills) available inside the `pi-vm` microvm via openskills, fix the latent headless install bug, and add a skill-selection policy to pi's AGENTS.md.

**Architecture:** Three independent edits to declarative NixOS/home-manager config. (1) The `openskills` HM module install/sync commands are made non-interactive with `--yes`. (2) `mattpocock/skills` is appended to the VM's `remoteSkills`. (3) A "Skill Selection" note is added to the pi guest `AGENTS.md`. Skills install into `~/.agent/skills` on activation; pi already discovers that path.

**Tech Stack:** Nix, home-manager, openskills CLI (`numman-ali/openskills`), `jj` for VCS, `alejandra` for formatting.

**Design reference:** `docs/plans/2026-08-06-mattpocock-skills-design.md`

**Testing note:** This is infrastructure config — there is no unit-test harness. "Tests" are: `nix fmt` (formatting), a config evaluation/build, and post-activation verification via the `openskills` CLI. Commit after each task with `jj`.

---

## Task 1: Make openskills activation non-interactive (`--yes`)

**TDD scenario:** Modifying existing config — verify the current broken behavior first, then fix.

**Files:**
- Modify: `modules/home-manager/programs/openskills.nix` (openskillsInstall ~line 116, openskillsSync ~line 131)

**Step 1: Reproduce the bug (evidence first)**

Run:
```bash
cd "$(mktemp -d)" && openskills install obra/superpowers </dev/null 2>&1 | tail -3
```
Expected: renders a picker then `Cancelled by user` — i.e. installs nothing without a TTY. This is exactly the activation context, confirming the current module is a no-op.

**Step 2: Add `--yes` to the install command**

In `modules/home-manager/programs/openskills.nix`, in `home.activation.openskillsInstall`, change:
```nix
            $DRY_RUN_CMD openskills install ${lib.escapeShellArg src} \
              ${lib.optionalString cfg.globalInstall "--global"} \
              ${lib.optionalString cfg.universalFormat "--universal"} \
              || echo "Warning: Failed to install ${src}" >&2
```
to:
```nix
            $DRY_RUN_CMD openskills install ${lib.escapeShellArg src} \
              ${lib.optionalString cfg.globalInstall "--global"} \
              ${lib.optionalString cfg.universalFormat "--universal"} \
              --yes \
              || echo "Warning: Failed to install ${src}" >&2
```

**Step 3: Add `--yes` to the sync command**

In the same file, in `home.activation.openskillsSync`, change:
```nix
        $DRY_RUN_CMD openskills sync || true
```
to:
```nix
        $DRY_RUN_CMD openskills sync --yes || true
```

**Step 4: Confirm `--yes` works headless (proves the fix)**

Run:
```bash
cd "$(mktemp -d)" && openskills install obra/superpowers --universal --yes </dev/null 2>&1 | tail -3
```
Expected: `Installation complete: N skill(s) installed` — installs without a TTY.

**Step 5: Format**

Run: `cd /home/fintohaps/Developer/fintos && nix fmt modules/home-manager/programs/openskills.nix`
Expected: no diff / clean formatting.

**Step 6: Commit**

```bash
cd /home/fintohaps/Developer/fintos
jj describe -m "openskills: run install/sync headless with --yes

Without a TTY (the nixos-rebuild activation context) openskills install
and sync render an interactive picker and abort, installing nothing.
Adding --yes makes activation actually install/sync all skills."
jj new
```

---

## Task 2: Add mattpocock/skills to the VM's remoteSkills

**TDD scenario:** Modifying existing config — additive list entry.

**Files:**
- Modify: `microvms/pi.nix` (`programs.openskills.remoteSkills`, ~lines 130-139)

**Step 1: Verify the repo installs cleanly with the same flags activation uses**

Run:
```bash
cd "$(mktemp -d)" && openskills install mattpocock/skills --universal --yes </dev/null 2>&1 | tail -3
```
Expected: `Installation complete: 35 skill(s) installed`.

**Step 2: Add the entry**

In `microvms/pi.nix`, change:
```nix
        # Additional security (MITRE ATT&CK mapped)
        {source = "mukul975/Anthropic-Cybersecurity-Skills";}
      ];
```
to:
```nix
        # Additional security (MITRE ATT&CK mapped)
        {source = "mukul975/Anthropic-Cybersecurity-Skills";}

        # General engineering skills (grilling, tdd, diagnosing-bugs, specs)
        "mattpocock/skills"
      ];
```

**Step 3: Format**

Run: `cd /home/fintohaps/Developer/fintos && nix fmt microvms/pi.nix`
Expected: clean.

**Step 4: Commit**

```bash
cd /home/fintohaps/Developer/fintos
jj describe -m "pi-vm: add mattpocock/skills to openskills remoteSkills"
jj new
```

---

## Task 3: Add skill-selection policy to pi AGENTS.md

**TDD scenario:** Trivial doc change — use judgment, no automated test.

**Files:**
- Modify: `microvms/pi/agent.md` (append a subsection after the "Pi Workflow" section, before "## Available Skills")

**Step 1: Add the subsection**

In `microvms/pi/agent.md`, immediately after the "## Pi Workflow" bullet list and before "## Available Skills", insert:

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

**Step 2: Verify placement**

Run: `cd /home/fintohaps/Developer/fintos && grep -n "Skill Selection\|## Available Skills\|## Pi Workflow" microvms/pi/agent.md`
Expected: "## Pi Workflow" < "## Skill Selection" < "## Available Skills".

**Step 3: Commit**

```bash
cd /home/fintohaps/Developer/fintos
jj describe -m "pi-vm: document skill-selection policy for overlapping skills"
jj new
```

---

## Task 4: Evaluate config and verify activation

**TDD scenario:** Integration verification of all three edits together.

**Files:** none (build/verify only)

**Step 1: Evaluate the pi-vm config builds**

Run (from the flake root):
```bash
cd /home/fintohaps/Developer/fintos
nix flake check 2>&1 | tail -20
```
Alternatively build the guest toplevel if `flake check` is too broad — identify the microvm attribute and build just that:
```bash
nix eval .#nixosConfigurations --apply builtins.attrNames 2>/dev/null || true
```
Expected: evaluation succeeds (no Nix errors from the edited files).

**Step 2: Rebuild / activate the VM**

Follow the repo's normal deploy path for `pi-vm` (e.g. `nixos-rebuild switch` targeting the microvm host, or the project's documented microvm redeploy command). Confirm activation runs `openskillsInstall`/`openskillsSync` without the "Cancelled by user" message.

**Step 3: Verify skills landed (post-activation, inside the VM)**

Run:
```bash
openskills list 2>&1 | head -40
ls ~/.agent/skills | wc -l
ls ~/.agent/skills | grep -E '^(tdd|grill-with-docs|diagnosing-bugs|code-review|to-spec)$'
```
Expected: `openskills list` shows skills from all four repos; `~/.agent/skills` now contains the mattpocock directories (35 from mattpocock plus the others); the grep finds the named skills.

**Step 4: Verify pi resolves a skill**

Run inside pi (or check discovery path):
```bash
grep -rl "^name: tdd" ~/.agent/skills/tdd/SKILL.md
```
Expected: the mattpocock `tdd` SKILL.md is present and discoverable via pi's configured `skills` paths.

**Step 5: Final commit (close the change)**

If any notes/adjustments were needed, commit them:
```bash
cd /home/fintohaps/Developer/fintos
jj describe -m "pi-vm: verify mattpocock/skills activation" # only if working copy has changes
```
Otherwise the working copy is clean and the feature is complete.

---

## Notes / gotchas

- **jj identity:** commits currently use the empty identity. If pushing is needed, run
  `jj config set --user user.name "..."` and `jj config set --user user.email "..."` first.
- **No pinning:** openskills clones the default branch each activation; mattpocock floats to `main` (accepted, matches existing repos). To refresh deliberately: `openskills update`.
- **Idempotent:** re-running activation re-installs; safe.
- **Ordering:** `openskillsSync` already runs `entryAfter openskillsInstall` — do not reorder.
