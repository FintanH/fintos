{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initExtra = ''
      autoload -U colors && colors;
      eval "$(direnv hook zsh)";
    '';
    sessionVariables = {
      EDITOR = "${pkgs.emacs}/bin/emacs";
    };
    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-users/zsh-completions";}
        {name = "zsh-users/zsh-autosuggestions";}
        {name = "zsh-users/zsh-syntax-highlighting";}
        {name = "ryutok/rust-zsh-completions";}
      ];
    };
  };
}
