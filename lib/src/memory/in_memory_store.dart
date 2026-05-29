import '../core/message.dart';
import 'memory_store.dart';

/// In-memory implementation of [MemoryStore].
/// History is lost when the app restarts. Good for testing and ephemeral sessions.
class InMemoryStore implements MemoryStore {
  final Map<String, List<Message>> _store = {};

  @override
  Future<List<Message>> load(String sessionId) async =>
      List.unmodifiable(_store[sessionId] ?? []);

  @override
  Future<void> append(String sessionId, Message message) async {
    _store.putIfAbsent(sessionId, () => []).add(message);
  }

  @override
  Future<void> save(String sessionId, List<Message> messages) async {
    _store[sessionId] = List.of(messages);
  }

  @override
  Future<void> clear(String sessionId) async {
    _store.remove(sessionId);
  }
}
