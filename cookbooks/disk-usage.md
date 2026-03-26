# Debugging Disk Usage on NixOS

This cookbook documents common commands and directories to check when diagnosing disk space issues on a NixOS system.

## Initial Diagnosis

### Check Overall Filesystem Usage

```bash
df -h
```

Start here to identify which filesystem is running low on space.
Pay attention to the mount points - on NixOS, `/nix/store` is typically on the root filesystem,
so high usage there doesn't necessarily mean the nix store is the problem.

### Find What's Using Space at the Root Level

```bash
sudo du -sh /* 2>/dev/null | sort -hr | head -20
```

This reveals the top-level directories consuming space.
Compare this against what `df` reports - if `/nix` is small but the filesystem is full,
the problem lies elsewhere. Common culprits include `/home`, `/var`, and `/nix`.

## NixOS-Specific Checks

### Check Nix Store Size

```bash
sudo du -sh /nix/store
```

This shows the actual disk usage of the nix store.
If this is small but `df` shows high usage, the nix store isn't your problem - look elsewhere on the filesystem.

### Count Store Paths

```bash
ls /nix/store | wc -l
```

A high number of store paths (tens of thousands) might indicate accumulated derivations.
However, the count alone doesn't indicate a problem - what matters is whether garbage collection can clean them up.

### List Largest Store Paths

```bash
sudo du -sh /nix/store/* 2>/dev/null | sort -hr | head -30
```

Identifies the largest individual packages in the store.
Useful for understanding what's consuming space, though these may be legitimate dependencies of your current system.

### Check Garbage Collection Roots

```bash
nix-store --gc --print-roots | grep -v '{temp}' | grep -v '/proc/'
```

GC roots are symlinks that keep store paths alive. Common roots include:
- `/run/current-system` - your active NixOS configuration
- `/run/booted-system` - the system you booted into (may differ after rebuilds)
- `~/.local/state/home-manager/gcroots/current-home` - home-manager generation
- `.direnv/` directories - nix-direnv cached development shells
- `result` symlinks - outputs from `nix build`

### Check System Generations

```bash
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
```

Each NixOS generation keeps its entire closure alive.
If you have many generations, deleting old ones can free significant space:

```bash
sudo nix-env --delete-generations +7d -p /nix/var/nix/profiles/system
```

### Check Current System Closure Size

```bash
nix path-info -Sh /run/current-system
```

Shows the total size of your running NixOS system's closure.
This is the minimum space required by the nix store for your current configuration.

### Check for Dead Paths

```bash
nix-store --gc --print-dead | wc -l
```

Shows how many store paths would be removed by garbage collection.
A high number indicates potential space savings.

### Run Garbage Collection

```bash
# Delete old generations and collect garbage
sudo nix-collect-garbage -d

# Or just collect garbage without deleting generations
sudo nix-collect-garbage
```

The `-d` flag deletes old profile generations before collecting garbage, allowing more paths to be freed.

## Development Environment Checks

### Find nix-direnv Caches

```bash
find ~/Developer -type d -name '.direnv' 2>/dev/null
```

nix-direnv caches development shells in `.direnv/` directories. Each cache keeps flake inputs and shell closures alive.
For Rust projects, a single dev shell can be 4+ GB.

To clean all direnv caches (they rebuild automatically when you enter the directory):

```bash
find ~/Developer -type d -name '.direnv' -exec rm -rf {} + 2>/dev/null
```

### Find Result Symlinks

```bash
find ~/Developer -maxdepth 3 -name 'result*' -type l 2>/dev/null
```

`result` symlinks from `nix build` keep their outputs alive. Delete them if you no longer need the builds:

```bash
find ~/Developer -maxdepth 3 -name 'result*' -type l -delete
```

### Find Rust Target Directories

```bash
du -sh ~/Developer/*/target 2>/dev/null | sort -hr | head -10
```

Rust `target/` directories can grow very large (multiple GB per project).
Clean them with `cargo clean` in each project, or remove them directly:

```bash
# Remove all target directories (builds will recompile when needed)
find ~/Developer -type d -name 'target' -prune -exec rm -rf {} + 2>/dev/null
```

## Common Space Hogs

### Home Directory Breakdown

```bash
du -sh ~/* ~/.* 2>/dev/null | sort -hr | head -20
```

This reveals large directories in your home folder. Common culprits:

- **`~/.local/share/ollama`**: AI model weights (can be 20+ GB per model)
- **`~/.rustup`**: Rust toolchains (10-15 GB typical)
- **`~/.cargo`**: Cargo cache and installed binaries
- **`~/.cache`**: Application caches
- **`~/Developer`**: Source code and build artifacts

### Check Ollama Models

```bash
du -sh ~/.local/share/ollama
ollama list
```

Large language models consume significant space. Remove unused models with:

```bash
ollama rm <model-name>
```

### Check /var/lib Contents

```bash
sudo du -sh /var/lib/* 2>/dev/null | sort -hr | head -10
```

Common large directories:
- **`/var/lib/microvms`**: Microvm disk images
- **`/var/lib/containers`**: Podman/Docker images and volumes
- **`/var/lib/ollama`**: System-wide Ollama models (if not using user service)

### Clean Podman/Containers

```bash
# See what exists
podman ps -a          # Containers
podman images -a      # Images
podman volume ls      # Volumes

# Remove everything
podman system prune -a -f --volumes
```

### Check Systemd Journal Size

```bash
journalctl --disk-usage
```

If large, vacuum it:

```bash
sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-time=7d
```

## Prevention: Automatic Cleanup

### Configure Nix Garbage Collection

Add to `configuration.nix`:

```nix
nix.gc = {
  automatic = true;
  dates = "daily";
  options = "--delete-older-than 7d";
};

nix.settings.auto-optimise-store = true;

nix.extraOptions = ''
  min-free = ${toString (50 * 1024 * 1024 * 1024)}
  max-free = ${toString (100 * 1024 * 1024 * 1024)}
'';
```

This runs GC daily, removes derivations older than 7 days, optimizes the store via hardlinking, and auto-triggers GC when free space drops below 50GB.

### Limit Journal Size

Add to `configuration.nix`:

```nix
services.journald.extraConfig = ''
  SystemMaxUse=500M
  MaxRetentionSec=7day
  Compress=yes
'';
```

## Quick Reference

| Check | Command |
|-------|---------|
| Filesystem usage | `df -h` |
| Directory sizes | `sudo du -sh /* 2>/dev/null \| sort -hr` |
| Nix store size | `sudo du -sh /nix/store` |
| GC roots | `nix-store --gc --print-roots` |
| System generations | `sudo nix-env --list-generations -p /nix/var/nix/profiles/system` |
| System closure size | `nix path-info -Sh /run/current-system` |
| Run garbage collection | `sudo nix-collect-garbage -d` |
| Find direnv caches | `find ~/Developer -type d -name '.direnv'` |
| Journal size | `journalctl --disk-usage` |
