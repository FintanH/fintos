# NixOS Configuration

Personal NixOS configuration managed with flakes.

## Quick Start

```bash
# Build the system
sudo nixos-rebuild switch --flake .#haptop

# Or from anywhere
sudo nixos-rebuild switch --flake fintos
```

## Directory Structure

```
.
├── flake.nix                 # Flake definition and inputs
├── configuration.nix         # System-level NixOS configuration
├── home.nix                  # Home-manager user configuration
├── hardware-configuration.nix
├── microvm.nix               # MicroVM host configuration
│
├── lib/                      # Shared library functions and constants
│   └── user.nix              # Centralized user constants (username, email, keys)
│
├── modules/                  # Reusable NixOS and home-manager modules
│   ├── nixos/                # System-level modules (tor, zsh)
│   └── home-manager/         # User-level modules
│       ├── programs/         # Program configurations (radicle)
│       └── services/         # User services (radicle-node)
│
├── home/                     # User environment configurations
│   ├── emacs/                # Emacs configuration
│   │   ├── default.nix       # Entry point with prelude
│   │   ├── base.nix          # Core editor settings
│   │   ├── ui.nix            # Theme and visual configuration
│   │   ├── org.nix           # Org-mode configuration
│   │   └── languages/        # Language-specific configurations
│   ├── git.nix
│   ├── zsh.nix
│   ├── starship.nix
│   └── ...
│
├── overlays/                 # Package overlays
│   └── radicle-node.nix
│
├── hardware/                 # Hardware-specific configurations
│   ├── common/               # Shared hardware settings
│   └── framework/            # Framework laptop specifics
│
├── hm/                       # Legacy home-manager organization
│   ├── module/               # Custom HM modules
│   ├── profiles/             # User profiles
│   └── services/             # User services
│
├── microvm/                  # MicroVM infrastructure
├── microvms/                 # MicroVM definitions
│
└── secrets/                  # SOPS-encrypted secrets
```

## Key Components

### Flake Inputs

- **nixpkgs**: NixOS 25.11
- **home-manager**: User environment management
- **microvm**: Lightweight VMs
- **sops-nix**: Secrets management
- **nur**: Nix User Repository

### User Configuration

User constants are centralized in `lib/user.nix`:

```nix
{
  username = "fintohaps";
  fullName = "Fintan Halpenny";
  email = "fintan.halpenny@gmail.com";
  # ...
}
```

## Secrets

Secrets such as API keys and passwords are encrypted in an encrypted file,
`secrets/secrets.yaml`.

To update this file, run:

```
sops secrets/secrets.yaml
```

which will open editor for modifying the file.

The `.sops.yaml` file contains `age` public keys for allowing decryption to
occur. If these keys are updated, then run:

```
sops updatekeys secrets/secrets.yaml
```

### Emacs Configuration

The Emacs setup uses [rycee's emacs-init module](https://gitlab.com/rycee/nur-expressions) with configurations split by concern:

- **base.nix**: Core packages (autorevert, saveplace, whitespace)
- **ui.nix**: Visual theme (base16, beacon, nyan-mode, ace-window)
- **languages/**: Per-language support (haskell, rust, nix, web, misc)

## Development

Format with alejandra:

```bash
nix fmt
```

## microvm

[microvm-nix]: https://microvm-nix.github.io/microvm.nix/intro.html

The [microvm-nix] project is used for created sandboxed VM environments.
At the moment, these are used for playing around with AI agents,
so that I can have some peace of mind when using something that has edit access to the filesystem.

### Diagnostics

Developing and improving this setup can be a finicky beast.
I have often successfully switched a NixOS build, only to find that the VM would not start.

In these scenarios, it's worth checking the following services to diagnose what went wrong.

The VM service itself:
```
journalctl -xeu microvm@{vm-name}.service --no-pager
```

The VM's virtual filesystem service:
```
journalctl -xeu microvm-vitiosfsd@{vm-name}.service --no-pager
```

The VM's TAP interfaces service:
```
journalctl -xeu microvm-tap-interfaces@{vm-name}.service
```
