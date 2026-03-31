# Shared Ollama model definitions — single source of truth.
#
# Each model is an attrset with: id, name, context, output.
# Access by friendly key:
#   models.qwen3-coder-30b.id   → "qwen3-coder:30b"
#
# For a flat list (e.g. ollama loadModels):
#   builtins.attrValues models
let
  models = {
    qwen3-coder-30b = {
      id = "qwen3-coder:30b";
      name = "Qwen3 Coder 30B";
      context = 131072; # 128K; cap below native 256K for local RAM comfort
      output = 32768;
    };
    qwen3-30b = {
      id = "qwen3:30b";
      name = "Qwen3 30B Instruct";
      context = 131072;
      output = 32768;
    };
  };
in
  models
