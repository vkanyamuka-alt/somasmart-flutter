import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/push/push_routing.dart';
import '../../../core/services/supabase_service.dart';

/// The student's daily "time to study" reminder (Supabase `study_reminders`).
/// The server sends it (pg_cron + push-reminders), so it arrives even when
/// the app has not been opened for days.
class StudyReminder {
  final bool enabled;
  final TimeOfDay time;

  const StudyReminder({required this.enabled, required this.time});

  static const defaultTime = TimeOfDay(hour: 18, minute: 0);

  /// Postgres `time` ("18:30:00") to TimeOfDay.
  static TimeOfDay parseTime(String? value) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value ?? '');
    if (m == null) return defaultTime;
    final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return defaultTime;
    return TimeOfDay(hour: h, minute: min);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  factory StudyReminder.fromRow(Map<String, dynamic> row) => StudyReminder(
        enabled: row['enabled'] != false,
        time: parseTime(row['remind_at']?.toString()),
      );

  Map<String, dynamic> toRow({required String userId, required String language, required Duration utcOffset}) => {
        'user_id': userId,
        'enabled': enabled,
        'remind_at': formatTime(time),
        'time_zone': timeZoneForOffset(utcOffset),
        'language': language == 'en' ? 'en' : 'sw',
      };

  StudyReminder copyWith({bool? enabled, TimeOfDay? time}) =>
      StudyReminder(enabled: enabled ?? this.enabled, time: time ?? this.time);
}

class StudyReminderRepository {
  final SupabaseClient client;
  StudyReminderRepository(this.client);

  String? get _uid => client.auth.currentUser?.id;

  /// Null = never set up on any phone.
  Future<StudyReminder?> load() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await client.from('study_reminders').select('enabled, remind_at').eq('user_id', uid).maybeSingle();
    return row == null ? null : StudyReminder.fromRow(row);
  }

  Future<void> save(StudyReminder r, {required String language}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    await client.from('study_reminders').upsert(
          r.toRow(userId: uid, language: language, utcOffset: DateTime.now().timeZoneOffset),
          onConflict: 'user_id',
        );
  }
}

final studyReminderRepositoryProvider = Provider<StudyReminderRepository?>((ref) {
  try {
    return StudyReminderRepository(ref.read(supabaseClientProvider));
  } catch (_) {
    return null; // widget tests: Supabase is not initialised
  }
});

/// The saved reminder (null = not set up). Errors read as "not set up".
class StudyReminderNotifier extends AsyncNotifier<StudyReminder?> {
  @override
  Future<StudyReminder?> build() async {
    final repo = ref.read(studyReminderRepositoryProvider);
    if (repo == null) return null;
    try {
      return await repo.load();
    } catch (_) {
      return null;
    }
  }

  /// Saves on the server first, then shows it. Throws if the save fails.
  Future<void> save(StudyReminder r, {required String language}) async {
    final repo = ref.read(studyReminderRepositoryProvider);
    if (repo == null) throw Exception('Not available');
    await repo.save(r, language: language);
    state = AsyncData(r);
  }
}

final studyReminderProvider =
    AsyncNotifierProvider<StudyReminderNotifier, StudyReminder?>(StudyReminderNotifier.new);
