{
  config,
  lib,
  pkgs,
  ...
}: let
  user-constants = import ../lib/user.nix;

  user = {
    name = user-constants.fullName;
    email = user-constants.email;
  };

  aliases = {
    gs = "status";
    gd = "diff";
    logs = "log --show-signature";
    commits = "commit --trailer \"X-Clacks-Overhead: GNU Terry Pratchett\" -s -v";
    lg = "log --date=format:'%a %b %e, %Y' --pretty=format:'%C(yellow)%h%C(reset) %s %C(cyan)%cd%C(reset) %C(blue)%an%C(reset) %C(green)%d%C(reset)' --graph";
  };
in {
  programs.git = {
    enable = true;
    ignores = [
      # direnv files
      ".direnv"
      ".envrc"

      # emacs files
      "*~undo-tree~"
      "**/.\\#*"

      # pi files
      # Note that these may need to be re-enabled for local projects
      ".pi"
    ];
    settings = {
      inherit user;
      alias = aliases;

      core = {
        excludesFile = "~/.config/git/ignore";
        pager = "delta";
      };

      # Displaying branches and tags in a better order
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";

      delta = {
        # use n and N to move between diff sections
        navigate = true;
        # set to true if you're in a terminal w/ a light background colour
        light = false;
        # https://github.com/dandavison/magit-delta/issues/13
        # line-numbers = true;
        side-by-side = true;
        relative-paths = true;
        file-style = "yellow";
        hunk-header-style = "line-number syntax";
      };

      fetch = {
        # Prune remote branches and tags if they have been removed on the remote
        prune = true;
        pruneTags = true;
      };

      # Helps rebasing with conflicts by remembering the resolutions
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      # Prompt for the fixed command when a typo is made
      help.autocorrect = "prompt";

      # Shows diff when committing, i.e. git commit -v
      commit = {
        verbose = true;
        gpgSign = true;
      };

      format.signOff = true;

      merge = {
        conflictstyle = "zdiff3";
      };

      diff = {
        algorithm = "histogram";
        renames = true;
        mnemonicPrefix = true;
        external = "difft";
        colorMoved = "default";
      };
    };

    signing = {
      signByDefault = true;
      format = "ssh";
      key = "key::${user-constants.sshKeys.primary}";
    };
  };
}
