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
  ];

  # Inject the pi home-manager module.
  # home-manager.sharedModules makes our module available to all users.
  # home-manager.users.fintohaps is merged with the block in base.nix.
  home-manager.sharedModules = [
    ../hm/module/programs/pi.nix
  ];

  home-manager.users.fintohaps = {
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

      # Enable extended thinking for complex CRDT/distributed systems work
      extraSettings = {
        thinking = "medium";
      };

      npmPackages = [
        "npm:@mariozechner/pi-plan-mode"
        # "npm:@mariozechner/pi-subagent"
      ];
      agentsMd = builtins.readFile ./pi/agent.md;
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
