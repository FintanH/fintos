# Centralized user constants for the configuration
#
# Import this file where user-specific values are needed:
#   let user = import ../lib/user.nix; in { ... }
#
# This provides a single source of truth that can be updated
# when migrating to a new machine or adapting for multiple users.
{
  username = "fintohaps";
  fullName = "Fintan Halpenny";
  email = "fintan.halpenny@gmail.com";
  homeDirectory = "/home/fintohaps";

  # SSH public keys
  sshKeys = {
    # Primary signing/authentication key
    primary = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEFsaRqAJ1r6bBFwlcWzJKN7DdjItQDumCNc0wqw6Dvk";
    # Key used for microvm access
    haptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4u7ma3yeNTSVvOmR30hq9G5ZzhUoTMPMTiwVx/MaPx fintohaps@haptop";
  };

  # Radicle-specific settings
  radicle = {
    alias = "fintohaps";
    port = 8776;
    # Tor onion address for radicle node
    onionAddress = "67apylyibh2oeonhwjlkloezjpc2yupjzajfb4o63bwhe75uq2c2dvid.onion";
  };
}
