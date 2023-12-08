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
      logs = "log --show-signature";
      commits = "commit --trailer \"X-Clacks-Overhead: GNU Terry Pratchett\" -s -v";
      lg = "log --date=format:'%a %b %e, %Y' --pretty=format:'%C(yellow)%h%C(reset) %s %C(cyan)%cd%C(reset) %C(blue)%an%C(reset) %C(green)%d%C(reset)' --graph";
    };
  };
}
