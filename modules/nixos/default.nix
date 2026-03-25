# Aggregates all NixOS modules
{ ... }: {
  imports = [
    ./tor.nix
    ./zsh.nix
  ];
}
