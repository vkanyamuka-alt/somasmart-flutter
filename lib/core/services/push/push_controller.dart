import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_messaging.dart';
import 'push_routing.dart';

/// Where the app keeps this phone's push token on the server (Supabase
/// `device_tokens`, see SupabasePushBackend).
abstract class PushBackend {
  Future<void> register(String token);
  Future<void> remove(String token);

  /// Asks the server to send a test notification to the signed-in student's phones.
  /// Returns how many phones it reached; throws with the server's message.
  Future<int> sendTest(String language);
}

/// Push notifications for the signed-in student:
/// - registers this phone's token once notifications are allowed (Android 13+
///   asks only when the student turns them on, never at first launch);
/// - keeps the token current, and removes it on sign-out;
/// - passes foreground messages and taps to the app.
class PushController extends ChangeNotifier {
  /// The Settings switch "App notifications" (default on, as before).
  static const prefEnabled = 'somasmart_notifications';

  /// First day the app was opened on this phone; the home screen offers the
  /// study reminder from the next day on, not at first launch.
  static const prefFirstOpen = 'somasmart_first_open_day';

  final PushMessaging messaging;
  final PushBackend backend;
  final SharedPreferences prefs;
  final bool Function() isSignedIn;
  final Stream<bool> signedInChanges;
  final void Function(PushTarget target) onOpen;
  final void Function(PushMessage message) onForeground;
  final DateTime Function() now;

  PushController({
    required this.messaging,
    required this.backend,
    required this.prefs,
    required this.isSignedIn,
    required this.signedInChanges,
    required this.onOpen,
    required this.onForeground,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  bool _started = false;
  bool _available = false;
  PushPermission _permission = PushPermission.notDetermined;
  String? _registeredToken;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// False until start() finds Firebase configured in this build.
  bool get available => _available;
  PushPermission get permission => _permission;

  /// The student wants notifications on this phone and Android allows them.
  bool get enabled => _available && wantsPush && _permission == PushPermission.granted;
  bool get wantsPush => prefs.getBool(prefEnabled) ?? true;

  /// Whether the app has been in use since before today (local day).
  bool get usedBeforeToday {
    final first = prefs.getString(prefFirstOpen);
    return first != null && first.compareTo(_day(now())) < 0;
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (prefs.getString(prefFirstOpen) == null) await prefs.setString(prefFirstOpen, _day(now()));

    _available = await messaging.initialize();
    if (!_available) {
      notifyListeners();
      return;
    }
    _permission = await _safe(messaging.permission, PushPermission.notDetermined);
    notifyListeners();

    _subs
      ..add(messaging.onTokenRefresh.listen((t) => _register(t, force: true)))
      ..add(messaging.onForegroundMessage.listen(onForeground))
      ..add(messaging.onMessageOpenedApp.listen((m) => onOpen(pushTargetFor(m.data))))
      ..add(signedInChanges.listen((signedIn) {
        if (signedIn) {
          registerIfAllowed();
        } else {
          // Session ended (sign-out elsewhere, expiry): drop the phone's token,
          // so the old account's messages stop; FCM tells the server it is gone.
          _registeredToken = null;
          _safe(messaging.deleteToken, null);
        }
      }));

    final initial = await _safe(messaging.getInitialMessage, null);
    if (initial != null) onOpen(pushTargetFor(initial.data));

    await registerIfAllowed();
  }

  /// Registers this phone if the student is signed in, wants notifications and
  /// Android allows them. Never shows the permission dialog.
  Future<void> registerIfAllowed() async {
    if (!_available || !wantsPush || !isSignedIn()) return;
    _permission = await _safe(messaging.permission, _permission);
    notifyListeners();
    if (_permission != PushPermission.granted) return;
    final token = await _safe(messaging.getToken, null);
    if (token != null) await _register(token);
  }

  Future<void> _register(String token, {bool force = false}) async {
    if (!_available || !wantsPush || !isSignedIn()) return;
    if (!force && token == _registeredToken) return;
    try {
      await backend.register(token);
      _registeredToken = token;
    } catch (e) {
      debugPrint('Push: could not register this phone ($e)');
    }
  }

  /// Turns notifications on: shows Android's permission dialog if it was never
  /// answered, then registers. Returns the resulting permission.
  Future<PushPermission> enable() async {
    if (!_available) return PushPermission.denied;
    await prefs.setBool(prefEnabled, true);
    _permission = await _safe(messaging.requestPermission, PushPermission.denied);
    notifyListeners();
    if (_permission == PushPermission.granted) await registerIfAllowed();
    return _permission;
  }

  /// Turns notifications off on this phone (the server stops sending here).
  Future<void> disable() async {
    await prefs.setBool(prefEnabled, false);
    await _removeServerToken();
    notifyListeners();
  }

  /// Call BEFORE signing out of Supabase: the row can only be deleted while
  /// the session is still valid.
  Future<void> unregisterForSignOut() async {
    if (!_available) return;
    await _removeServerToken();
    await _safe(messaging.deleteToken, null);
  }

  Future<void> _removeServerToken() async {
    if (!_available) return;
    final token = _registeredToken ?? await _safe(messaging.getToken, null);
    _registeredToken = null;
    if (token == null || !isSignedIn()) return;
    try {
      await backend.remove(token);
    } catch (e) {
      debugPrint('Push: could not remove this phone ($e)');
    }
  }

  Future<int> sendTest(String language) => backend.sendTest(language);

  static Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('Push: $e');
      return fallback;
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
