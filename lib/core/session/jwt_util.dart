import 'dart:convert';

/// Reads the `exp` claim of a JWT without verifying the signature.
class JwtUtil {
  JwtUtil._();

  /// Expiry instant, or null if the token is malformed or has no `exp`.
  static DateTime? expiracion(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return null;
      final json = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
      final exp = (jsonDecode(json) as Map<String, dynamic>)['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
          isUtc: true);
    } catch (_) {
      return null;
    }
  }

  /// Malformed tokens count as expired.
  static bool estaExpirado(String token, {DateTime? ahora}) {
    final exp = expiracion(token);
    if (exp == null) return true;
    return !exp.isAfter(ahora ?? DateTime.now());
  }
}
