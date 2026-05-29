import 'builtins/calculator_tool.dart';
import 'builtins/datetime_tool.dart';
import 'builtins/http_tool.dart';
import 'builtins/mock_weather_tool.dart';
import 'genesis_tool.dart';

export 'builtins/http_tool.dart' show HttpTool;

/// Pre-built tools included with the Genesis AI SDK.
///
/// All tools are zero-config unless noted. Just add them to your agent:
///
/// ```dart
/// final agent = GenesisAgent(
///   provider: myProvider,
///   tools: [
///     GenesisTools.calculator,
///     GenesisTools.dateTime,
///     GenesisTools.httpRequest,
///     GenesisTools.mockWeather,  // swap for a real weather tool in production
///   ],
/// );
/// ```
abstract final class GenesisTools {
  /// Evaluates arithmetic expressions: +, -, *, /, ^, %, sqrt(), trig, log.
  ///
  /// No API key. Works offline. All platforms.
  static GenesisTool get calculator => calculatorTool;

  /// Returns the current date, time, day of week, and timezone info.
  ///
  /// No API key. Works offline. All platforms.
  static GenesisTool get dateTime => dateTimeTool;

  /// Makes HTTP GET / POST requests to any URL.
  ///
  /// No API key required. Requires network access.
  /// For domain-restricted usage: `HttpTool(allowedDomains: ['...'])`
  static GenesisTool get httpRequest => httpRequestTool;

  /// Returns mock weather data for testing and development.
  ///
  /// No API key. Works offline. **Not for production use.**
  /// Replace with a real provider from the `genesis_ai_tools` package.
  static GenesisTool get mockWeather => mockWeatherTool;

  /// All built-in tools as a list — useful for quick prototyping.
  ///
  /// ```dart
  /// tools: GenesisTools.all
  /// ```
  static List<GenesisTool> get all => [
        calculator,
        dateTime,
        httpRequest,
        mockWeather,
      ];
}
