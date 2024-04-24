{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "Fintan Halpenny";
    userEmail = "fintan.halpenny@gmail.com";
    signing = {
      signByDefault = true;
      key = "C93C17467280C75B";
    };

    aliases = {
      gs = "status";
      gd = "diff";
      logs = "log --show-signature";
      commits = "commit --trailer \"X-Clacks-Overhead: GNU Terry Pratchett\" -s -v";
      lg = "log --date=format:'%a %b %e, %Y' --pretty=format:'%C(yellow)%h%C(reset) %s %C(cyan)%cd%C(reset) %C(blue)%an%C(reset) %C(green)%d%C(reset)' --graph";
    };
    extraConfig = {
      core = {
        excludesFile = "~/.config/git/ignore";
        pager = "delta";
      };

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

      merge = {
        conflictstyle = "diff3";
      };

      diff = {
        colorMoved = "default";
      };
    };
  };
}
