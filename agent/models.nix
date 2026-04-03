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
  };
in
  models
