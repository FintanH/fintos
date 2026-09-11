# Home-manager module that declaratively manages ~/.pi/agent/.
# Import this in a home.nix or profile alongside other module imports.
#
# Minimal usage:
#
#   imports = [ ./modules/home-manager/programs/pi.nix ];
#   programs.pi.enable = true;
#
# Pi packages can be managed two ways:
#
#   # Nix derivations (peer-deps-only packages, fully declarative)
#   programs.pi.packages = [ pkgs.piPackages.plan-mode ];
#
#   # Pi-managed sources (packages with runtime deps, git repos)
#   programs.pi.packageSources = [
#     "npm:pi-fetch"
#     "git:github.com/can1357/oh-my-pi"
#   ];
#
# Agents (subagent definitions):
#
#   programs.pi.agents = {
#     scout = {
#       description = "Fast codebase recon";
#       model = "claude-haiku-4-5";
#       tools = [ "read" "bash" "grep" ];
#       systemPrompt = "You are a scout...";
#     };
#   };
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi;

  # Agent submodule type
  agentType = lib.types.submodule {
    options = {
      description = lib.mkOption {
        type = lib.types.str;
        description = "Short description of the agent's purpose.";
      };
      model = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "claude-haiku-4-5";
        description = ''
          Model for this agent. When null, inherits the default model
          from programs.pi.defaultModel.
        '';
      };
      tools = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = ["read" "bash" "grep"];
        description = ''
          Tools available to this agent. null = all tools (default),
          explicit list restricts to those tools only.
        '';
      };
      systemPrompt = lib.mkOption {
        type = lib.types.lines;
        description = "System prompt (markdown body of the agent file).";
      };
    };
  };

  # Generate a pi agent markdown file from a name + agent attrset.
  # Format: YAML frontmatter (---) followed by the system prompt body.
  mkAgentFile = name: agent: let
    frontmatter =
      "name: ${name}\n"
      + "description: ${agent.description}\n"
      + (lib.optionalString (agent.model != null) "model: ${agent.model}\n")
      + (lib.optionalString (agent.tools != null) "tools: ${lib.concatStringsSep ", " agent.tools}\n");
  in
    "---\n" + frontmatter + "---\n\n" + agent.systemPrompt + "\n";

  # home.file entries for agents
  agentFiles =
    lib.mapAttrs' (name: agent: {
      name = ".pi/agent/agents/${name}.md";
      value.text = mkAgentFile name agent;
    })
    cfg.agents;

  # Nix packages become local path references; source strings pass through.
  allPackages =
    (map toString cfg.packages)
    ++ cfg.packageSources;

  # Whether any packageSources use npm: (requires writable npm prefix on NixOS).
  hasNpmSources = lib.any (s: lib.hasPrefix "npm:" s) cfg.packageSources;

  # Build settings.json, merging provider/model, packages, and extraSettings.
  settingsJson =
    {
      provider = cfg.provider;
      model = cfg.defaultModel;
    }
    // lib.optionalAttrs (allPackages != []) {
      packages = allPackages;
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

    apiKeyFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = lib.literalExpression ''
        {
          OPENROUTER_API_KEY = "/run/secrets/openrouter_api_key";
        }
      '';
      description = ''
        Map of environment-variable name to a file path containing that
        provider's API key. Each entry is exported at shell login (if the
        file is readable), in addition to `apiKeyFile` (which exports
        ANTHROPIC_API_KEY). Reference these vars from models.json/custom
        providers as "$VAR_NAME".
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

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      example = lib.literalExpression "[ pkgs.piPackages.plan-mode ]";
      description = ''
        Pi extension packages as Nix derivations. Each is a directory
        with a package.json and pi manifest. Referenced as Nix store
        paths in settings.json — fully declarative, reproducible,
        and rollbackable.

        Use this for packages that have only peerDependencies (which
        pi provides at runtime). See overlays/pi-packages.nix.
      '';
    };

    packageSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [
        "npm:pi-fetch"
        "git:github.com/can1357/oh-my-pi"
      ];
      description = ''
        Pi package sources that pi manages itself (npm: and git:
        specifiers). Use this for packages that have runtime
        dependencies requiring npm install, or complex git repos.

        These are written to settings.json and pi resolves them at
        startup. Less pure than `packages` but necessary for packages
        that cannot be trivially built as Nix derivations.
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

    customProviders = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      example = lib.literalExpression ''
        {
          providers.ollama = {
            baseUrl = "http://localhost:11434/v1";
            api = "openai-completions";
            apiKey = "ollama";
            models = [
              { id = "llama3.1:8b"; }
            ];
          };
        }
      '';
      description = ''
        Custom provider definitions written to ~/.pi/agent/models.json.
        Used for Ollama, vLLM, LM Studio, or any OpenAI-compatible
        provider.  See pi docs/models.md for the full schema.
      '';
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf agentType;
      default = {};
      example = lib.literalExpression ''
        {
          scout = {
            description = "Fast codebase recon";
            model = "claude-haiku-4-5";
            tools = [ "read" "bash" "grep" ];
            systemPrompt = "You are a scout...";
          };
          implementer = {
            description = "Implements code tasks autonomously";
            systemPrompt = "You are an implementation agent...";
          };
        }
      '';
      description = ''
        Named agent definitions for pi's subagent tool.
        Each agent becomes a markdown file in ~/.pi/agent/agents/<name>.md
        with YAML frontmatter (name, description, model, tools) and
        the system prompt as the markdown body.

        When model is null, the agent inherits programs.pi.defaultModel.
        When tools is null, the agent has access to all tools.
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
      agentFiles
      // stableSkillLinks
      // devSkillLinks
      // {
        ".pi/agent/settings.json".text = builtins.toJSON settingsJson;
      }
      // lib.optionalAttrs (cfg.customProviders != null) {
        ".pi/agent/models.json".text = builtins.toJSON cfg.customProviders;
      }
      // lib.optionalAttrs (cfg.agentsMd != "") {
        ".pi/agent/AGENTS.md".text = cfg.agentsMd;
      }
      // lib.optionalAttrs hasNpmSources {
        # On NixOS, npm's global prefix defaults to the read-only Nix store.
        # Redirect it to a writable location when packageSources use npm:.
        ".npmrc".text = ''
          prefix=''${HOME}/.npm-global
        '';
      };

    home.sessionPath = lib.mkIf hasNpmSources ["$HOME/.npm-global/bin"];

    # Export provider API keys from their secret files into the shell.
    # pi reads $ANTHROPIC_API_KEY / $OPENROUTER_API_KEY etc. natively;
    # we never put a key in settings.json or models.json.
    programs.zsh.initContent = let
      allApiKeyFiles =
        (lib.optionalAttrs (cfg.apiKeyFile != null) {
          ANTHROPIC_API_KEY = cfg.apiKeyFile;
        })
        // cfg.apiKeyFiles;
      exportLine = var: path: ''
        if [ -r "${path}" ]; then
          export ${var}="$(cat ${path})"
        fi
      '';
    in
      lib.mkIf (allApiKeyFiles != {})
      (lib.concatStringsSep "\n" (lib.mapAttrsToList exportLine allApiKeyFiles));
  };
}
