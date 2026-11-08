import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/push/push_controller.dart';
import '../../../../core/services/push/push_messaging.dart';
import '../../../../core/services/push/push_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/study_reminder.dart';
import '../controllers/settings_controller.dart';

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

/// Android 13+ shows its "Allow notifications?" dialog here, the first time a
/// student asks for notifications. Returns true when they are allowed.
Future<bool> turnOnNotifications(BuildContext context, WidgetRef ref) async {
  final isSw = ref.read(languageProvider) == 'sw';
  final result = await ref.read(pushControllerProvider).enable();
  if (result == PushPermission.granted) return true;
  if (context.mounted) {
    _snack(
      context,
      isSw
          ? 'Arifa zimezuiwa. Ziruhusu kwa SomaSmart kwenye Mipangilio ya simu yako.'
          : 'Notifications are blocked. Allow them for SomaSmart in your phone settings.',
    );
  }
  return false;
}

/// Asks for notifications (if needed), then a time, and saves a daily reminder.
Future<bool> setUpStudyReminder(BuildContext context, WidgetRef ref) async {
  final isSw = ref.read(languageProvider) == 'sw';
  if (!await turnOnNotifications(context, ref)) return false;
  if (!context.mounted) return false;

  final saved = ref.read(studyReminderProvider).valueOrNull;
  final time = await showTimePicker(
    context: context,
    initialTime: saved?.time ?? StudyReminder.defaultTime,
    helpText: isSw ? 'Nikukumbushe saa ngapi kila siku?' : 'When should we remind you each day?',
    cancelText: isSw ? 'Ghairi' : 'Cancel',
    confirmText: isSw ? 'Weka' : 'Set',
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  if (time == null || !context.mounted) return false;

  try {
    await ref
        .read(studyReminderProvider.notifier)
        .save(StudyReminder(enabled: true, time: time), language: isSw ? 'sw' : 'en');
  } catch (_) {
    if (context.mounted) {
      _snack(context, isSw ? 'Imeshindikana kuhifadhi. Angalia intaneti, ujaribu tena.' : 'Could not save. Check your internet and try again.');
    }
    return false;
  }
  if (context.mounted) {
    final hhmm = StudyReminder.formatTime(time);
    _snack(context, isSw ? 'Tutakukumbusha kila siku saa $hhmm.' : 'We will remind you every day at $hhmm.');
  }
  return true;
}

Future<void> turnOffStudyReminder(BuildContext context, WidgetRef ref) async {
  final isSw = ref.read(languageProvider) == 'sw';
  final saved = ref.read(studyReminderProvider).valueOrNull;
  try {
    await ref.read(studyReminderProvider.notifier).save(
          (saved ?? const StudyReminder(enabled: false, time: StudyReminder.defaultTime)).copyWith(enabled: false),
          language: isSw ? 'sw' : 'en',
        );
  } catch (_) {
    if (context.mounted) _snack(context, isSw ? 'Imeshindikana kuhifadhi.' : 'Could not save.');
  }
}

/// Offered on the home screen once, from the second day the app is used, to
/// students who have not set a reminder. "Not now" hides it for good.
class StudyReminderPrompt extends ConsumerStatefulWidget {
  const StudyReminderPrompt({super.key});

  static const prefDismissed = 'somasmart_reminder_prompt_dismissed';

  @override
  ConsumerState<StudyReminderPrompt> createState() => _StudyReminderPromptState();
}

class _StudyReminderPromptState extends ConsumerState<StudyReminderPrompt> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final PushController push;
    try {
      push = ref.watch(pushControllerProvider);
    } catch (_) {
      return const SizedBox.shrink(); // push not set up in this context (tests)
    }
    final prefs = push.prefs;
    final reminder = ref.watch(studyReminderProvider);
    final show = push.available &&
        push.isSignedIn() &&
        push.usedBeforeToday &&
        !(prefs.getBool(StudyReminderPrompt.prefDismissed) ?? false) &&
        push.permission != PushPermission.denied &&
        reminder.hasValue &&
        reminder.value == null;
    if (!show) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSw = ref.watch(languageProvider) == 'sw';
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    Future<void> dismiss() async {
      await prefs.setBool(StudyReminderPrompt.prefDismissed, true);
      if (mounted) setState(() {});
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: const Key('home-reminder-prompt'),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSw ? 'Nikukumbushe kusoma kila siku?' : 'Want a daily study reminder?',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    key: const Key('home-reminder-not-now'),
                    onPressed: _busy ? null : dismiss,
                    child: Text(isSw ? 'Sio sasa' : 'Not now'),
                  ),
                  FilledButton(
                    key: const Key('home-reminder-turn-on'),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final ok = await setUpStudyReminder(context, ref);
                            if (ok) await prefs.setBool(StudyReminderPrompt.prefDismissed, true);
                            if (mounted) setState(() => _busy = false);
                          },
                    child: Text(isSw ? 'Chagua saa' : 'Pick a time'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
