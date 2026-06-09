{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initContent = ''
      fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
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

      # SSH into pi-vm with OAuth callback ports forwarded
      # - Port 51515: Claude Code (via MCP_OAUTH_CALLBACK_PORT)
      # - Port 53692: Pi coding agent (hardcoded in pi-mono)
      # Usage: ssh-pi-oauth, then run `claude login` or `pi` → `/login`
      ssh-pi-oauth = "ssh -L 51515:localhost:51515 -L 53692:localhost:53692 fintohaps@192.168.83.8";
    };
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];
  };
}
