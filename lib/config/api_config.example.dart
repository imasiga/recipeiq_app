import 'dart:io';

class ApiConfig {
  // Example values — copy this file to api_config.dart and edit.
  static const String tunnelBaseUrl = 'https://YOUR-TUNNEL.trycloudflare.com';
  static const String macLanIp = '192.168.1.20';

  static String baseUrl({
    bool useTunnel = true,
    bool realDevice = false,
  }) {
    if (useTunnel) return tunnelBaseUrl;

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    if (!realDevice) return 'http://127.0.0.1:8000';

    return 'http://$macLanIp:8000';
  }
}
