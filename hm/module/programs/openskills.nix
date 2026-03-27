# Home-manager module for [openskills] universal skills loader.
# Provides cross-agent skill synchronization via AGENTS.md.
#
# [openskills]: https://github.com/numman-ali/openskills
#
# Usage:
#
#   imports = [ ../hm/module/programs/openskills.nix ];
#   programs.openskills = {
#     enable = true;
#     package = pkgs.llm-agents.openskills;
#     remoteSkills = [
#       "obra/superpowers"
#       { source = "trailofbits/skills"; ref = "main"; }
#     ];
#   };
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.openskills;

  # Submodule for remote skills with optional pinning
  remoteSkillType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        example = "trailofbits/skills";
        description = "GitHub user/repo or marketplace name.";
      };
      ref = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "v1.0.0";
        description = "Git ref to pin (tag, branch, commit). Reserved for future use.";
      };
    };
  };

  # Extract source string from either a plain string or a submodule
  getSource = skill:
    if builtins.isString skill
    then skill
    else skill.source;
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

    remoteSkills = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str remoteSkillType);
      default = [];
      example = lib.literalExpression ''
        [
          "obra/superpowers"
          { source = "trailofbits/skills"; ref = "main"; }
        ]
      '';
      description = ''
        Remote skills to install via `openskills install` during activation.
        Can be GitHub repos (user/repo) or marketplace names.
        Use the submodule form to specify a git ref (reserved for future pinning support).
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
      lib.mkIf (cfg.remoteSkills != [])
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${cfg.package}/bin:$PATH"
        ${lib.concatMapStringsSep "\n" (skill: let
            src = getSource skill;
          in ''
            echo "Installing skill: ${src}"
            $DRY_RUN_CMD openskills install ${lib.escapeShellArg src} \
              ${lib.optionalString cfg.globalInstall "--global"} \
              ${lib.optionalString cfg.universalFormat "--universal"} \
              || echo "Warning: Failed to install ${src}" >&2
          '')
          cfg.remoteSkills}
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
