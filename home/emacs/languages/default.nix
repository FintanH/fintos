# Aggregates all language-specific configurations
{...}: {
  imports = [
    ./haskell.nix
    ./rust.nix
    ./nix.nix
    ./web.nix
    ./misc.nix
  ];
}
