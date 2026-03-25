## General
- Always explain *why* a change is being made, not just what it does.
- Prefer minimal diffs — change only what is strictly necessary to
  accomplish the task. Leave unrelated code untouched.
- Always ask for clarification if you cannot make progress on task.

## Direnv

If you notice an `.envrc` file, then execute:
```
direnv allow
```
If this does not work, notify me.

## Nix / NixOS
- Prefer declarative NixOS and Home Manager idioms over imperative shell
  commands. If a Nix-native option exists, use it.
- When editing .nix files, preserve the surrounding formatting style.

## Rust
- Write idiomatic Rust: prefer iterators, avoid unnecessary clones, use
  the type system to make illegal states unrepresentable.
- Isolate business logic from I/O, and use traits to represent I/O "effects".
- Only suggest `unsafe` when there is no safe alternative, and always
  accompany it with a `// SAFETY:` comment explaining the invariant.

## Programming
- Write functional core, imperative shell style code.
- Prefer DDD techniques.
- Use TDD and red/green testing techniques.
- Use Sans-IO techniques for protocol related code.
