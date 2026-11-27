/// Where a tapped notification opens the app.
class PushTarget {
  final String route;

  /// Also open the announcements sheet (the bell) on top of [route].
  final bool openAnnouncements;

  const PushTarget(this.route, {this.openAnnouncements = false});

  @override
  bool operator ==(Object other) =>
      other is PushTarget && other.route == route && other.openAnnouncements == openAnnouncements;

  @override
  int get hashCode => Object.hash(route, openAnnouncements);

  @override
  String toString() => 'PushTarget($route, openAnnouncements: $openAnnouncements)';
}

/// First path segments a notification may open. Anything else goes home, so a
/// mistyped route in a message can never strand a student on a broken page.
const pushRouteSections = {
  'home', 'settings', 'progress', 'account', 'shop', 'subscription', 'subjects',
  'notes', 'syllabus', 'quiz-exams', 'exams', 'forum', 'practicals', 'practical',
};

/// Reads the `type` and `route` data that push-send / push-reminders put in
/// every message.
PushTarget pushTargetFor(Map<String, String> data) {
  if (data['type'] == 'announcement') return const PushTarget('/home', openAnnouncements: true);

  final route = (data['route'] ?? '').trim();
  final uri = Uri.tryParse(route);
  final ok = uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      route.startsWith('/') &&
      !route.startsWith('//') &&
      uri.pathSegments.isNotEmpty &&
      pushRouteSections.contains(uri.pathSegments.first);
  return PushTarget(ok ? route : '/home');
}

/// Routes where the app is not ready to open a notification yet: it waits
/// until the student is past the splash screen and signed in.
bool isPushHoldingRoute(String path) =>
    const {'/', '/splash', '/welcome', '/login', '/signup', '/forgot-password', '/contact-support'}.contains(path);

/// Supabase stores IANA zone names. Phones in Tanzania (UTC+3) get
/// Africa/Dar_es_Salaam; elsewhere whole-hour offsets map to Etc/GMT zones
/// (whose sign is inverted by convention).
String timeZoneForOffset(Duration offset) {
  if (offset == const Duration(hours: 3)) return 'Africa/Dar_es_Salaam';
  if (offset.inMinutes % 60 != 0 || offset.inHours.abs() > 14) return 'Africa/Dar_es_Salaam';
  final h = offset.inHours;
  if (h == 0) return 'Etc/GMT';
  return h > 0 ? 'Etc/GMT-$h' : 'Etc/GMT+${-h}';
}
