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
    initContent = ''
      autoload -U colors && colors;
      eval "$(direnv hook zsh)";
    '';
    sessionVariables = {
      EDITOR = "${pkgs.emacs}/bin/emacs";
    };
    shellAliases = {
      ll = "ls -l";

      # Drop me into the storage of the Radicle repository
      rad-storage = "cd ~/.radicle/storage/$(rad . | sed 's/rad://g')";
      # Print out the URL for a patch.
      # Arg 1: Host URL, e.g. "seed.radicle.xyz"
      # Arg 2: Patch ID, e.g. "d9d44fed19d98f67374297c899cd969733b26958"
      rad-patch-url = "f() {rad config | jq -r .publicExplorer | sed -e 's/\$host/$1/' -e 's/\$rid/$(rad .)/' -e 's/\$path/\/patches\/$2/'};f";
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
