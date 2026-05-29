import 'dart:convert';

/// Represents one step the agent took during a ReAct loop.
/// Useful for showing "thinking..." and "calling tool..." states in the UI.
sealed class AgentStep {
  const AgentStep();
}

/// The agent is deciding what to do next.
class ThinkingStep extends AgentStep {
  final String thought;
  const ThinkingStep(this.thought);
}

/// The agent decided to call a tool.
class ToolCallStep extends AgentStep {
  final String toolName;
  final Map<String, dynamic> arguments;
  const ToolCallStep(this.toolName, this.arguments);

  String get displayText =>
      '$toolName(${arguments.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
}

/// The tool returned a result.
class ToolResultStep extends AgentStep {
  final String toolName;
  final Map<String, dynamic> result;
  const ToolResultStep(this.toolName, this.result);

  String get displayText => jsonEncode(result);
}

/// The agent produced a final text response.
class FinalResponseStep extends AgentStep {
  final String text;
  const FinalResponseStep(this.text);
}

/// An error occurred during a step.
class ErrorStep extends AgentStep {
  final String message;
  final Object? error;
  const ErrorStep(this.message, [this.error]);
}
