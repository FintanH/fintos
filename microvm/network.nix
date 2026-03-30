# Network prep for microvm.nix VMs.
#
# Creates a "microbr" bridge on 192.168.83.1/24 and NATs traffic
# out through your physical interface.
#
# Uses plain ip commands instead of systemd-networkd.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Physical network interface used for NAT (microvm internet access).
  # Update this if your interface name changes (check with `ip link`).
  externalInterface = "wlp192s0";
in {
  # Enable IP forwarding (required for NAT)
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Create the bridge before any microvm starts
  systemd.services.microvm-bridge = {
    description = "Create microvm bridge";
    wantedBy = ["multi-user.target"];
    before = ["microvm@.service"];
    after = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "microvm-bridge-up" ''
        ${pkgs.iproute2}/bin/ip link add microbr type bridge 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip addr add 192.168.83.1/24 dev microbr 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set microbr up
      '';
      ExecStop = pkgs.writeShellScript "microvm-bridge-down" ''
        ${pkgs.iproute2}/bin/ip link set microbr down 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del microbr 2>/dev/null || true
      '';
    };
  };

  # Add tap interfaces to bridge when they appear
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="microvm*", RUN+="${pkgs.iproute2}/bin/ip link set %k master microbr"
  '';

  # NAT for microvm network
  networking.nat = {
    enable = true;
    internalInterfaces = ["microbr"];
    inherit externalInterface;
  };
}
