# Scoped home directory for microvms.
#
# Creates a bind mount assembly at ~/.vm-home containing only
# safe paths, excluding sensitive directories like ~/.ssh, ~/.gnupg, etc.
#
# Uses systemd.mounts instead of fileSystems for proper ordering:
# - Mounts complete before microvm@.service starts virtiofsd
# - Handles missing source paths gracefully with ConditionPathExists
# - Correctly bind-mounts files (not just directories)
{config, lib, ...}: let
  user = "fintohaps";
  vmHome = "/home/${user}/.vm-home";
  realHome = "/home/${user}";

  # Share specifications: src, dst, ro (read-only), required, isFile
  #
  # NOTE: do not share files and directories that are already managed by
  # home-manager, e.g. `.config/git`.
  shares = [
    {
      src = "Developer";
      ro = false;
      required = true;
    }
    {
      src = ".config/jj";
      ro = true;
      required = false;
    }
    {
      src = ".config/nix";
      ro = true;
      required = false;
    }
    {
      src = ".jj";
      ro = false;
      required = false;
    }
    {
      src = ".emacs.d";
      ro = false;
      required = false;
    }
    {
      src = ".local/share/zsh";
      ro = false;
      required = false;
    }
    {
      src = ".gitignore";
      ro = true;
      required = false;
      isFile = true;
    }
  ];

  # Generate tmpfiles rule for mount point
  mkMountPointRule = share:
    if share.isFile or false
    then "f ${vmHome}/${share.src} 0644 ${user} users -"
    else "d ${vmHome}/${share.src} 0755 ${user} users -";

  # Generate parent directory rules (e.g., .config for .config/git)
  mkParentDirRules = share: let
    parts = lib.splitString "/" share.src;
    parentParts = lib.init parts;
  in
    if parentParts == []
    then []
    else
      map
      (i: "d ${vmHome}/${lib.concatStringsSep "/" (lib.sublist 0 i parentParts)} 0755 ${user} users -")
      (lib.range 1 (lib.length parentParts));

  # Generate systemd mount unit
  mkMount = share: {
    what = "${realHome}/${share.src}";
    where = "${vmHome}/${share.src}";
    type = "none";
    options =
      "bind"
      + (lib.optionalString share.ro ",ro")
      + (lib.optionalString (!(share.required)) ",nofail");
    wantedBy = ["vm-home-mounts.target"];
    before = ["microvm@.service"];
    after = ["systemd-tmpfiles-setup.service"];
    requires = ["systemd-tmpfiles-setup.service"];
    unitConfig =
      {
        RequiresMountsFor = "${realHome} ${vmHome}";
      }
      // (lib.optionalAttrs (!(share.required)) {
        ConditionPathExists = "${realHome}/${share.src}";
      });
  };
in {
  # Target that groups all VM home mounts; microvm service waits for this
  systemd.targets.vm-home-mounts = {
    description = "VM Home Directory Bind Mounts";
    wantedBy = ["local-fs.target"];
    before = ["microvm@.service"];
  };

  # Create mount point directories and files
  systemd.tmpfiles.rules =
    ["d ${vmHome} 0755 ${user} users -"]
    ++ lib.flatten (map mkParentDirRules shares)
    ++ map mkMountPointRule shares;

  # Bind mounts with proper ordering
  systemd.mounts = map mkMount shares;
}
