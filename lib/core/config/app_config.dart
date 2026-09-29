import 'dart:convert';

/// Live access is opt-in; no website credentials or fallback endpoint.
class AppConfig {
  const AppConfig({
    this.enabled = false,
    this.environment = 'development',
    this.url = '',
    this.publicKey = '',
  });
  factory AppConfig.fromEnvironment() => const AppConfig(
    enabled: bool.fromEnvironment('ENABLE_SUPABASE'),
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    url: String.fromEnvironment('SUPABASE_URL'),
    publicKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  final bool enabled;
  final String environment;
  final String url;
  final String publicKey;

  String? get validationError {
    if (!enabled) return null;
    if (environment != 'development' && environment != 'test') {
      return 'Only development and test backends are supported in this build.';
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return 'Configure a valid HTTPS test Supabase project URL.';
    }
    if (publicKey.startsWith('sb_publishable_') && publicKey.length > 20) {
      return null;
    }
    // Legacy anon JWTs are supported; privileged keys must never enter a client.
    try {
      final parts = publicKey.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (payload is Map && payload['role'] == 'anon') return null;
      }
    } catch (_) {
      /* Invalid public key. */
    }
    return 'Use a public publishable or anon key for the test project.';
  }
}
