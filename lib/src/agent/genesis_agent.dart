import '../core/agent_response.dart';
import '../core/agent_step.dart';
import '../core/message.dart';
import '../executor/react_executor.dart';
import '../memory/in_memory_store.dart';
import '../memory/memory_store.dart';
import '../providers/llm_provider.dart';
import '../tools/genesis_tool.dart';

/// The main entry point for using Genesis AI.
///
/// Create an agent, give it a system prompt, tools, and a memory store,
/// then call [chat] or [chatStream] to interact with it.
///
/// Example:
/// ```dart
/// final agent = GenesisAgent(
///   provider: GeminiProvider(apiKey: 'YOUR_KEY'),
///   systemPrompt: 'You are a helpful assistant.',
///   tools: [weatherTool],
/// );
///
/// final response = await agent.chat('What is the weather in Mumbai?');
/// print(response);
/// ```
class GenesisAgent {
  final LlmProvider provider;
  final String systemPrompt;
  final List<GenesisTool> tools;
  final MemoryStore memory;
  final String sessionId;
  final int maxIterations;

  late final ReActExecutor _executor;

  GenesisAgent({
    required this.provider,
    this.systemPrompt = 'You are a helpful assistant.',
    this.tools = const [],
    MemoryStore? memory,
    this.sessionId = 'default',
    this.maxIterations = 8,
  })  : memory = memory ?? InMemoryStore(),
        _executor = ReActExecutor(
          provider: provider,
          tools: tools,
          maxIterations: maxIterations,
        );

  // ─── chat ───────────────────────────────────────────────────────────────────

  /// Send a message and get a complete [AgentResponse] back.
  ///
  /// [onStep] fires for every ReAct step (tool call, result, etc.)
  /// so you can update the UI in real time.
  Future<AgentResponse> chat(
    String userMessage, {
    void Function(AgentStep step)? onStep,
  }) async {
    final history = await _buildHistory(userMessage);
    final response = await _executor.run(messages: history, onStep: onStep);
    await _persistResponse(userMessage, response);
    return response;
  }

  /// Stream plain text tokens for a simple (no-tool) conversation turn.
  ///
  /// For tool-calling use [chat] instead — tool calls can't be streamed.
  Stream<String> chatStream(String userMessage) async* {
    final history = await _buildHistory(userMessage);
    String fullResponse = '';
    await for (final token in provider.stream(messages: history)) {
      fullResponse += token;
      yield token;
    }
    // Persist after stream completes
    await memory.append(sessionId, Message.user(userMessage));
    await memory.append(sessionId, Message.assistant(fullResponse));
  }

  // ─── history management ─────────────────────────────────────────────────────

  /// Returns the full conversation history for this session.
  Future<List<Message>> getHistory() => memory.load(sessionId);

  /// Clears the conversation history for this session.
  Future<void> clearHistory() => memory.clear(sessionId);

  // ─── internals ──────────────────────────────────────────────────────────────

  Future<List<Message>> _buildHistory(String userMessage) async {
    final persisted = await memory.load(sessionId);
    return [
      Message.system(systemPrompt),
      ...persisted,
      Message.user(userMessage),
    ];
  }

  Future<void> _persistResponse(
      String userMessage, AgentResponse response) async {
    await memory.append(sessionId, Message.user(userMessage));
    if (response is TextAgentResponse) {
      await memory.append(sessionId, Message.assistant(response.text));
    }
  }
}
