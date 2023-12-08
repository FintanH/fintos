{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    fzf-zsh
    oh-my-zsh
    ripgrep
    zsh
  ];

  programs.zsh = {
    ohMyZsh = {
      enable = true;
      plugins = [
        "cargo"
        "fzf"
        "git"
        "man"
        "ripgrep"
        "rustup"
        "stack"
      ];
      theme = "half-life";
      customPkgs = [
        pkgs.nix-zsh-completions
      ];
    };
    enable = true;
    enableCompletion = true;
    interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

      # Customize your oh-my-zsh options here
      ZSH_THEME="half-life"
      plugins=(git)

      HISTFILESIZE=50000
      HISTSIZE=50000
      setopt SHARE_HISTORY
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_DUPS
      setopt INC_APPEND_HISTORY
      autoload -U compinit && compinit
      unsetopt menu_complete
      setopt completealiases

      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      if [ -f ~/.aliases ]; then
        source ~/.aliases
      fi

      source $ZSH/oh-my-zsh.sh
    '';
  };
}
