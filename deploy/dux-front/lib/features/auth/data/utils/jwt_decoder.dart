import 'dart:convert';

/// Pure utility for decoding JWT payloads.
/// Extracted from AuthRepository (Single Responsibility).
/// Has no dependencies — fully unit-testable.
class JwtDecoder {
  const JwtDecoder._();

  /// Returns the decoded payload claims map from a JWT token string.
  /// Returns an empty map if decoding fails.
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
