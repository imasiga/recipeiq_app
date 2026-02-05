import 'dart:io';

class ApiConfig {
  // Your current Cloudflare Tunnel URL (changes whenever you restart the quick tunnel)
  static const String tunnelBaseUrl =
      'https://beta-natural-conceptual-narrative.trycloudflare.com';

  // Your Mac LAN IP (only used if you want local Wi-Fi testing on a real phone)
  static const String macLanIp = '192.168.1.20';

  static String baseUrl({
    bool useTunnel = true,
    bool realDevice = false,
  }) {
    // Android emulator -> host machine
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    // ✅ iOS Simulator ALWAYS uses localhost
    // (realDevice=false is the default, so this fixes your simulator immediately)
    if (Platform.isIOS && !realDevice) {
      return 'http://127.0.0.1:8000';
    }

    // ✅ Real iPhone
    if (Platform.isIOS && realDevice) {
      if (useTunnel) return tunnelBaseUrl;
      return 'http://$macLanIp:8000';
    }

    // Other platforms (macOS, etc.)
    if (useTunnel) return tunnelBaseUrl;
    return 'http://127.0.0.1:8000';
  }
}