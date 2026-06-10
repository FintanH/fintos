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
    dlog = ["log" "-r"];
    mergiraf = ["resolve" "--tool" "mergiraf"];
    l = ["log" "-r" "(trunk()..@):: | (trunk()..@)-"];
    fresh = ["new" "trunk()"];
    tug = [
      "bookmark"
      "move"
      "--from"
      "closest_bookmark(@)"
      "--to"
      "closest_pushable(@)"
    ];
    rpatch = ["util" "exec" "--" "bash" "-c" "" "jj bookmark create patches/$1 --to @-" "" ""];
  };

  revset-aliases = {
    "closest_bookmark(to)" = "heads(::to & bookmarks())";
    "closest_pushable(to)" = "heads(::to & mutable() & ~description(exact:\"\") & (~empty() | merges()))";
    "rad_patches()" = "remote_bookmarks('patches')";
    "desc(x)" = "description(x)";
    "pending()" = ".. ~ ::tags() ~ ::remote_bookmarks() ~ @ ~ private()";
    "private()" = "description(glob:'wip:*') | description(glob:'private:*') |\ndescription(glob:'WIP:*') | description(glob:'PRIVATE:*') |\n    conflicts() | (empty() ~ merges()) | description('substring-i:\"DO NOT MAIL\"')\n";
    # TODO(finto): use user.name variable
    "user()" = "user(\"fintan.halpenny@gmail.com\")";
    "user(x)" = "author(x) | committer(x)";
  };
in {
  programs.jujutsu = {
    enable = true;
    settings = {
      inherit user aliases revset-aliases;

      ui = {
        # Use Difftastic by default
        diff-formatter = ["difft" "--color=always" "$left" "$right"];
        editor = "${config.programs.emacs.finalPackage}/bin/emacs";
      };
      templates = {
        draft_commit_description = ''
          concat(
            builtin_draft_commit_description,
              "\nJJ: ignore-rest\n",
                diff.git(),
          )
        '';
      };
    };
  };
}
