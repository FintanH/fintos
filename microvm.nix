# Declares all coding-agent microvms.
# Each VM is ephemeral — nothing persists except the shared workspace
# and Claude credentials directory.
{
  config,
  lib,
  pkgs,
  inputs,
  nurNoPkgs,
  ...
}: let
  inherit
    (inputs)
    nixpkgs-unstable
    microvm
    home-manager
    ;

  microvmBase = import ./microvm/base.nix;
  user = "fintohaps";
in {
  microvm.vms.playground = {
    autostart = false;
    config = {
      imports = [
        microvm.nixosModules.microvm
        (microvmBase {
          vmName = "playground";
          hostName = "playground";
          ipAddress = "192.168.83.7";
          tapId = "microvm5";
          mac = "02:00:00:00:00:06";
          workspace = "/home/${user}/microvm/playground";
          inherit user nixpkgs-unstable home-manager nurNoPkgs inputs;
        })
        ./microvms/playground.nix
      ];
      microvm.credentialFiles = {
        ssh_host_ed25519_key = "/home/${user}/microvm/playground/ssh-host-keys/ssh_host_ed25519_key";
      };
    };
  };

  microvm.vms.pi = {
    autostart = true;
    config = {
      imports = [
        microvm.nixosModules.microvm
        {_module.args.inputs = inputs;}
        (microvmBase {
          vmName = "pi";
          hostName = "pi-vm";
          ipAddress = "192.168.83.8";
          tapId = "microvm6";
          mac = "02:00:00:00:00:07";
          workspace = "/home/${user}/microvm/pi";
          inherit user nixpkgs-unstable home-manager nurNoPkgs inputs;
        })
        ./microvms/pi.nix
      ];
      microvm.credentialFiles = {
        ssh_host_ed25519_key = "/var/lib/microvm-keys/pi/ssh_host_ed25519_key";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/microvm-keys 0550 microvm microvm -"
    "d /var/lib/microvm-keys/pi 0550 microvm microvm -"
    "z /var/lib/microvm-keys/pi/ssh_host_ed25519_key 0400 microvm microvm -"
  ];

  # ── Add more VMs below ────────────────────────────────────────
  # microvm.vms.myprojectvm = { ... };
}
