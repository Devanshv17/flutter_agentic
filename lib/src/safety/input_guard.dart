/// Input validation and sanitisation for user messages before they reach
/// the LLM.  Drop-in: wrap any call with [InputGuard.validate].
///
/// The guard is intentionally conservative by default and fully customisable:
/// - block prompt-injection patterns (e.g. "ignore previous instructions")
/// - enforce per-message character length limits
/// - strip or reject control characters
/// - allow developers to add their own [InputRule]s
library;

/// A single validation rule applied to raw user input.
abstract class InputRule {
  const InputRule();

  /// Return `null` if the input is acceptable, or a human-readable reason
  /// string if it should be rejected.
  String? check(String input);
}

// ── Built-in rules ───────────────────────────────────────────────────────────

/// Rejects messages longer than [maxChars] characters.
class MaxLengthRule extends InputRule {
  final int maxChars;
  const MaxLengthRule({this.maxChars = 8000});

  @override
  String? check(String input) {
    if (input.length > maxChars) {
      return 'Message too long (${input.length} chars, max $maxChars).';
    }
    return null;
  }
}

/// Rejects messages that are empty or contain only whitespace.
class NonEmptyRule extends InputRule {
  const NonEmptyRule();

  @override
  String? check(String input) {
    if (input.trim().isEmpty) return 'Message must not be empty.';
    return null;
  }
}

/// Strips ASCII control characters (0x00–0x1F except tab/newline/CR).
/// Returns `null` — never blocks, just cleans.
class StripControlCharsRule extends InputRule {
  const StripControlCharsRule();

  @override
  String? check(String input) => null; // cleaning is done in sanitise()
}

/// Rejects well-known prompt-injection phrases.
///
/// The list covers the most common jailbreak openers. It is **not** an
/// exhaustive defence — treat it as a first-pass filter, not a complete
/// security boundary. Set [caseSensitive] to `true` for higher precision
/// with less false-positives.
class PromptInjectionRule extends InputRule {
  final bool caseSensitive;

  const PromptInjectionRule({this.caseSensitive = false});

  static const _patterns = [
    'ignore previous instructions',
    'ignore all previous',
    'disregard previous',
    'forget your instructions',
    'forget previous instructions',
    'new instructions:',
    'system prompt:',
    'you are now',
    'act as if you are',
    'pretend you are',
    'pretend to be',
    'roleplay as',
    'jailbreak',
    'dan mode',
    'developer mode',
  ];

  @override
  String? check(String input) {
    final haystack = caseSensitive ? input : input.toLowerCase();
    for (final pattern in _patterns) {
      final needle = caseSensitive ? pattern : pattern.toLowerCase();
      if (haystack.contains(needle)) {
        return 'Message contains a disallowed phrase: "$pattern".';
      }
    }
    return null;
  }
}

// ── InputGuard ───────────────────────────────────────────────────────────────

/// Thrown when [InputGuard.validate] rejects input.
class InputGuardException implements Exception {
  final String reason;
  const InputGuardException(this.reason);

  @override
  String toString() => 'InputGuardException: $reason';
}

/// Validates and sanitises user input before it enters the agent pipeline.
///
/// ## Default ruleset
/// - [NonEmptyRule] — rejects blank messages
/// - [MaxLengthRule] (8 000 chars) — rejects excessively long messages
/// - [StripControlCharsRule] — strips invisible control characters
///
/// The [PromptInjectionRule] is **not** in the default set because it
/// generates false positives for legitimate developer/power-user queries.
/// Add it explicitly when you need it:
///
/// ```dart
/// final guard = InputGuard(extraRules: [
///   const PromptInjectionRule(),
/// ]);
/// ```
///
/// ## Usage
/// ```dart
/// final guard = InputGuard();
/// final clean = guard.validate('Hello, world!'); // returns sanitised text
/// ```
class InputGuard {
  final List<InputRule> rules;

  InputGuard({List<InputRule> extraRules = const []})
      : rules = [
          const NonEmptyRule(),
          const MaxLengthRule(),
          const StripControlCharsRule(),
          ...extraRules,
        ];

  /// Creates an [InputGuard] with [PromptInjectionRule] enabled.
  factory InputGuard.withInjectionDetection({int maxChars = 8000}) {
    return InputGuard(
      extraRules: [
        const PromptInjectionRule(),
        MaxLengthRule(maxChars: maxChars),
      ],
    );
  }

  /// Validates and sanitises [input].
  ///
  /// Returns the sanitised string if all rules pass.
  /// Throws [InputGuardException] if any rule rejects it.
  String validate(String input) {
    final sanitised = _sanitise(input);
    for (final rule in rules) {
      final reason = rule.check(sanitised);
      if (reason != null) throw InputGuardException(reason);
    }
    return sanitised;
  }

  /// Strips control characters (keeps \t, \n, \r).
  static String _sanitise(String input) {
    return input.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );
  }
}
