import '../providers/llm_provider.dart';
import 'genesis_logger.dart';
import 'model_config.dart';

/// Global configuration for the Genesis AI SDK.
///
/// Call [GenesisAI.init] once at app startup before creating any agents.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await GenesisAI.init(
///     providers: {
///       'gemini': GeminiProvider(apiKey: Env.geminiKey),
///       'openai': OpenAIProvider(apiKey: Env.openAiKey),
///     },
///     defaultProviderKey: 'gemini',
///     logLevel: LogLevel.info, // use LogLevel.none in production
///   );
///
///   runApp(const MyApp());
/// }
/// ```
class GenesisAI {
  GenesisAI._();

  static final Map<String, LlmProvider> _providers = {};
  static String? _defaultKey;
  static bool _initialized = false;

  /// Initialises the SDK with a map of named providers.
  ///
  /// [providers] — map of key → provider, e.g. `{'gemini': GeminiProvider(...)}`.
  /// [defaultProviderKey] — which key to use when no provider is specified.
  ///   Defaults to the first entry if omitted.
  /// [logLevel] — logging verbosity. Use [LogLevel.none] in production.
  static Future<void> init({
    required Map<String, LlmProvider> providers,
    String? defaultProviderKey,
    LogLevel logLevel = LogLevel.none,
  }) async {
    assert(providers.isNotEmpty, 'Provide at least one LlmProvider.');

    GenesisLogger.level = logLevel;
    _providers
      ..clear()
      ..addAll(providers);
    _defaultKey = defaultProviderKey ?? providers.keys.first;
    _initialized = true;

    GenesisLogger.info('GenesisAI', 'Initialized with providers: '
        '${providers.keys.join(', ')} | default: $_defaultKey');
  }

  /// Returns the provider registered under [key].
  ///
  /// Throws if [GenesisAI.init] has not been called or the key is unknown.
  static LlmProvider provider(String key) {
    _assertInitialized();
    final p = _providers[key];
    if (p == null) {
      throw GenesisAIException(
        'No provider registered under key "$key". '
        'Available: ${_providers.keys.join(', ')}',
      );
    }
    return p;
  }

  /// Returns the default provider (set via [defaultProviderKey] in [init]).
  static LlmProvider get defaultProvider {
    _assertInitialized();
    return _providers[_defaultKey]!;
  }

  /// Returns true if [GenesisAI.init] has been called.
  static bool get isInitialized => _initialized;

  /// Returns all registered provider keys.
  static List<String> get providerKeys => _providers.keys.toList();

  static void _assertInitialized() {
    if (!_initialized) {
      throw const GenesisAIException(
        'GenesisAI is not initialized. Call GenesisAI.init() at app startup.',
      );
    }
  }
}

/// Thrown when the SDK is misconfigured or used incorrectly.
class GenesisAIException implements Exception {
  final String message;
  const GenesisAIException(this.message);

  @override
  String toString() => 'GenesisAIException: $message';
}

/// Convenience accessor to [ModelRegistry].
/// `GenesisModels.get('gpt-4o-mini')` returns the config for GPT-4o Mini.
typedef GenesisModels = ModelRegistry;
