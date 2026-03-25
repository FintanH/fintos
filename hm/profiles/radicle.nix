{
  lib,
  ...
}: {
  # Restart radicle-node when configuration changes
  home.activation.restartRadicleNode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if $DRY_RUN_CMD systemctl --user is-active --quiet radicle-node.service; then
      $DRY_RUN_CMD systemctl --user restart radicle-node.service
    fi
  '';
}
