import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static const _kHasPreferences = 'has_preferences';

  static Future<bool> hasPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasPreferences) ?? false;
  }

  static Future<void> setHasPreferences(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasPreferences, value);
  }
}