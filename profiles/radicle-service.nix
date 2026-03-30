{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: let
  inherit (builtins) toString;

  inherit (lib) mkIf optional;

  package = pkgs.radicle-node-overlay;

  port = 8776;
  tor =
    (osConfig.services.tor.client or {enable = false;})
    // {
      # TODO: Depends on Tor running on the system.
      # sudo -u tor cat /var/lib/tor/onion/radicle/hostname
      address = "67apylyibh2oeonhwjlkloezjpc2yupjzajfb4o63bwhe75uq2c2dvid.onion:${toString port}";
    };
in {
  programs.radicle = {
    cli = {
      inherit package;
    };
    uri = {
      web-rad.enable = false;
      rad.browser.enable = false;
    };
    settings = {
      preferredSeeds = [];
      node = {
        connect = let
          connectAddr = {
            nid,
            addr,
            port ? 8776,
          }: "${nid}@${addr}:${toString port}";
        in [
          (connectAddr {
            nid = "z6MksmpU5b1dS7oaqF2bHXhQi1DWy2hB7Mh9CuN7y1DN6QSz";
            addr = "seed.radicle.xyz";
          })
          (connectAddr {
            nid = "z6MkuQeVNvq6TwrAbaTuwZihAxki3SYhgbLw1PcojjAJJLPG";
            addr = "moejgcv4yckzqkqjgobvghf636g2upbrhhcgpax2nucychhlgkxz6cqd.onion";
          })
        ];
        onion = mkIf tor.enable {
          mode = "proxy";
          address = "${tor.socksListenAddress.addr}:${toString tor.socksListenAddress.port}";
        };
        externalAddresses = optional tor.enable tor.address;
        listen = optional tor.enable "127.0.0.1:${toString port}";
      };
    };
  };
  services.radicle.node = {
    inherit package;
    enable = true;
    # lazy = true;
    environment.RUST_BACKTRACE = "1";
    args = "--log-level debug";
  };

  # Add EnvironmentFile for RAD_PASSPHRASE via systemd override
  systemd.user.services.radicle-node.Service.EnvironmentFile = [
    config.sops.templates."radicle.env".path
  ];
}
