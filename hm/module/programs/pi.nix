# hm/module/programs/pi.nix
#
# Home-manager module that declaratively manages ~/.pi/agent/.
# Import this in a home.nix or profile alongside other hm/module imports.
#
# Minimal usage:
#
#   imports = [ ../hm/module/programs/pi.nix ];
#   programs.pi.enable = true;
#
# Full usage with all options: see option definitions below.
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi;

  # Build settings.json, merging provider/model with any extraSettings
  settingsJson =
    {
      provider = cfg.provider;
      model = cfg.defaultModel;
    }
    // lib.optionalAttrs (cfg.extraSettings != {}) cfg.extraSettings;

  # home.file entries for stable skills (Nix store paths, content-addressed)
  stableSkillLinks = lib.listToAttrs (map (skillDir: {
      name = ".pi/agent/skills/${baseNameOf (toString skillDir)}";
      value = {
        source = skillDir;
        recursive = true;
      };
    })
    cfg.stableSkillDirs);

  # home.file entries for dev skills (live symlinks into the virtiofs mount)
  devSkillLinks =
    lib.optionalAttrs (cfg.devSkillsMount != null)
    (lib.listToAttrs (map (name: {
        name = ".pi/agent/skills/${name}";
        value = {
          source =
            config.lib.file.mkOutOfStoreSymlink
            "${cfg.devSkillsMount}/${name}";
        };
      })
      cfg.devSkillNames));
in {
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent";

    provider = lib.mkOption {
      type = lib.types.str;
      default = "anthropic";
      description = "Default LLM provider (anthropic | openai | google | ollama …)";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-sonnet-4-5";
      description = "Default model. Overridable at runtime with /model or Ctrl+L.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/anthropic_api_key";
      description = ''
        Path to a file containing the provider API key.
        Read at shell login and exported as ANTHROPIC_API_KEY (or the
        appropriate var for the chosen provider). When null, pi uses
        whatever is already in the environment.
      '';
    };

    stableSkillDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      example = lib.literalExpression "[ ./agent/skills/nix-aware ]";
      description = ''
        Nix store paths, each a directory containing a SKILL.md.
        Content-addressed and rebuilt on nixos-rebuild.
        Promote a dev skill here once it is stable.
      '';
    };

    devSkillsMount = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/mnt/dev-skills";
      description = ''
        Mount point inside this system where ~/Developer/AgentSkills
        is exposed (e.g. via virtiofs in a microvm guest, or a bind
        mount on the host). When null, devSkillNames is ignored.
      '';
    };

    devSkillNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["my-draft-skill" "experiment"];
      description = ''
        Names of subdirectories under devSkillsMount to symlink into
        ~/.pi/agent/skills/. Edit these freely on the host without
        any Nix rebuild.
      '';
    };

    npmPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["npm:@mariozechner/pi-plan-mode"];
      description = ''
        Pi packages installed via `pi install` during home-manager
        activation. Idempotent. Land in ~/.pi/packages/ (writable
        state, not tracked by Nix).
      '';
    };

    agentsMd = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Content of ~/.pi/agent/AGENTS.md — global instructions
        injected at startup for every pi session.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      example = lib.literalExpression ''
        {
          thinking = "medium";
          skills = [
            "~/.claude/skills"
            "~/.agent/skills"
          ];
        }
      '';
      description = ''
        Additional key-value pairs merged into settings.json verbatim.

        Common fields:
        - thinking: "off" | "low" | "medium" | "high" — extended thinking level
        - skills: list of additional skill discovery paths (e.g., openskills directories)

        See pi docs for all supported fields.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The pi-coding-agent package. Set this to pkgs.llm-agents.pi
        (from the llm-agents.nix overlay) in your home config or microvms/pi.nix.
      '';
      example = lib.literalExpression "pkgs.llm-agents.pi";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    home.file =
      stableSkillLinks
      // devSkillLinks
      // {
        ".pi/agent/settings.json".text = builtins.toJSON settingsJson;
      }
      // lib.optionalAttrs (cfg.agentsMd != "") {
        ".pi/agent/AGENTS.md".text = cfg.agentsMd;
      };

    # Export API key from the secret file into the shell.
    # pi reads ANTHROPIC_API_KEY natively; we never put the key in settings.json.
    programs.zsh.initContent = lib.mkIf (cfg.apiKeyFile != null) ''
      if [ -r "${cfg.apiKeyFile}" ]; then
        export ANTHROPIC_API_KEY="$(cat ${cfg.apiKeyFile})"
      fi
    '';

    # Install npm-sourced pi packages on activation (idempotent).
    home.activation.piInstallPackages =
      lib.mkIf (cfg.npmPackages != [])
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${cfg.package}/bin:$PATH"
        ${lib.concatMapStringsSep "\n" (pkg: ''
            $DRY_RUN_CMD pi install ${lib.escapeShellArg pkg} || true
          '')
          cfg.npmPackages}
      '');
  };
}
