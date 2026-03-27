# Parameterized module that every coding-agent VM imports.
# Provides: networking, shared dirs, qemu config,
#           home-manager with Zsh + Claude Code + opencode.
#
# Called as a function from microvm.nix — see there for usage.
{
  hostName,
  vmName,
  ipAddress,
  tapId,
  mac,
  workspace,
  user,
  nixpkgs-unstable,
  home-manager,
  nurNoPkgs,
  inputs,
  extraZshInit ? "",
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  pkgsUnstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in {
  imports = [
    home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  # ── home-manager ───────────────────────────────────────────────
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {inherit user nurNoPkgs inputs;};
  home-manager.users.${user} = {
    imports = [
      nurNoPkgs.repos.rycee.hmModules.emacs-init
      ./home.nix
    ];
    microvm.extraZshInit = extraZshInit;
  };

  # ── Claude Code CLI (from nixpkgs-unstable, unfree) ───────────
  environment.systemPackages = [
    pkgsUnstable.claude-code
  ];

  networking.hostName = hostName;
  system.stateVersion = "25.11";
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # ── File Descriptor Limits ──────────────────────────────────────
  # Fix "too many open files" errors during garbage collection
  boot.kernel.sysctl."fs.file-max" = 2097152;
  boot.kernel.sysctl."fs.nr_open" = 2097152;

  # ── SSH ────────────────────────────────────────────────────────
  services.openssh.enable = true;

  # Use SSH host keys mounted from outside the VM (stable across rebuilds)
  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  # ── User (match UIDs/GIDs with host) ──────────────────────────
  users.groups.${user} = {gid = 1000;};
  users.users.${user} = {
    group = user;
    # Secrets are scoped to this group, see `configuration.nix` under `sops`
    extraGroups = ["kvm"];
    isNormalUser = true;
    uid = 1000;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4u7ma3yeNTSVvOmR30hq9G5ZzhUoTMPMTiwVx/MaPx fintohaps@haptop"
    ];
  };

  # ── Home directory setup ─────────────────────────────────────
  # Ensure home directory has correct ownership (runs after filesystems mount)
  systemd.tmpfiles.rules = [
    "d /home/${user} 0755 ${user} ${user} -"
  ];

  # ── Secrets ───────────────────────────────────────────────────
  sops = {
    age.sshKeyPaths = [
      "/etc/ssh/host-keys/ssh_host_ed25519_key"
    ];

    defaultSopsFile = ../secrets/secrets.yaml;

    secrets = {
      anthropic_api_key = {
        mode = "0440";
        group = user;
      };
      gemini_api_key = {
        mode = "0440";
        group = user;
      };
    };
  };

  # ── Networking ─────────────────────────────────────────────────
  services.resolved.enable = true;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.tempAddresses = "disabled";
  systemd.network.enable = true;

  systemd.network.networks."10-e" = {
    matchConfig.Name = "e*";
    addresses = [{Address = "${ipAddress}/24";}];
    routes = [{Gateway = "192.168.83.1";}];
  };

  networking.nameservers = ["8.8.8.8" "1.1.1.1"];

  # Disable firewall — we're behind NAT anyway
  networking.firewall.enable = false;

  # ── Fast shutdowns ────────────────────────────────────────────
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "5s";
  };

  # ── Fix for microvm shutdown hang (issue #170) ────────────────
  # Without this, systemd tries to unmount /nix/store during
  # shutdown but umount lives in /nix/store → deadlock.
  systemd.mounts = [
    {
      what = "store";
      where = "/nix/store";
      overrideStrategy = "asDropin";
      unitConfig.DefaultDependencies = false;
    }
  ];

  security.sudo.extraRules = [
    {
      users = ["fintohaps"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # ── microvm settings ──────────────────────────────────────────
  microvm = {
    # Writable nix store overlay (tmpfs — ephemeral).
    # Required for home-manager activation / nix-daemon.
    writableStoreOverlay = "/nix/.rw-store";

    # Persistent volumes (stored in /var/lib/microvms/<name>/)
    volumes = [
      {
        mountPoint = "/var";
        image = "var.img";
        size = 102400; # 100 GB
      }
      {
        mountPoint = "/nix/.rw-store";
        image = "nix-store.img";
        size = 61440; # 60 GB for nix store
      }
      {
        mountPoint = "/home/${user}";
        image = "home.img";
        size = 102400; # 100 GB for home directory
      }
    ];

    shares = [
      # Host's /nix/store (avoids building a squashfs image)
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      # Developer directory shared from host (read-write)
      {
        proto = "virtiofs";
        tag = "developer";
        source = "/home/${user}/Developer";
        mountPoint = "/home/${user}/Developer";
      }
      # SSH host keys (stable across rebuilds)
      {
        proto = "virtiofs";
        tag = "ssh-keys";
        source = "${workspace}/ssh-host-keys";
        mountPoint = "/etc/ssh/host-keys";
      }
    ];

    interfaces = [
      {
        type = "tap";
        id = tapId;
        mac = mac;
      }
    ];

    hypervisor = "qemu";
    vcpu = 8;
    # 32 GB RAM
    mem = 32768;
    socket = "control.socket";

    # Use file handles instead of O_PATH descriptors in virtiofsd
    # Prevents "too many open files" when sharing large directories
    virtiofsd.inodeFileHandles = "prefer";
    virtiofsd.threadPoolSize = 16;
  };
}
