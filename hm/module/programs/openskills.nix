# Home-manager module for [openskills] universal skills loader.
# Provides cross-agent skill synchronization via AGENTS.md.
#
# [openskills]: packages/openskills/package.nix
#
# Usage:
#
#   imports = [ ../hm/module/programs/openskills.nix ];
#   programs.openskills = {
#     enable = true;
#     package = pkgs.llm-agents.openskills;
#   };
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.openskills;
in {
  options.programs.openskills = {
    enable = lib.mkEnableOption "openskills universal skills loader";

    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The openskills package. Set this to pkgs.llm-agents.openskills
        (from the llm-agents.nix overlay).
      '';
      example = lib.literalExpression "pkgs.llm-agents.openskills";
    };

    skillSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["obra/superpowers" "./local-skill"];
      description = ''
        Skills to install via `openskills install` during activation.
        Can be GitHub repos (user/repo), local paths, or marketplace names.
      '';
    };

    globalInstall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to install skills globally (--global flag).
        When false, skills are installed to the current directory.
      '';
    };

    universalFormat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to use universal format (--universal flag).
        Enables compatibility across all supported agents.
      '';
    };

    autoSync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run `openskills sync` on activation to update AGENTS.md
        with available skills.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    # Install configured skills on activation
    home.activation.openskillsInstall =
      lib.mkIf (cfg.skillSources != [])
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${cfg.package}/bin:$PATH"
        ${lib.concatMapStringsSep "\n" (src: ''
            $DRY_RUN_CMD openskills install ${lib.escapeShellArg src} \
              ${lib.optionalString cfg.globalInstall "--global"} \
              ${lib.optionalString cfg.universalFormat "--universal"} \
              || true
          '')
          cfg.skillSources}
      '');

    # Sync AGENTS.md on activation
    home.activation.openskillsSync =
      lib.mkIf cfg.autoSync
      (lib.hm.dag.entryAfter ["writeBoundary" "openskillsInstall"] ''
        export PATH="${cfg.package}/bin:$PATH"
        $DRY_RUN_CMD openskills sync || true
      '');
  };
}
