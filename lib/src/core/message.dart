/// Represents the role of a message in a conversation.
enum MessageRole { system, user, assistant, tool }

/// A single message in a conversation history.
class Message {
  final MessageRole role;
  final String content;

  /// Only set when role == tool. Identifies which tool produced this result.
  final String? toolName;

  const Message._({
    required this.role,
    required this.content,
    this.toolName,
  });

  factory Message.system(String content) =>
      Message._(role: MessageRole.system, content: content);

  factory Message.user(String content) =>
      Message._(role: MessageRole.user, content: content);

  factory Message.assistant(String content) =>
      Message._(role: MessageRole.assistant, content: content);

  factory Message.tool(String toolName, String content) => Message._(
        role: MessageRole.tool,
        content: content,
        toolName: toolName,
      );

  @override
  String toString() => '[${role.name}] $content';
}
