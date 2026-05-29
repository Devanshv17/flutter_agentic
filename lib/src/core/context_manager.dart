import 'message.dart';

/// Manages conversation history to stay within a model's context window.
///
/// When history grows too large, old messages are pruned while always
/// preserving the system message (persona) and the most recent exchanges.
///
/// Token counting is approximate (4 chars ≈ 1 token). For exact counts,
/// use a tokenizer library or set [maxMessages] instead of [maxTokens].
///
/// ```dart
/// final manager = ContextManager(maxTokens: 4000);
/// final trimmed = manager.fit(messages);
/// ```
class ContextManager {
  /// Maximum approximate token count for the conversation.
  /// Null means no token limit.
  final int? maxTokens;

  /// Maximum number of messages to keep (excluding system message).
  /// Null means no message count limit.
  final int? maxMessages;

  const ContextManager({
    this.maxTokens,
    this.maxMessages,
  }) : assert(
          maxTokens != null || maxMessages != null,
          'Provide at least one of maxTokens or maxMessages.',
        );

  // ─── Preset factories ────────────────────────────────────────────────────

  /// ~4k tokens — small local models (Gemma 270M, SmolLM 135M).
  static ContextManager get small =>
      const ContextManager(maxTokens: 3500, maxMessages: 20);

  /// ~8k tokens — mid-size models (Gemma 2B, Phi-4 Mini).
  static ContextManager get medium =>
      const ContextManager(maxTokens: 7500, maxMessages: 40);

  /// ~32k tokens — large cloud models (GPT-4o-mini, Gemini Flash).
  static ContextManager get large =>
      const ContextManager(maxTokens: 30000, maxMessages: 100);

  /// ~128k tokens — frontier models (GPT-4o, Gemini Pro, Claude Sonnet).
  static ContextManager get xlarge =>
      const ContextManager(maxTokens: 120000, maxMessages: 500);

  /// Returns the appropriate [ContextManager] preset for a model ID from the
  /// [ModelRegistry].  Falls back to [large] for unknown models.
  ///
  /// ```dart
  /// final mgr = ContextManager.forModel('gemini-2.0-flash');
  /// ```
  static ContextManager forModel(String modelId) {
    // Lazy import via top-level map to avoid circular dependency.
    const knownContexts = {
      // Local / tiny
      'smollm-135m': 2048,
      'function-gemma-270m': 4096,
      'qwen3-0.6b': 4096,
      'gemma-3-1b-it': 8192,
      'gemma-3n-e2b-it': 8192,
      'gemma-3n-e4b-it': 8192,
      'phi-4-mini': 16384,
      // Cloud
      'mistral-7b': 32768,
      'llama-3.2-1b': 131072,
      'llama-3.2-3b': 131072,
      'gpt-4o-mini': 128000,
      'gpt-4o': 128000,
      'gpt-4.1': 1047576,
      'gpt-4.1-mini': 1047576,
      'o3-mini': 200000,
      'claude-haiku-4-5': 200000,
      'claude-sonnet-4-5': 200000,
      'claude-opus-4-5': 200000,
      'gemini-1.5-flash': 1048576,
      'gemini-1.5-pro': 2097152,
      'gemini-2.0-flash': 1048576,
      'gemini-2.0-flash-lite': 1048576,
      'gemini-2.5-flash': 1048576,
      'gemini-2.5-flash-lite': 1048576,
      'gemini-2.5-pro': 1048576,
    };
    final ctx = knownContexts[modelId.toLowerCase()];
    if (ctx == null || ctx >= 100000) return xlarge;
    if (ctx >= 30000) return large;
    if (ctx >= 7000) return medium;
    return small;
  }

  /// Trims [messages] to fit within limits.
  ///
  /// Always keeps the first system message.
  /// Removes oldest non-system messages until within limits.
  /// Preserves complete request/response pairs when possible.
  List<Message> fit(List<Message> messages) {
    if (messages.isEmpty) return messages;

    // Separate system message (always kept) from the rest.
    final systemMsg =
        messages.where((m) => m.role == MessageRole.system).firstOrNull;
    var history =
        messages.where((m) => m.role != MessageRole.system).toList();

    // Apply message count limit first (cheaper to check).
    if (maxMessages != null && history.length > maxMessages!) {
      history = history.sublist(history.length - maxMessages!);
    }

    // Apply token limit.
    if (maxTokens != null) {
      final systemTokens =
          systemMsg != null ? _approxTokens(systemMsg.content) : 0;
      int budget = maxTokens! - systemTokens;

      // Walk from the END (keep newest) and accumulate until budget runs out.
      final kept = <Message>[];
      for (int i = history.length - 1; i >= 0; i--) {
        final tokens = _approxTokens(history[i].content);
        if (budget - tokens < 0) break;
        budget -= tokens;
        kept.insert(0, history[i]);
      }
      history = kept;
    }

    return [
      if (systemMsg != null) systemMsg,
      ...history,
    ];
  }

  /// Approximate token count: ~4 characters per token (rough estimate).
  int _approxTokens(String text) => (text.length / 4).ceil();

  /// Returns the approximate token count for a list of messages.
  int approximateTokenCount(List<Message> messages) =>
      messages.fold(0, (sum, m) => sum + _approxTokens(m.content));
}

/// Pre-configured context managers for common model sizes.
extension ContextManagerPresets on ContextManager {
  /// ~4k tokens — small local models (Gemma 270M, SmolLM 135M).
  static ContextManager get small =>
      const ContextManager(maxTokens: 3500, maxMessages: 20);

  /// ~8k tokens — mid-size models (Gemma 2B, Phi-4 Mini).
  static ContextManager get medium =>
      const ContextManager(maxTokens: 7500, maxMessages: 40);

  /// ~32k tokens — large cloud models (GPT-4o-mini, Gemini Flash).
  static ContextManager get large =>
      const ContextManager(maxTokens: 30000, maxMessages: 100);

  /// ~128k tokens — frontier models (GPT-4o, Gemini Pro, Claude Sonnet).
  static ContextManager get xlarge =>
      const ContextManager(maxTokens: 120000, maxMessages: 500);
}
