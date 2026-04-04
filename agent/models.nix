# Shared Ollama model definitions — single source of truth.
#
# Each model is an attrset with: id, name, context, output.
# Access by friendly key:
#   models.qwen3-coder-30b.id   → "qwen3-coder:30b"
#
# For a flat list (e.g. ollama loadModels):
#   builtins.attrValues models
#
# Pi-specific fields (reasoning, compat) are used by microvms/pi.nix
# to generate ~/.pi/agent/models.json.  Other consumers (opencode,
# configuration.nix) ignore them harmlessly.
let
  # Shared compat flags for local Qwen models served by Ollama.
  qwenCompat = {
    supportsDeveloperRole = false;
    supportsReasoningEffort = false;
    thinkingFormat = "qwen-chat-template";
  };

  # Shared compat flags for local Gemma 4 models served by Ollama.
  gemmaCompat = {
    supportsDeveloperRole = false;
    supportsReasoningEffort = false;
  };

  models = {
    qwen3-coder-30b = {
      id = "qwen3-coder:30b";
      name = "Qwen3 Coder 30B";
      context = 131072; # 128K; cap below native 256K for local RAM comfort
      output = 32768;
      reasoning = true;
      compat = qwenCompat;
    };
    qwen3-30b = {
      id = "qwen3:30b";
      name = "Qwen3 30B Instruct";
      context = 131072;
      output = 32768;
      reasoning = true;
      compat = qwenCompat;
    };
    gemma4-e4b = {
      id = "gemma4:e4b";
      name = "Gemma 4 E4B";
      context = 131072; # 128K native
      output = 32768;
      reasoning = true;
      compat = gemmaCompat;
    };
    gemma4-26b = {
      id = "gemma4:26b";
      name = "Gemma 4 26B MoE";
      context = 131072; # 128K; cap below native 256K for local RAM comfort
      output = 32768;
      reasoning = true;
      compat = gemmaCompat;
    };
  };
in
  models
