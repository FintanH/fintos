# Project-specific packages for the Emacs microvm.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    emacs
    git
    ripgrep
  ];
}
