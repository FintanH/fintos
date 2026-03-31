# Pi-specific NixOS config layered on top of microvm/base.nix.
# Imported in microvm.nix alongside microvms/playground.nix.
#
# base.nix already provides:
#   - /home/fintohaps shared via virtiofs (whole home, same path as host)
#   - home-manager wired to microvm/home.nix for fintohaps
#   - SSH, networking, writable nix store overlay, sudo
#
# This file adds:
#   - pi-coding-agent via hm/module/programs/pi.nix
#   - openskills for cross-agent skill synchronization
#   - virtiofs share of /run/vm-secrets/pi (scoped secrets, avoids sops inside VM)
#   - tmux (needed for pi sub-agent pattern)
#
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Overlay: make pkgs.llm-agents.pi available inside the guest.
  # The host's overlay (applied in flake.nix) is not inherited by the guest's
  # separate NixOS evaluation.
  nixpkgs.overlays = [inputs.llm-agents.overlays.default];

  # Secrets: share pi-scoped secrets via virtiofs.
  #
  # Running sops inside the VM causes an initrd ordering race: sops activates
  # before the virtiofs home share mounts, so the age key is never found.
  # The host decrypts secrets via sops templates to /run/vm-secrets/pi/.
  # We share only that scoped directory, not /run/secrets/ (which contains
  # host-only secrets like rad_passphrase).
  sops.secrets = lib.mkForce {};
  sops.age.keyFile = lib.mkForce null;

  microvm.shares = lib.mkAfter [
    {
      proto = "virtiofs";
      tag = "secrets";
      source = "/run/vm-secrets/pi";
      mountPoint = "/run/secrets";
    }
  ];

  # Extra system packages
  environment.systemPackages = with pkgs; [
    tmux # pi's recommended mechanism for background/sub-agent processes
    pkgs.llm-agents.openskills # cross-agent skill synchronization

    # required for pi package installation
    nodejs
    git

    # RustDex CLI binary (code indexer for pi-rustdex extension)
    rustdex
  ];

  # Inject the pi and openskills home-manager modules.
  # home-manager.sharedModules makes our modules available to all users.
  # home-manager.users.fintohaps is merged with the block in base.nix.
  home-manager.sharedModules = [
    ../modules/home-manager/programs/pi.nix
    ../modules/home-manager/programs/openskills.nix
  ];

  home-manager.users.fintohaps = {
    # OpenSkills - remote skill installation
    programs.openskills = {
      enable = true;
      package = pkgs.llm-agents.openskills;

      remoteSkills = [
        # Security & Crypto (critical for Radicle P2P)
        "trailofbits/skills"

        # Rust development methodology
        "obra/superpowers"

        # Additional security (MITRE ATT&CK mapped)
        {source = "mukul975/Anthropic-Cybersecurity-Skills";}
      ];
    };

    # Pi - coding agent with local + openskills paths
    programs.pi = {
      enable = true;
      package = pkgs.llm-agents.pi;
      provider = "anthropic";
      defaultModel = "claude-sonnet-4-5";

      # Secrets arrive via the virtiofs share above (/run/vm-secrets/pi -> /run/secrets)
      apiKeyFile = "/run/secrets/anthropic_api_key";

      # Stable skills: Nix store paths, rebuilt on nixos-rebuild.
      stableSkillDirs = [
        # ../agent/skills/my-stable-skill
      ];

      # Dev skills: base.nix shares /home/fintohaps from the host at the same
      # path, so ~/Developer/AgentSkills is already accessible in the VM.
      devSkillsMount = "/home/fintohaps/Developer/AgentSkills";
      devSkillNames = [
        "radicle-dev/rust-tdd"
        "radicle-dev/rust-functional"
        "radicle-dev/rust-types"
        "radicle-dev/crdt-development"
        "radicle-dev/distributed-systems"
        "radicle-dev/git-internals"
        "radicle-dev/radicle-cobs"
        "Rust/rust-skills-rules"
      ];

      # Pi packages as Nix derivations (peer-deps-only, fully declarative)
      packages = with pkgs.piPackages; [
        plan-mode # Structured planning (/plan)
        superpowers-plus # TDD enforcement (RED→GREEN→REFACTOR)
        gitnexus # Git integration
        rustdex # Rust documentation lookup
      ];

      # Pi-managed sources (packages with runtime deps or complex git repos)
      packageSources = [
        "npm:@zenobius/pi-worktrees" # Git worktree management
        "npm:pi-fetch" # URL fetching
        "git:github.com/can1357/oh-my-pi" # Atomic git commits, LSP
        "git:github.com/jayshah5696/pi-agent-extensions" # Interactive code review
      ];

      extraSettings = {
        thinking = "medium";
        # Include openskills directories for skill discovery
        skills = [
          "~/.claude/skills" # openskills global
          "~/.agent/skills" # openskills universal
        ];
      };

      agentsMd = builtins.readFile ./pi/agent.md;

      # Subagent definitions — each becomes ~/.pi/agent/agents/<name>.md
      agents = {
        scout = {
          description = "Fast codebase recon — finds relevant code and returns structured context for handoff";
          model = "claude-haiku-4-5";
          tools = ["read" "grep" "find" "ls" "bash"];
          systemPrompt = builtins.readFile ./pi/agents/scout.md;
        };
        implementer = {
          description = "Implements code tasks autonomously with full tool access, following TDD and project conventions";
          systemPrompt = builtins.readFile ./pi/agents/implementer.md;
        };
        reviewer = {
          description = "Code review specialist — analyzes quality, correctness, security, and style";
          tools = ["read" "grep" "find" "ls" "bash" "rustdex"];
          systemPrompt = builtins.readFile ./pi/agents/reviewer.md;
        };
        nixos-specialist = {
          description = "NixOS and Nix configuration specialist — overlays, home-manager, microvm setup";
          systemPrompt = builtins.readFile ./pi/agents/nixos-specialist.md;
        };
      };
    };

    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      historyLimit = 50000;
      extraConfig = ''
        set -g mouse on
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
      '';
    };
  };
}
