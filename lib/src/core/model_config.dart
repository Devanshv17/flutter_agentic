/// Configuration for a specific LLM model.
///
/// The SDK ships pre-configured entries for all major models so developers
/// never have to look up context limits, prompt formats, or capabilities.
///
/// Access via [ModelRegistry.get]:
/// ```dart
/// final config = ModelRegistry.get('gemini-2.0-flash');
/// print(config.contextWindow); // 1048576
/// ```
class ModelConfig {
  /// Display name of the model.
  final String name;

  /// Provider family.
  final ModelProvider provider;

  /// Maximum context window in tokens.
  final int contextWindow;

  /// Recommended token budget for output (if provider supports it).
  final int? maxOutputTokens;

  /// Whether this model supports native function / tool calling.
  final bool supportsToolCalling;

  /// Whether this model supports image inputs.
  final bool supportsVision;

  /// Whether this model supports audio inputs.
  final bool supportsAudio;

  /// Approximate cost per 1M input tokens in USD. Null = free / local.
  final double? inputCostPer1MTokens;

  /// Approximate cost per 1M output tokens in USD. Null = free / local.
  final double? outputCostPer1MTokens;

  /// Whether this model runs locally on-device.
  final bool isLocal;

  const ModelConfig({
    required this.name,
    required this.provider,
    required this.contextWindow,
    this.maxOutputTokens,
    this.supportsToolCalling = true,
    this.supportsVision = false,
    this.supportsAudio = false,
    this.inputCostPer1MTokens,
    this.outputCostPer1MTokens,
    this.isLocal = false,
  });
}

/// Which provider family a model belongs to.
enum ModelProvider { gemini, openai, anthropic, ollama, gemma, llama, unknown }

/// Registry of pre-configured model settings.
///
/// Supports all major cloud models and common local models.
/// Unknown models get a sensible fallback configuration.
class ModelRegistry {
  ModelRegistry._();

