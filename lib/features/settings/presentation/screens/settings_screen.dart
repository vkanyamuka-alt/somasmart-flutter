import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../controllers/settings_controller.dart';

/// Settings Screen (Tab 5)
/// Fully aligned with SomaSmart React `Settings.jsx` information architecture & visual direction.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _privacyExpanded = false;
  bool _termsExpanded = false;
  bool _showDeleteConfirm = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLang == 'sw' ? 'Mipangilio' : 'Settings',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      currentLang == 'sw'
                          ? 'Mapendeleo, Usiri na Udhibiti wa Akaunti'
                          : 'Preferences, Privacy & App Controls',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card 1: Theme / Muonekano
            _SettingsCard(
              title: currentLang == 'sw' ? 'Muonekano' : 'Appearance / Theme',
              icon: Icons.palette_outlined,
              description: currentLang == 'sw'
                  ? 'Badilisha muonekano wa programu kulingana na mwangaza unaoupenda.'
                  : 'Customize the visual theme between light and dark modes.',
              child: Row(
                children: [
                  Expanded(
                    child: _ChoiceButton(
                      label: 'Light Mode',
                      icon: Icons.light_mode_rounded,
                      isSelected: themeMode == ThemeMode.light ||
                          (themeMode == ThemeMode.system && !isDark),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceButton(
                      label: 'Dark Mode',
                      icon: Icons.dark_mode_rounded,
                      isSelected: themeMode == ThemeMode.dark ||
                          (themeMode == ThemeMode.system && isDark),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: App Notifications / Taarifa za App
            _SettingsCard(
              title: currentLang == 'sw' ? 'Taarifa za App' : 'App Notifications',
              icon: Icons.notifications_none_rounded,
              trailing: Switch.adaptive(
                value: notificationsEnabled,
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? (currentLang == 'sw'
                                ? 'Arifa zimeamilishwa!'
                                : 'Notifications enabled!')
                            : (currentLang == 'sw'
                                ? 'Arifa zimezimwa.'
                                : 'Notifications disabled.'),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: isDark
                          ? AppColors.darkBgSurface
                          : AppColors.lightBgSurface,
                    ),
                  );
                },
              ),
              description: currentLang == 'sw'
                  ? 'Washa au zima arifa za masomo mapya, ratiba za masomo na quizzes mpya kwenye simu yako.'
                  : 'Enable or disable push alerts for new syllabus summaries, quiz additions, and study planners.',
            ),
            const SizedBox(height: 14),

            // Card 3: Language Settings / Mipangilio ya Lugha
            _SettingsCard(
              title: currentLang == 'sw' ? 'Mipangilio ya Lugha' : 'Language Settings',
              icon: Icons.language_rounded,
              description: currentLang == 'sw'
                  ? 'Chagua lugha ya kutumia kwenye jukwaa la SomaSmart.'
                  : 'Choose the language to use across the SomaSmart platform.',
              child: Row(
                children: [
                  Expanded(
                    child: _ChoiceButton(
                      label: 'Kiswahili',
                      isSelected: currentLang == 'sw',
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage('sw');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceButton(
                      label: 'English',
                      isSelected: currentLang == 'en',
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage('en');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 4: Privacy Policy Accordion / Sera ya Faragha
            _AccordionSettingsCard(
              title: currentLang == 'sw' ? 'Sera ya Faragha' : 'Privacy Policy',
              icon: Icons.shield_outlined,
              isExpanded: _privacyExpanded,
              onToggle: () {
                setState(() {
                  _privacyExpanded = !_privacyExpanded;
                });
              },
              collapsedDescription: currentLang == 'sw'
                  ? 'Soma jinsi tunavyolinda na kusimamia taarifa zako za siri.'
                  : 'Read how we secure and protect your private account data.',
              expandedContent: currentLang == 'sw'
                  ? 'SomaSmart inajali usalama na usiri wa taarifa zako. Tunakusanya taarifa za msingi kama jina, barua pepe na namba ya simu ili kuboresha matumizi yako. Hatushiriki taarifa zako na upande wowote wa tatu bila ridhaa yako.'
                  : 'SomaSmart values your data privacy. We collect basic account info (name, email, phone) to personalize your learning. Your credentials are fully encrypted and are never shared with third parties without your consent.',
            ),
            const SizedBox(height: 14),

            // Card 5: Terms of Service Accordion / Vigezo na Masharti
            _AccordionSettingsCard(
              title: currentLang == 'sw' ? 'Vigezo na Masharti' : 'Terms of Service',
              icon: Icons.article_outlined,
              isExpanded: _termsExpanded,
              onToggle: () {
                setState(() {
                  _termsExpanded = !_termsExpanded;
                });
              },
              collapsedDescription: currentLang == 'sw'
                  ? 'Sheria na vigezo vya matumizi ya huduma za SomaSmart.'
                  : 'The terms and regulations governing the use of SomaSmart app.',
              expandedContent: currentLang == 'sw'
                  ? 'Kwa kutumia jukwaa hili, unakubali kutonakili, kutosambaza au kuuza summaries, notes na quizzes za SomaSmart bila kibali maalum cha maandishi. Huduma hii ni kwa matumizi yako ya kibinafsi pekee.'
                  : 'By accessing SomaSmart services, you agree not to duplicate, distribute, or resell any platform summaries or quiz contents without written consent. The service is strictly for personal educational use.',
            ),
            const SizedBox(height: 14),

            // Card 6: Account Security / Usalama wa Akaunti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentLang == 'sw' ? 'Usalama wa Akaunti' : 'Account Security',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLang == 'sw'
                        ? 'Ukitaka kufuta akaunti yako kabisa na kufuta data zako zote kwenye mfumo.'
                        : 'Permanently delete your user profile and remove all stored educational logs from our databases.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_showDeleteConfirm)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showDeleteConfirm = true;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          currentLang == 'sw' ? 'Futa Akaunti Yako' : 'Delete Account',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang == 'sw'
                                ? 'Je, una uhakika kabisa? Data zote zitapotea daima.'
                                : 'Are you absolutely sure? This cannot be undone.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showDeleteConfirm = false;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  currentLang == 'sw' ? 'Ghairi' : 'Cancel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        currentLang == 'sw'
                                            ? 'Ombi lako la kufuta akaunti limetumwa.'
                                            : 'Account deletion request submitted.',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  setState(() {
                                    _showDeleteConfirm = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  currentLang == 'sw' ? 'Ndio, Futa' : 'Yes, Delete',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final Widget? trailing;
  final Widget? child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    this.description,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trailingWidget = trailing;
    final desc = description;
    final childWidget = child;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ?trailingWidget,
            ],
          ),
          if (desc != null) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (childWidget != null) ...[
            const SizedBox(height: 12),
            childWidget,
          ],
        ],
      ),
    );
  }
}

class _AccordionSettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String collapsedDescription;
  final String expandedContent;

  const _AccordionSettingsCard({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.collapsedDescription,
    required this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(
                    collapsedDescription,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.45,
                    ),
                  ),
                  secondChild: Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: Text(
                      expandedContent,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkBgBase : AppColors.lightBgContainer),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryLight
                        : AppColors.primary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
