import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_provider.dart';

final notificationsEnabledProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationsNotifier(prefs);
});

class NotificationsNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String key = 'somasmart_notifications';

  NotificationsNotifier(this._prefs) : super(true) {
    state = _prefs.getBool(key) ?? true;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _prefs.setBool(key, next);
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await _prefs.setBool(key, value);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});

class LanguageNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const String key = 'somasmart_language';

  LanguageNotifier(this._prefs) : super('sw') {
    state = _prefs.getString(key) ?? 'sw';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    await _prefs.setString(key, lang);
  }
}
