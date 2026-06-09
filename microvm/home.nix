# Home-manager module used inside every coding-agent microvm.
# Sets up Zsh and points Claude Code at the shared credentials dir.
{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}: {
  imports = [
    ../home/emacs
    ../home/git.nix

    ../home/starship.nix
    ../home/zsh.nix
    ../profiles/rust.nix
  ];

  options.microvm = {
    extraZshInit = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra lines to add to Zsh initContent for this VM.";
    };
  };

  config = {
    home.username = user;
    home.homeDirectory = "/home/${user}";
    xdg.enable = true;

    # Fixed OAuth callback port for claude login via SSH port forwarding.
    # On the host, use `ssh-pi-oauth` alias to forward this port.
    home.sessionVariables.MCP_OAUTH_CALLBACK_PORT = "51515";

    home.packages = with pkgs; [
      delta
      difftastic
      direnv
      fd
      git
      htop
      jujutsu
      jjui
      just
      jq
      mergiraf
      ripgrep
      tree
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
