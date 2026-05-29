import '../core/message.dart';

/// Abstract persistence layer for conversation history.
///
/// Implement this to add your own storage backend (Hive, SQLite, cloud, etc.).
abstract class MemoryStore {
  /// Returns the full conversation history for [sessionId].
  Future<List<Message>> load(String sessionId);

  /// Appends [message] to the history for [sessionId].
  Future<void> append(String sessionId, Message message);

  /// Replaces the entire history for [sessionId].
  Future<void> save(String sessionId, List<Message> messages);

  /// Clears all messages for [sessionId].
  Future<void> clear(String sessionId);
}
