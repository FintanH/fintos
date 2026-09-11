# NixOS Configuration

Personal NixOS configuration managed with flakes for a Framework 13 laptop.

## Quick Start

```bash
# Build the system
sudo nixos-rebuild switch --flake .#haptop

# Or from anywhere (registered in nix registry)
sudo nixos-rebuild switch --flake fintos
```

## Directory Structure

```
.
├── flake.nix                   # Flake inputs and NixOS system definition
├── configuration.nix           # System-level NixOS configuration
├── hardware-configuration.nix  # Generated hardware scan
├── home.nix                    # Home-manager entry point (host)
│
├── lib/                        # Shared constants
│   └── user.nix                # Centralized user identity (name, email, SSH keys)
│
├── agent/                      # AI agent configuration
│   └── models.nix              # Ollama model definitions (shared across consumers)
│
├── modules/                    # Reusable option-defining modules
│   ├── nixos/                  # NixOS modules (gnome, tor, zsh)
│   │   └── default.nix         # Aggregator
│   └── home-manager/           # Home-manager modules
│       ├── programs/           # pi, openskills, radicle
│       └── services/           # radicle-node systemd service
│
├── profiles/                   # Profiles that configure modules for this user
│   ├── radicle.nix             # Radicle node restart on config change
│   ├── radicle-service.nix     # Radicle service config (sops secrets, connect peers)
│   └── rust.nix                # Rust toolchain (rustup, cargo config)
│
├── home/                       # Home-manager feature configurations
│   ├── emacs/                  # Emacs (rycee emacs-init module)
│   │   ├── default.nix         # Entry point, prelude, packages
│   │   ├── base.nix            # Core packages (autorevert, saveplace)
│   │   ├── ui.nix              # Theme (base16, beacon, nyan-mode)
│   │   ├── org.nix             # Org-mode
│   │   └── languages/          # Per-language support (rust, nix, haskell, web)
│   ├── git.nix                 # Git + delta + difftastic
│   ├── zsh.nix                 # Zsh + autosuggestions + direnv
│   ├── starship.nix            # Starship prompt
│   ├── secrets.nix             # sops-nix home-manager secrets
│   └── destiny.nix             # Custom package derivation
│
├── overlays/                   # Nixpkgs overlays
│   ├── radicle-node.nix        # Radicle 1.8.0 (ahead of nixpkgs)
│   └── pi-packages.nix         # Pi extensions + RustDex CLI
│
├── hardware/                   # Hardware-specific configurations
│   ├── common/                 # Shared CPU/GPU/storage settings
│   └── framework/              # Framework laptop specifics
│
├── microvm.nix                 # MicroVM declarations (pi, playground)
├── microvm/                    # MicroVM infrastructure
│   ├── base.nix                # Parameterized base for all VMs
│   ├── home.nix                # Home-manager for VM guests
│   └── network.nix             # Bridge + NAT for VM networking
├── microvms/                   # Per-VM NixOS extensions
│   ├── pi.nix                  # Pi coding agent VM
│   └── playground.nix          # General-purpose VM
│
└── secrets/                    # SOPS-encrypted secrets
    └── secrets.yaml
```

### Conventions

- **`modules/`** contains reusable option-defining modules (`mkOption`, `mkEnableOption`)
- **`profiles/`** contains configurations that *set values* on those modules
- **`home/`** contains home-manager feature configs (programs, shells, editors)
- **`lib/user.nix`** is the single source of truth for user identity — imported wherever user constants are needed
- **`agent/models.nix`** defines Ollama models as an attrset, consumed by `configuration.nix`, and `emacs/default.nix`

## Secrets

Secrets (API keys, passphrases) are managed with [sops-nix](https://github.com/Mic92/sops-nix) and encrypted in `secrets/secrets.yaml`.

```bash
# Edit secrets
sops secrets/secrets.yaml

# After updating age keys in .sops.yaml
sops updatekeys secrets/secrets.yaml
```

## MicroVMs

[microvm-nix](https://microvm-nix.github.io/microvm.nix/intro.html) provides sandboxed VM environments, primarily for AI coding agents with filesystem access.

VMs share `/home/fintohaps/Developer` via virtiofs (read-write) and secrets via scoped virtiofs mounts. The host decrypts secrets with sops and exposes only per-VM scoped directories.

### Diagnostics

```bash
# VM service
journalctl -xeu microvm@<vm-name>.service --no-pager

# Virtiofs
journalctl -xeu microvm-virtiofsd@<vm-name>.service --no-pager

# TAP interfaces
journalctl -xeu microvm-tap-interfaces@<vm-name>.service --no-pager
```

## Development

```bash
# Format all .nix files
nix fmt
```

## Merging PDFs

I always end up needing to merge two PDFs, so here is the command:

```
pdftk [<a>.pdf <b>.pdf ...] cat output <final>.pdf
```
