# Aggregates all home-manager program modules
{ ... }: {
  imports = [
    ./radicle.nix
    ./pi.nix
    ./openskills.nix
  ];
}
