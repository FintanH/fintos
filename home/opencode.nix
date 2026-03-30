{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  # List of skills to symlink from ~/Developer/AgentSkills/ into opencode.
  # - name:     the skill name opencode will see (and the subdir under AgentSkills
  #             if `location` is omitted)
  # - location: override when the repo directory name differs from `name`
  skills = [
    {name = "sans-io";}
  ];
  plugins = [
    {
      name = "superpowers.js";
      location = "obra/superpowers/.opencode/plugins/superpowers.js";
    }
  ];

  # ── Skill symlinks ────────────────────────────────────────────────────────────
  # Each entry symlinks a locally-cloned skill repo into opencode's skills dir.
  # Update a skill: cd ~/Developer/AgentSkills/<name> && git pull
  # Add/remove a skill: edit this list and run nixos-rebuild switch.
  #
  # TODO: once you've settled on keepers, consider migrating them to flake
  # inputs for proper pinning and multi-machine reproducibility.
  mkSkill = {
    name,
    location ? name,
  }: {
    ".config/opencode/skills/${name}".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Developer/AgentSkills/${location}";
  };
  mkPlugin = {
    name,
    location ? name,
  }: {
    ".config/opencode/plugins/${name}".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Developer/AgentSkills/${location}";
  };

  trailofbitsSkills = map (skill: "${config.home.homeDirectory}/Developer/AgentSkills/trailofbits/skills/plugins/${skill}/skills") [
    "zeroize-audit"
    "constant-time-analysis"
    "differential-review"
    "sharp-edges"
    "property-based-testing"
    "static-analysis"
    "variant-analysis"
    "fp-check"
  ];
  superpowersSkills = [
    "${config.home.homeDirectory}/Developer/AgentSkills/superpowers/skills"
  ];
  cekBase = "${config.home.homeDirectory}/Developer/AgentSkills/context-engineering-kit/plugins";
  cekSkills = map (plugin: "${cekBase}/${plugin}/skills") [
    "sdd"
    "reflexion"
    "code-review"
    "sadd"
    "tdd"
    "ddd"
    "kaizen"
  ];

  ollamaModels = builtins.listToAttrs (map (m: {
    name = m.id;
    value = {
      name = m.name;
      limit = {
        context = m.context;
        output = m.output;
      };
    };
  }) (builtins.attrValues (import ../agent/models.nix)));
in {
  options.opencode = {
    anthropicKeyFile = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.anthropic_api_key.path;
      description = "Path to a file containing the Anthropic API key.";
    };
    geminiKeyFile = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.gemini_api_key.path;
      description = "Path to a file containing the Gemini API key.";
    };
  };

  config = {
    home.file = lib.mkMerge ((map mkSkill skills) ++ (map mkPlugin plugins));
    programs.opencode = {
      enable = true;
      package = inputs.opencode.packages.${pkgs.system}.default;

      settings.skills = {
        paths = trailofbitsSkills ++ superpowersSkills ++ cekSkills;
      };

      # ── Global rules ─────────────────────────────────────────────────────────
      # Persistent instructions injected into every session.
      rules = builtins.readFile ../opencode/rules.md;

      settings = {
        model = "anthropic/claude-opus-4-20250514";
        small_model = "anthropic/claude-haiku-4-5-20251001";

        # ── Providers ──────────────────────────────────────────────────────────
        provider = {
          anthropic.options = {
            apiKey = "{file:${config.opencode.anthropicKeyFile}}";
            timeout = 600000;
            setCacheKey = true;
          };

          google.options = {
            apiKey = "{file:${config.opencode.geminiKeyFile}}";
          };

          ollama = {
            npm = "@ai-sdk/openai-compatible";
            name = "Ollama (local)";
            options.baseURL = "http://localhost:11434/v1";
            models = ollamaModels;
          };
        };

        # ── Permissions ────────────────────────────────────────────────────────
        permission = {
          bash = "allow";
          write = "allow";
          edit = "allow";
        };

        # ── File watcher ───────────────────────────────────────────────────────
        watcher.ignore = [
          "result"
          "result-*"
          ".git/**"
          "node_modules/**"
          "dist/**"
          "build/**"
          "target/**" # Rust/Cargo — can be many GB
          "**/__pycache__/**"
          "**/*.pyc"
        ];

        # ── Agents ─────────────────────────────────────────────────────────────
        agent = {
          nix-specialist = import ../opencode/agent/nix-specialist.nix;
          rust-refactorer = import ../opencode/agent/rust-refactorer.nix;
          reviewer = import ../opencode/agent/reviewer.nix;
        };

        # ── Commands ───────────────────────────────────────────────────────────
        command = {
          review = import ../opencode/command/review.nix;
        };

        share = "manual";
      };
    };
  };
}
