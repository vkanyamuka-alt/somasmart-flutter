import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/section_widgets.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../controllers/settings_controller.dart';

/// Settings, grouped the same way as the web Settings page:
/// Account, Appearance, Notifications, Support, Legal, Sign out and
/// Request account deletion. Only settings that work are shown.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // One expandable row open at a time: about, privacy, terms or delete.
  String? _open;

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  Future<void> _confirmSignOut(bool isSw) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSw ? 'Toka kwenye akaunti?' : 'Sign out?'),
        content: Text(isSw ? 'Utahitaji kuingia tena ili kuendelea kusoma.' : 'You will need to log in again to keep studying.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isSw ? 'Ghairi' : 'Cancel')),
          FilledButton(
            key: const Key('settings-confirm-sign-out'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSw ? 'Toka' : 'Sign out'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await ref.read(userProfileProvider.notifier).signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final lang = ref.watch(languageProvider);
    final isSw = lang == 'sw';
    final profile = ref.watch(userProfileProvider).valueOrNull;
    String t(String en, String sw) => isSw ? sw : en;

    final name = (profile?.fullName.trim().isNotEmpty ?? false) && profile!.fullName != 'User'
        ? profile.fullName
        : t('Student', 'Mwanafunzi');
    final initials = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.l, AppSpacing.gutter, AppSpacing.bottomNavClearance),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    t('Settings', 'Mipangilio'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                ),
                const SizedBox(height: AppSpacing.l + 4),

                SettingsGroup(label: t('Account', 'Akaunti'), children: [
                  InkWell(
                    key: const Key('settings-account'),
                    onTap: () => context.go('/account'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 2),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? AppColors.primaryLight.withValues(alpha: 0.14) : AppColors.primarySoft,
                            child: Text(
                              initials.isEmpty ? 'S' : initials,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                if ((profile?.phone ?? '').isNotEmpty || (profile?.email ?? '').isNotEmpty)
                                  Text(
                                    (profile!.phone.isNotEmpty ? profile.phone : profile.email),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ],
                      ),
                    ),
                  ),
                ]),

                SettingsGroup(label: t('Appearance', 'Mwonekano'), children: [
                  _Block(
                    title: t('Display mode', 'Mandhari'),
                    subtitle: t('System follows your device.', 'Mfumo unafuata mpangilio wa kifaa chako.'),
                    child: _Segmented<ThemeMode>(
                      keyPrefix: 'settings-theme',
                      value: themeMode,
                      onChanged: (mode) => ref.read(themeModeProvider.notifier).setTheme(mode),
                      options: [
                        _Option(ThemeMode.system, t('System', 'Mfumo'), Icons.phone_android_rounded),
                        _Option(ThemeMode.light, t('Light', 'Mwanga'), Icons.light_mode_outlined),
                        _Option(ThemeMode.dark, t('Dark', 'Giza'), Icons.dark_mode_outlined),
                      ],
                    ),
                  ),
                  _Block(
                    title: t('Language', 'Lugha'),
                    child: _Segmented<String>(
                      keyPrefix: 'settings-language',
                      value: lang,
                      onChanged: (code) => ref.read(languageProvider.notifier).setLanguage(code),
                      options: const [
                        _Option('sw', 'Kiswahili'),
                        _Option('en', 'English'),
                      ],
                    ),
                  ),
                ]),

                SettingsGroup(label: t('Notifications', 'Arifa'), children: [
                  SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: t('App notifications', 'Arifa za app'),
                    subtitle: t('New lessons, quizzes and announcements', 'Masomo mapya, quizzes na matangazo'),
                    trailing: Switch.adaptive(
                      key: const Key('settings-notifications'),
                      value: notificationsEnabled,
                      activeTrackColor: isDark ? AppColors.primaryLight : AppColors.primary,
                      onChanged: (val) {
                        ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text(val ? t('Notifications on', 'Arifa zimewashwa') : t('Notifications off', 'Arifa zimezimwa')),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ));
                      },
                    ),
                  ),
                ]),

                SettingsGroup(label: t('Support', 'Msaada'), children: [
                  SettingsRow(
                    key: const Key('settings-help'),
                    icon: Icons.help_outline_rounded,
                    title: t('Help and support', 'Msaada'),
                    onTap: () => context.push('/contact-support'),
                  ),
                  _ExpandRow(
                    id: 'about',
                    open: _open == 'about',
                    onToggle: _toggle,
                    icon: Icons.info_outline_rounded,
                    title: t('About SomaSmart', 'Kuhusu SomaSmart'),
                    body: Text(
                      t(
                        'SomaSmart is a learning platform for Tanzanian secondary students: NECTA notes, quizzes and practicals, on the web and the mobile app.',
                        'SomaSmart ni jukwaa la elimu kwa wanafunzi wa sekondari Tanzania: notes za NECTA, quizzes na practicals, kwenye tovuti na app ya simu.',
                      ),
                      style: bodyStyle,
                    ),
                  ),
                ]),

                SettingsGroup(label: t('Legal', 'Sheria'), children: [
                  _ExpandRow(
                    id: 'privacy',
                    open: _open == 'privacy',
                    onToggle: _toggle,
                    icon: Icons.shield_outlined,
                    title: t('Privacy policy', 'Sera ya faragha'),
                    body: Text(
                      t(
                        'SomaSmart values your data privacy. We collect basic account info (name, email, phone) to personalize your learning. Your data is never shared with third parties without your consent.',
                        'SomaSmart inajali usalama na usiri wa taarifa zako. Tunakusanya taarifa za msingi kama jina, barua pepe na namba ya simu ili kuboresha matumizi yako. Hatushiriki taarifa zako na upande wowote wa tatu bila ridhaa yako.',
                      ),
                      style: bodyStyle,
                    ),
                  ),
                  _ExpandRow(
                    id: 'terms',
                    open: _open == 'terms',
                    onToggle: _toggle,
                    icon: Icons.article_outlined,
                    title: t('Terms of service', 'Vigezo na masharti'),
                    body: Text(
                      t(
                        'By using SomaSmart, you agree not to copy, distribute or resell its summaries, notes or quizzes without written permission. The service is for your personal educational use only.',
                        'Kwa kutumia jukwaa hili, unakubali kutonakili, kutosambaza au kuuza summaries, notes na quizzes za SomaSmart bila kibali maalum cha maandishi. Huduma hii ni kwa matumizi yako ya kibinafsi pekee.',
                      ),
                      style: bodyStyle,
                    ),
                  ),
                ]),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('settings-sign-out'),
                    onPressed: () => _confirmSignOut(isSw),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(t('Sign out', 'Toka')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SettingsGroup(label: t('Delete account', 'Futa akaunti'), children: [
                  _ExpandRow(
                    id: 'delete',
                    open: _open == 'delete',
                    onToggle: _toggle,
                    icon: Icons.person_remove_outlined,
                    title: t('Request account deletion', 'Omba kufutwa kwa akaunti'),
                    danger: true,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(
                            "To delete your account and all your data, contact the SomaSmart team from the phone number or email you registered with. We'll confirm with you before deleting anything.",
                            'Ili kufuta akaunti yako na taarifa zako zote, wasiliana na timu ya SomaSmart ukitumia namba au email uliyosajili nayo. Tutakuthibitishia kabla ya kufuta.',
                          ),
                          style: bodyStyle,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        OutlinedButton(
                          key: const Key('settings-delete-contact'),
                          onPressed: () => context.push('/contact-support'),
                          child: Text(t('Contact support', 'Wasiliana na msaada')),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row that opens to show more text underneath, like the web's expandable rows.
class _ExpandRow extends StatelessWidget {
  final String id;
  final bool open;
  final ValueChanged<String> onToggle;
  final IconData icon;
  final String title;
  final Widget body;
  final bool danger;

  const _ExpandRow({
    required this.id,
    required this.open,
    required this.onToggle,
    required this.icon,
    required this.title,
    required this.body,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          expanded: open,
          child: SettingsRow(
            key: Key('settings-row-$id'),
            icon: icon,
            title: title,
            danger: danger,
            onTap: () => onToggle(id),
            trailing: AnimatedRotation(
              turns: open ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: open
              ? Padding(padding: const EdgeInsets.fromLTRB(62, 0, AppSpacing.l, AppSpacing.l), child: body)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Title, optional subtitle and a control underneath.
class _Block extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Block({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final String label;
  final IconData? icon;
  const _Option(this.value, this.label, [this.icon]);
}

/// Equal-width choice buttons, the selected one filled with navy.
class _Segmented<T> extends StatelessWidget {
  final String keyPrefix;
  final T value;
  final ValueChanged<T> onChanged;
  final List<_Option<T>> options;

  const _Segmented({required this.keyPrefix, required this.value, required this.onChanged, required this.options});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              selected: options[i].value == value,
              button: true,
              child: InkWell(
                key: Key('$keyPrefix-${options[i].value is Enum ? (options[i].value as Enum).name : options[i].value}'),
                onTap: () => onChanged(options[i].value),
                borderRadius: BorderRadius.circular(AppRadius.tile),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: options[i].value == value ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    border: Border.all(color: options[i].value == value ? accent : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (options[i].icon != null) ...[
                          Icon(
                            options[i].icon,
                            size: 15,
                            color: options[i].value == value ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          options[i].label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: options[i].value == value ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
