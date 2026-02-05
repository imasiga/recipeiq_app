class ImageUrl {
  static String normalize({
    required String rawUrl,
    required String apiBaseUrl,
  }) {
    final s = rawUrl.trim();
    if (s.isEmpty) return s;

    // If backend returns "/storage/...", prefix with API base URL
    if (s.startsWith('/')) {
      return '${apiBaseUrl.replaceAll(RegExp(r'/$'), '')}$s';
    }

    try {
      final u = Uri.parse(s);

      // If already not localhost, keep as-is
      if (u.host != '127.0.0.1' && u.host != 'localhost') return s;

      // Replace localhost with current apiBaseUrl host (tunnel-safe)
      final b = Uri.parse(apiBaseUrl);

      return u
          .replace(
            scheme: b.scheme,
            host: b.host,
            port: b.hasPort ? b.port : u.port,
          )
          .toString();
    } catch (_) {
      return s;
    }
  }
}