import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import 'supabase_service.dart';

/// An announcement that an admin posted in the admin panel. The web app's
/// bell and Updates page read the same `announcements` table.
class Announcement {
  final String id;
  final String title;
  final String content;
  final String priority;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.priority = 'medium',
    this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        id: m['id'].toString(),
        title: (m['title'] as String?) ?? '',
        content: (m['content'] as String?) ?? '',
        priority: (m['priority'] as String?) ?? 'medium',
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(m['expires_at']?.toString() ?? ''),
        isActive: m['is_active'] != false,
      );
}

/// Active, unexpired announcements, newest first (same rule as the web).
List<Announcement> visibleAnnouncements(List<Announcement> all, DateTime now) {
  final list = all.where((a) => a.isActive && (a.expiresAt == null || a.expiresAt!.isAfter(now))).toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  return list;
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    final rows = await ref
        .read(supabaseClientProvider)
        .from('announcements')
        .select('id, title, content, priority, is_active, expires_at, created_at')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(50);
    return visibleAnnouncements(
      (rows as List).map((r) => Announcement.fromMap(Map<String, dynamic>.from(r as Map))).toList(),
      DateTime.now(),
    );
  } catch (_) {
    return const [];
  }
});

/// Ids the student has already seen, kept on the device.
class ReadAnnouncementsNotifier extends StateNotifier<Set<String>> {
  static const _key = 'somasmart_read_announcements';
  final Ref _ref;

  ReadAnnouncementsNotifier(this._ref)
      : super((_ref.read(sharedPreferencesProvider).getStringList(_key) ?? const []).toSet());

  Future<void> markAll(Iterable<String> ids) async {
    state = {...state, ...ids};
    await _ref.read(sharedPreferencesProvider).setStringList(_key, state.toList());
  }
}

final readAnnouncementsProvider =
    StateNotifierProvider<ReadAnnouncementsNotifier, Set<String>>((ref) => ReadAnnouncementsNotifier(ref));

/// How many announcements the student has not opened yet (for the bell badge).
final unreadAnnouncementsCountProvider = Provider<int>((ref) {
  final items = ref.watch(announcementsProvider).valueOrNull ?? const [];
  final read = ref.watch(readAnnouncementsProvider);
  return items.where((a) => !read.contains(a.id)).length;
});
