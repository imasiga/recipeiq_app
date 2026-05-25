import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static const _kHasPreferences = 'has_preferences';
  static const _kIsPro = 'is_pro';

  static Future<bool> hasPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasPreferences) ?? false;
  }

  static Future<void> setHasPreferences(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasPreferences, value);
  }

  static Future<bool> isPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPro) ?? false;
  }

  static Future<void> setIsPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPro, value);
  }
}
