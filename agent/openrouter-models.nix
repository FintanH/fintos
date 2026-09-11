# Shared OpenRouter model definitions — single source of truth.
#
# Mirrors agent/models.nix.  Consumed by microvms/pi.nix to generate the
# `openrouter` provider block in ~/.pi/agent/models.json.
#
# Each entry:
#   id       OpenRouter model id (pi references it as openrouter/<id>)
#   name     Display name shown in /model
#   context  Context window (tokens)
#   output   Max output tokens (maxTokens); practical cap, tunable
#   reasoning  Whether the model supports extended thinking
#   input    Input modalities (["text"] or ["text" "image"])
#   cost     $/million tokens: input, output, cacheRead, cacheWrite
#   compat   Optional OpenAI-compat overrides (e.g. supportsReasoningEffort)
#
# Model ids and metadata verified against https://openrouter.ai/api/v1/models
# on 2026-09-11.
let
  # Models that accept text and image input.
  multimodal = ["text" "image"];
  textOnly = ["text"];

  # For models that do not accept the OpenAI `reasoning_effort` parameter.
  noReasoningEffort = {supportsReasoningEffort = false;};
in {
  # ── Frontier / planning ──────────────────────────────────────
  gpt-6-astra = {
    id = "openai/gpt-6-astra";
    name = "GPT-6 Astra";
    context = 1050000;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 10.0;
      output = 50.0;
      cacheRead = 1.0;
      cacheWrite = 12.5;
    };
  };
  gpt-5-3-codex = {
    id = "openai/gpt-5.3-codex";
    name = "GPT-5.3 Codex";
    context = 400000;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 1.75;
      output = 14.0;
      cacheRead = 0.175;
      cacheWrite = 0.0;
    };
  };
  claude-opus-5 = {
    id = "anthropic/claude-opus-5";
    name = "Claude Opus 5";
    context = 1000000;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 5.0;
      output = 25.0;
      cacheRead = 0.5;
      cacheWrite = 6.25;
    };
  };
  claude-sonnet-5 = {
    id = "anthropic/claude-sonnet-5";
    name = "Claude Sonnet 5";
    context = 1000000;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 2.0;
      output = 10.0;
      cacheRead = 0.2;
      cacheWrite = 2.5;
    };
  };
  claude-fable-5-1 = {
    id = "anthropic/claude-fable-5.1";
    name = "Claude Fable 5.1";
    context = 1000000;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 10.0;
      output = 50.0;
      cacheRead = 0.25;
      cacheWrite = 12.5;
    };
  };

  # ── Cheap task-runner (proprietary) ──────────────────────────
  claude-haiku-4-5 = {
    id = "anthropic/claude-haiku-4.5";
    name = "Claude Haiku 4.5";
    context = 200000;
    output = 64000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 1.0;
      output = 5.0;
      cacheRead = 0.1;
      cacheWrite = 1.25;
    };
    compat = noReasoningEffort;
  };

  # ── Open-weight (to evaluate) ────────────────────────────────
  kimi-k3 = {
    id = "moonshotai/kimi-k3";
    name = "Kimi K3";
    context = 1048576;
    output = 128000;
    reasoning = true;
    input = multimodal;
    cost = {
      input = 2.34;
      output = 11.7;
      cacheRead = 0.261;
      cacheWrite = 0.0;
    };
  };
  glm-5-3 = {
    id = "z-ai/glm-5.3";
    name = "GLM-5.3";
    context = 1310720;
    output = 128000;
    reasoning = true;
    input = textOnly;
    cost = {
      input = 1.4;
      output = 4.4;
      cacheRead = 0.26;
      cacheWrite = 0.0;
    };
  };
  deepseek-v4-pro = {
    id = "deepseek/deepseek-v4-pro";
    name = "DeepSeek V4 Pro";
    context = 1048576;
    output = 128000;
    reasoning = true;
    input = textOnly;
    cost = {
      input = 0.95526;
      output = 1.91052;
      cacheRead = 0.079605;
      cacheWrite = 0.0;
    };
  };
  qwen3-coder-flash = {
    id = "qwen/qwen3-coder-flash";
    name = "Qwen3 Coder Flash";
    context = 1000000;
    output = 65536;
    reasoning = false;
    input = textOnly;
    cost = {
      input = 0.195;
      output = 0.975;
      cacheRead = 0.039;
      cacheWrite = 0.0;
    };
    compat = noReasoningEffort;
  };
}
