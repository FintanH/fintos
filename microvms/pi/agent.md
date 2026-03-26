# Global Agent Instructions

## Environment
- Running inside NixOS microvm `pi-vm` on `haptop`
- ~/Developer/AgentSkills is editable on the host; changes are live here
- Skills available in ~/.pi/agent/skills/

## Development Practices
- Test-Driven Development (TDD) - write tests first
- Pure core, imperative shell architecture
- Property-based testing to reason about systems
- Avoid over-engineering; minimal changes for the task at hand
- Be aware of backwards-compatibility in APIs and functionality

## Rust Conventions
- Leverage Rust's type system for correctness
- Prefer using pure data rather than using I/O
- Prefer private modules and functions before using `pub`
- Do not import `self`, e.g. use `use foo::bar;` over `use foo::bar::{self, Bar};`
- Documentation should foremost describe the usage, mentioning implementation
  details if necessary.

## NixOS Conventions
- Format all .nix files with alejandra (`nix fmt`)
- Packages not in nixpkgs -> overlay/<n>.nix (overlay function)
- Home-manager modules -> hm/module/programs/ or hm/module/services/
- Per-VM NixOS extras -> microvms/<n>.nix (layered on microvm/base.nix)

## Pi Workflow
- Use `/skill:<name>` to load specific skills on-demand
- Use tmux for long-running processes (pi has no background bash)
- Sub-agents: spawn `pi` instances in separate tmux windows/panes
- Use `/plan` for structured planning (requires pi-plan-mode package)

## Available Skills
Load with `/skill:<name>`:
- rust-tdd: Test-driven development workflow
- rust-functional: Pure core, imperative shell patterns
- rust-types: Leveraging Rust's type system
- crdt-development: CRDT theory and implementation
- distributed-systems: Gossip protocols, peer discovery
- git-internals: Git object model, refs, protocols
- radicle-cobs: Collaborative Objects patterns
