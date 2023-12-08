{
  pkgs,
  config,
  lib,
  ...
}: let
  language = [
    "$c"
    "$cmake"
    "$haskell"
    "$rust"
  ];
  vcs = [
    "$git_branch"
    "$git_commit"
    "$git_state"
    "$git_metrics"
    "$git_status"
  ];
in {
  programs.starship = {
    enable = true;
    settings = {
      directory.truncate_to_repo = false;
      format = lib.concatStrings (
        [
          "$username"
          "$hostname"
          "$localip"
          "$directory"
        ]
        ++ vcs
        ++ language
        ++ ["$all"]
      );
      hostname = {
        ssh_symbol = "";
        ## TODO: Ideally the “:” would appear whenever there’s _anything_
        ##       before the path, likethe local non-logged-in user.
        format = "[$ssh_symbol$hostname]($style):";
      };
      nix_shell = {
        format = "[$symbol$state]($style) ";
        heuristic = true;
        impure_msg = "!";
        pure_msg = "";
        # Just removes the trailing space (which would be better in the
        # `format`, IMO).
        symbol = "❄️";
        unknown_msg = "?";
      };
      ## TODO: Ideally the “@” would only appear when there’s a hostname, but
      ##       we need _something_ to separate the user from the path.
      ## TODO: Would like to use the ‘BUST IN SILHOUETTE’ emoji instead of the
      ##       actual username, but on macOS that codepoint gets Mac styling,
      ##       which doesn’t allow coloring (and setting this on remote Linux
      ##       machines doesn’t help because it still gets rendered by the
      ##       client-side Mac. Also, would be great if an ssh user could be
      ##       elided if it matches the local username.
      username.format = "[$user]($style)@";
    };
  };
}
