# Nix language support
{ pkgs, ... }: {
  programs.emacs.init.usePackage = {
    nix-mode = {
      enable = true;
      mode = [''"\\.nix\\'"''];
      hook = ["(nix-mode . subword-mode)"];
    };

    nix-sandbox = {
      enable = true;
      command = ["nix-current-sandbox" "nix-shell-command"];
    };
  };
}
