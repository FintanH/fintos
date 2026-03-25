# models.nix
# Shared Ollama model definitions. Import this wherever you need the list.
#
# In configuration.nix:
#   services.ollama.loadModels = map (m: m.id) (import ./models.nix);
#
# In opencode.nix:
#   let models = import ./models.nix; in ...
[
  {
    id = "qwen3-coder:30b";
    name = "Qwen3 Coder 30B";
    context = 131072; # 128K; cap below native 256K for local RAM comfort
    output = 32768;
  }
  {
    id = "qwen3:30b";
    name = "Qwen3 30B Instruct";
    context = 131072;
    output = 32768;
  }
]