  static const Map<String, ModelConfig> _configs = {
    // ── Google Gemini ────────────────────────────────────────────────────────
    'gemini-2.0-flash': ModelConfig(
      name: 'Gemini 2.0 Flash',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 8192,
      supportsVision: true,
      supportsAudio: true,
      inputCostPer1MTokens: 0.10,
      outputCostPer1MTokens: 0.40,
    ),
    'gemini-2.0-flash-lite': ModelConfig(
      name: 'Gemini 2.0 Flash Lite',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 8192,
      supportsVision: true,
      inputCostPer1MTokens: 0.075,
      outputCostPer1MTokens: 0.30,
    ),
    'gemini-1.5-flash': ModelConfig(
      name: 'Gemini 1.5 Flash',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 8192,
      supportsVision: true,
      inputCostPer1MTokens: 0.075,
      outputCostPer1MTokens: 0.30,
    ),
    'gemini-1.5-pro': ModelConfig(
      name: 'Gemini 1.5 Pro',
      provider: ModelProvider.gemini,
      contextWindow: 2097152,
      maxOutputTokens: 8192,
      supportsVision: true,
      supportsAudio: true,
      inputCostPer1MTokens: 1.25,
      outputCostPer1MTokens: 5.00,
    ),
    'gemini-2.5-flash': ModelConfig(
      name: 'Gemini 2.5 Flash',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 65536,
      supportsVision: true,
      supportsAudio: true,
      inputCostPer1MTokens: 0.15,
      outputCostPer1MTokens: 0.60,
    ),
    'gemini-2.5-flash-lite': ModelConfig(
      name: 'Gemini 2.5 Flash Lite',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 65536,
      supportsVision: true,
      inputCostPer1MTokens: 0.10,
      outputCostPer1MTokens: 0.40,
    ),
    'gemini-2.5-pro': ModelConfig(
      name: 'Gemini 2.5 Pro',
      provider: ModelProvider.gemini,
      contextWindow: 1048576,
      maxOutputTokens: 65536,
      supportsVision: true,
      supportsAudio: true,
      inputCostPer1MTokens: 1.25,
      outputCostPer1MTokens: 10.00,
    ),

    // ── OpenAI ───────────────────────────────────────────────────────────────
    'gpt-4o': ModelConfig(
      name: 'GPT-4o',
      provider: ModelProvider.openai,
      contextWindow: 128000,
      maxOutputTokens: 16384,
      supportsVision: true,
      inputCostPer1MTokens: 2.50,
      outputCostPer1MTokens: 10.00,
    ),
    'gpt-4o-mini': ModelConfig(
      name: 'GPT-4o Mini',
      provider: ModelProvider.openai,
      contextWindow: 128000,
      maxOutputTokens: 16384,
      supportsVision: true,
      inputCostPer1MTokens: 0.15,
      outputCostPer1MTokens: 0.60,
    ),
    'gpt-4.1': ModelConfig(
      name: 'GPT-4.1',
      provider: ModelProvider.openai,
      contextWindow: 1047576,
      maxOutputTokens: 32768,
      supportsVision: true,
      inputCostPer1MTokens: 2.00,
      outputCostPer1MTokens: 8.00,
    ),
    'gpt-4.1-mini': ModelConfig(
      name: 'GPT-4.1 Mini',
      provider: ModelProvider.openai,
      contextWindow: 1047576,
      maxOutputTokens: 32768,
      supportsVision: true,
      inputCostPer1MTokens: 0.40,
      outputCostPer1MTokens: 1.60,
    ),
    'o3-mini': ModelConfig(
      name: 'o3-mini',
      provider: ModelProvider.openai,
      contextWindow: 200000,
      maxOutputTokens: 100000,
      inputCostPer1MTokens: 1.10,
      outputCostPer1MTokens: 4.40,
    ),

    // ── Anthropic Claude ─────────────────────────────────────────────────────
    'claude-opus-4-5': ModelConfig(
      name: 'Claude Opus 4.5',
      provider: ModelProvider.anthropic,
      contextWindow: 200000,
      maxOutputTokens: 32000,
      supportsVision: true,
      inputCostPer1MTokens: 15.00,
      outputCostPer1MTokens: 75.00,
    ),
    'claude-sonnet-4-5': ModelConfig(
      name: 'Claude Sonnet 4.5',
      provider: ModelProvider.anthropic,
      contextWindow: 200000,
      maxOutputTokens: 32000,
      supportsVision: true,
      inputCostPer1MTokens: 3.00,
      outputCostPer1MTokens: 15.00,
    ),
    'claude-haiku-4-5': ModelConfig(
      name: 'Claude Haiku 4.5',
      provider: ModelProvider.anthropic,
      contextWindow: 200000,
      maxOutputTokens: 8192,
      supportsVision: true,
      inputCostPer1MTokens: 0.80,
      outputCostPer1MTokens: 4.00,
    ),

    // ── Local — Gemma (via flutter_gemma) ────────────────────────────────────
    'gemma-3n-e2b-it': ModelConfig(
      name: 'Gemma 3n E2B (2B)',
      provider: ModelProvider.gemma,
      contextWindow: 8192,
      supportsVision: true,
      isLocal: true,
    ),
    'gemma-3n-e4b-it': ModelConfig(
      name: 'Gemma 3n E4B (4B)',
      provider: ModelProvider.gemma,
      contextWindow: 8192,
      supportsVision: true,
      isLocal: true,
    ),
    'gemma-3-1b-it': ModelConfig(
      name: 'Gemma 3 1B',
      provider: ModelProvider.gemma,
      contextWindow: 8192,
      isLocal: true,
    ),
    'phi-4-mini': ModelConfig(
      name: 'Phi-4 Mini',
      provider: ModelProvider.gemma,
      contextWindow: 16384,
      supportsToolCalling: false,
      isLocal: true,
    ),
    'qwen3-0.6b': ModelConfig(
      name: 'Qwen3 0.6B',
      provider: ModelProvider.gemma,
      contextWindow: 4096,
      isLocal: true,
    ),
    'smollm-135m': ModelConfig(
      name: 'SmolLM 135M',
      provider: ModelProvider.gemma,
      contextWindow: 2048,
      supportsToolCalling: false,
      isLocal: true,
    ),
    'function-gemma-270m': ModelConfig(
      name: 'FunctionGemma 270M',
      provider: ModelProvider.gemma,
      contextWindow: 4096,
      supportsToolCalling: true,
      isLocal: true,
    ),

    // ── Local — Llama / GGUF (via llamadart / llama_sdk) ─────────────────────
    'llama-3.2-3b': ModelConfig(
      name: 'Llama 3.2 3B',
      provider: ModelProvider.llama,
      contextWindow: 131072,
      supportsToolCalling: false,
      isLocal: true,
    ),
    'llama-3.2-1b': ModelConfig(
      name: 'Llama 3.2 1B',
      provider: ModelProvider.llama,
      contextWindow: 131072,
      supportsToolCalling: false,
      isLocal: true,
    ),
    'mistral-7b': ModelConfig(
      name: 'Mistral 7B',
      provider: ModelProvider.llama,
      contextWindow: 32768,
      supportsToolCalling: false,
      isLocal: true,
    ),
  };

  /// Fallback config for unknown models.
  static const ModelConfig _fallback = ModelConfig(
    name: 'Unknown Model',
    provider: ModelProvider.unknown,
    contextWindow: 8192,
  );

  /// Returns the config for [modelId], or a fallback if not found.
  static ModelConfig get(String modelId) =>
      _configs[modelId.toLowerCase()] ?? _fallback;

  /// Returns true if [modelId] is in the registry.
  static bool has(String modelId) =>
      _configs.containsKey(modelId.toLowerCase());

  /// Returns all registered model IDs.
  static List<String> get allIds => _configs.keys.toList();

  /// Returns all local model IDs.
  static List<String> get localModelIds =>
      _configs.entries.where((e) => e.value.isLocal).map((e) => e.key).toList();

  /// Returns all cloud model IDs.
  static List<String> get cloudModelIds => _configs.entries
      .where((e) => !e.value.isLocal)
      .map((e) => e.key)
      .toList();

  /// Returns all models for a given provider.
  static List<String> modelsFor(ModelProvider provider) => _configs.entries
      .where((e) => e.value.provider == provider)
      .map((e) => e.key)
      .toList();
}
