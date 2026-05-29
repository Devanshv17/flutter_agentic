/// Output validation for LLM responses before they reach the end user.
///
/// The [OutputGuard] lets developers:
/// - redact PII (emails, phone numbers, credit card numbers, SSNs)
/// - enforce a maximum response length
/// - add custom post-processing / filtering rules
library;

/// A single transformation or check applied to raw LLM output.
abstract class OutputRule {
  const OutputRule();

  /// Return the (potentially modified) output, or throw [OutputGuardException]
  /// to reject it entirely.
  String process(String output);
}

// ── Built-in rules ───────────────────────────────────────────────────────────

/// Truncates responses that exceed [maxChars] characters.
///
/// Rather than throwing, it trims and appends an ellipsis so the user
/// still receives a partial answer.
class TruncateOutputRule extends OutputRule {
  final int maxChars;
  final String suffix;

  const TruncateOutputRule({
    this.maxChars = 32000,
    this.suffix = '… [response truncated]',
  });

  @override
  String process(String output) {
    if (output.length <= maxChars) return output;
    return output.substring(0, maxChars) + suffix;
  }
}

/// Redacts common PII patterns with a configurable placeholder.
///
/// Patterns covered:
/// - Email addresses
/// - US/international phone numbers (various formats)
/// - Credit card numbers (13–19 digit, space/dash-separated)
/// - US Social Security Numbers (xxx-xx-xxxx)
class PiiRedactionRule extends OutputRule {
  final String placeholder;

  const PiiRedactionRule({this.placeholder = '[REDACTED]'});

  // Compiled once for efficiency.
  static final _emailRe =
      RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');

  static final _phoneRe = RegExp(
    r'(\+?1?\s?)?'
    r'(\(?\d{3}\)?[\s.\-]?)'
    r'(\d{3}[\s.\-]?)'
    r'(\d{4})',
  );

  static final _creditCardRe = RegExp(
    r'\b(?:\d[ \-]?){13,19}\b',
  );

  static final _ssnRe = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');

  @override
  String process(String output) {
    var result = output;
    result = result.replaceAll(_emailRe, placeholder);
    result = result.replaceAll(_phoneRe, placeholder);
    result = result.replaceAll(_creditCardRe, placeholder);
    result = result.replaceAll(_ssnRe, placeholder);
    return result;
  }
}

/// Rejects responses that contain any phrase from [blocklist].
///
/// Useful when you need to guarantee the model never surfaces certain
/// brand names, internal codenames, or other forbidden strings.
class BlocklistOutputRule extends OutputRule {
  final List<String> blocklist;
  final bool caseSensitive;

  const BlocklistOutputRule({
    required this.blocklist,
    this.caseSensitive = false,
  });

  @override
  String process(String output) {
    final haystack = caseSensitive ? output : output.toLowerCase();
    for (final word in blocklist) {
      final needle = caseSensitive ? word : word.toLowerCase();
      if (haystack.contains(needle)) {
        throw OutputGuardException(
            'Response contains a blocked term: "$word".');
      }
    }
    return output;
  }
}

// ── OutputGuard ──────────────────────────────────────────────────────────────

/// Thrown when an [OutputRule] rejects an LLM response.
class OutputGuardException implements Exception {
  final String reason;
  const OutputGuardException(this.reason);

  @override
  String toString() => 'OutputGuardException: $reason';
}

/// Applies a pipeline of [OutputRule]s to LLM responses.
///
/// ## Default ruleset
/// - [TruncateOutputRule] (32 000 chars)
///
/// ## Example — add PII redaction
/// ```dart
/// final guard = OutputGuard(extraRules: [
///   const PiiRedactionRule(),
/// ]);
///
/// final safe = guard.process(rawLlmResponse);
/// ```
///
/// ## Example — block specific words
/// ```dart
/// final guard = OutputGuard(extraRules: [
///   BlocklistOutputRule(blocklist: ['competitor_name', 'internal_codename']),
/// ]);
/// ```
class OutputGuard {
  final List<OutputRule> rules;

  OutputGuard({List<OutputRule> extraRules = const []})
      : rules = [
          const TruncateOutputRule(),
          ...extraRules,
        ];

  /// Creates an [OutputGuard] with PII redaction enabled.
  factory OutputGuard.withPiiRedaction({String placeholder = '[REDACTED]'}) {
    return OutputGuard(
      extraRules: [PiiRedactionRule(placeholder: placeholder)],
    );
  }

  /// Runs [output] through all rules in order.
  ///
  /// Returns the (possibly modified) text, or throws [OutputGuardException].
  String process(String output) {
    var result = output;
    for (final rule in rules) {
      result = rule.process(result);
    }
    return result;
  }
}
