import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/settings/presentation/controllers/settings_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/notification_drawer.dart';
import '../announcements_service.dart';
import '../supabase_service.dart';
import 'push_controller.dart';
import 'push_messaging.dart';
import 'push_routing.dart';

/// The app's ScaffoldMessenger, so a push that arrives while the app is open
/// can show a banner on whatever screen the student is on.
final pushMessengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'push-messenger');

SupabaseClient? _clientOrNull(Ref ref) {
  try {
    return ref.read(supabaseClientProvider);
  } catch (_) {
    return null; // widget tests: Supabase is not initialised
  }
}

/// device_tokens via register_device_token (moves a shared phone's token to
/// the student now signed in) and a plain RLS delete on sign-out.
class SupabasePushBackend implements PushBackend {
  final SupabaseClient client;
  SupabasePushBackend(this.client);

  @override
  Future<void> register(String token) =>
      client.rpc('register_device_token', params: {'p_token': token, 'p_platform': 'android'});

  @override
  Future<void> remove(String token) => client.from('device_tokens').delete().eq('token', token);

  @override
  Future<int> sendTest(String language) async {
    try {
      final res = await client.functions.invoke('push-send', body: {'type': 'test', 'language': language});
      final data = res.data is Map ? res.data as Map : const {};
      return (data['sent'] as num?)?.toInt() ?? 0;
    } on FunctionException catch (e) {
      final d = e.details;
      throw Exception(d is Map && d['error'] is String ? d['error'] : 'push-send ${e.status}');
    }
  }
}

class _NoBackend implements PushBackend {
  @override
  Future<void> register(String token) async {}
  @override
  Future<void> remove(String token) async {}
  @override
  Future<int> sendTest(String language) async => throw Exception('Not signed in');
}

final pushMessagingProvider = Provider<PushMessaging>((ref) => FirebasePushMessaging());

final pushBackendProvider = Provider<PushBackend>((ref) {
  final client = _clientOrNull(ref);
  return client == null ? _NoBackend() : SupabasePushBackend(client);
});

/// Opens the screen a tapped notification points to. While the app is still on
/// the splash or sign-in screens it waits, then opens it once the student is in.
class PushNavigator {
  final GoRouter router;
  final void Function() refreshAnnouncements;
  PushTarget? _pending;
  bool _listening = false;

  PushNavigator(this.router, {required this.refreshAnnouncements});

  String get _path {
    try {
      return router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '/splash';
    }
  }

  void open(PushTarget target) {
    if (isPushHoldingRoute(_path)) {
      _pending = target;
      if (!_listening) {
        _listening = true;
        router.routerDelegate.addListener(_onRouteChanged);
      }
      return;
    }
    _go(target);
  }

  void _onRouteChanged() {
    final target = _pending;
    if (target == null || isPushHoldingRoute(_path)) return;
    _pending = null;
    _listening = false;
    router.routerDelegate.removeListener(_onRouteChanged);
    // Let the screen that just opened finish building first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(target));
  }

  void _go(PushTarget target) {
    router.go('/home');
    if (target.route != '/home') router.push(target.route);
    if (target.openAnnouncements) {
      refreshAnnouncements();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) NotificationDrawer.show(ctx);
      });
    }
  }
}

final pushNavigatorProvider = Provider<PushNavigator>((ref) => PushNavigator(
      ref.read(appRouterProvider),
      refreshAnnouncements: () => ref.invalidate(announcementsProvider),
    ));

/// A message that arrives while the app is open: Android does not show it, so
/// the app shows a navy banner with an "Open" button.
void showForegroundPush(Ref ref, PushMessage m) {
  final target = pushTargetFor(m.data);
  if (target.openAnnouncements) ref.invalidate(announcementsProvider);
  final messenger = pushMessengerKey.currentState;
  if (messenger == null || (m.title == null && m.body == null)) return;
  final isSw = ref.read(languageProvider) == 'sw';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: const Key('push-foreground-banner'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      duration: const Duration(seconds: 6),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.title != null)
            Text(m.title!, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          if (m.body != null) Text(m.body!, style: const TextStyle(color: Colors.white)),
        ],
      ),
      action: SnackBarAction(
        label: isSw ? 'Fungua' : 'Open',
        textColor: AppColors.brandGold,
        onPressed: () => ref.read(pushNavigatorProvider).open(target),
      ),
    ));
}

final pushControllerProvider = ChangeNotifierProvider<PushController>((ref) {
  final client = _clientOrNull(ref);
  final auth = client?.auth;
  return PushController(
    messaging: ref.read(pushMessagingProvider),
    backend: ref.read(pushBackendProvider),
    prefs: ref.read(sharedPreferencesProvider),
    isSignedIn: () => auth?.currentSession != null,
    signedInChanges: auth == null
        ? const Stream.empty()
        : auth.onAuthStateChange
            .where((s) =>
                s.event == AuthChangeEvent.signedIn ||
                s.event == AuthChangeEvent.signedOut ||
                (s.event == AuthChangeEvent.initialSession && s.session != null))
            .map((s) => s.event != AuthChangeEvent.signedOut),
    onOpen: (target) => ref.read(pushNavigatorProvider).open(target),
    onForeground: (m) => showForegroundPush(ref, m),
  );
});

/// Sign-out helper used by the Settings screen and the profile controller.
Future<void> unregisterPushBeforeSignOut(Ref ref) async {
  try {
    await ref.read(pushControllerProvider).unregisterForSignOut();
  } catch (_) {}
}

/// The language the student reads in, for server texts (reminders, test push).
String pushLanguage(WidgetRef ref) => ref.read(languageProvider) == 'en' ? 'en' : 'sw';
