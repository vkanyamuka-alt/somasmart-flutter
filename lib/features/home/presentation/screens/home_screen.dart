import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/card_surface.dart';
import '../../../../core/widgets/section_widgets.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';

/// Home dashboard. Same order as the web dashboard (docs/DESIGN_SYSTEM.md):
/// hero, access status, then Study, Practise and exams, and Community.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSw = ref.watch(languageProvider) == 'sw';
    final profile = ref.watch(userProfileProvider).valueOrNull;

    final rawName = profile?.fullName.trim();
    final firstName = (rawName != null && rawName.isNotEmpty && rawName != 'User')
        ? rawName.split(' ').first
        : (isSw ? 'Mwanafunzi' : 'Student');

    String t(String en, String sw) => isSw ? sw : en;

    final study = [
      FeatureCard(
        key: const Key('home-card-o-level'),
        icon: Icons.school_outlined,
        title: 'O-Level',
        description: t('Form 1–4 subjects', 'Masomo ya Kidato 1–4'),
        onTap: () {
          ref.read(selectedFormLevelProvider.notifier).state = 4;
          context.push('/subjects');
        },
      ),
      FeatureCard(
        key: const Key('home-card-a-level'),
        icon: Icons.menu_book_outlined,
        title: 'A-Level',
        description: t('Form 5–6 subjects', 'Masomo ya Kidato 5–6'),
        onTap: () {
          ref.read(selectedFormLevelProvider.notifier).state = 5;
          context.push('/subjects');
        },
      ),
      FeatureCard(
        key: const Key('home-card-syllabus'),
        icon: Icons.description_outlined,
        title: t('Syllabus', 'Mtaala'),
        description: t('Official NECTA and TIE syllabus', 'Mtaala rasmi wa NECTA na TIE'),
        onTap: () => context.push('/syllabus'),
      ),
    ];

    final practise = [
      FeatureCard(
        key: const Key('home-card-practicals'),
        icon: Icons.science_outlined,
        title: t('Practicals', 'Vitendo'),
        description: t('Virtual science labs', 'Maabara za sayansi mtandaoni'),
        onTap: () => context.push('/practicals'),
      ),
      FeatureCard(
        key: const Key('home-card-past-papers'),
        icon: Icons.assignment_turned_in_outlined,
        title: t('Past papers', 'Mitihani ya zamani'),
        description: t('Practise with previous exams', 'Jizoeze kwa mitihani iliyopita'),
        onTap: () => context.push('/quiz-exams?tab=practice'),
      ),
      FeatureCard(
        key: const Key('home-card-quiz-exams'),
        icon: Icons.fact_check_outlined,
        title: t('Quizzes and exams', 'Majaribio na mitihani'),
        description: t('Test what you have learned', 'Pima ulichojifunza'),
        onTap: () => context.push('/quiz-exams'),
      ),
    ];

    final community = [
      FeatureCard(
        key: const Key('home-card-forum'),
        icon: Icons.forum_outlined,
        title: t('Discussion forum', 'Jukwaa la majadiliano'),
        description: t('Ask and answer with other students', 'Uliza na ujibu pamoja na wanafunzi wengine'),
        onTap: () => context.push('/forum'),
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.m,
          AppSpacing.gutter,
          AppSpacing.bottomNavClearance,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(
                  name: firstName,
                  isSw: isSw,
                  onContinue: () => context.push('/subjects'),
                ),
                const SizedBox(height: AppSpacing.m),
                if (profile != null) ...[
                  _AccessStatusCard(profile: profile, isSw: isSw, formatDate: _formatDate),
                  const SizedBox(height: AppSpacing.l),
                ] else
                  const SizedBox(height: AppSpacing.m),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Phones keep the compact 2-column tiles; tablets get the
                    // grouped cards with descriptions, like the web's desktop view.
                    if (constraints.maxWidth < 600) {
                      return FeatureGrid(
                        cards: [...study, ...practise, ...community].map((c) => c.asCompact()).toList(),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(t('Study', 'Masomo')),
                        FeatureGrid(cards: study),
                        const SizedBox(height: AppSpacing.xl),
                        SectionLabel(t('Practise and exams', 'Mazoezi na mitihani')),
                        FeatureGrid(cards: practise),
                        const SizedBox(height: AppSpacing.xl),
                        SectionLabel(t('Community', 'Jumuiya')),
                        FeatureGrid(cards: community),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Greeting, headline, Continue learning and the same student photo as the web.
class _HeroCard extends StatelessWidget {
  final String name;
  final bool isSw;
  final VoidCallback onContinue;

  const _HeroCard({required this.name, required this.isSw, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.heroNavyDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final words = isSw ? ['Jifunze.', 'Jizoeze.', 'Fanikiwa.'] : ['Learn.', 'Practice.', 'Excel.'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final headlineSize = width < 340 ? 22.0 : (width < 420 ? 25.0 : 30.0);
        final photoWidth = (width * 0.42).clamp(120.0, 300.0);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? AppColors.heroBannerBgDark : AppColors.heroBannerBgLight,
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.l + 2, AppSpacing.l + 2, AppSpacing.s, AppSpacing.l + 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Flexible(
                              child: Text(
                                isSw ? 'Habari, $name' : 'Hi, $name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '${words[0]}\n${words[1]}\n', style: TextStyle(color: ink)),
                              TextSpan(text: words[2], style: TextStyle(color: accent)),
                            ]),
                            style: TextStyle(
                              fontSize: headlineSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.08,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        ElevatedButton(
                          key: const Key('home-continue-learning'),
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isSw ? 'Endelea kujifunza' : 'Continue learning',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: photoWidth,
                  child: Image.asset(
                    'assets/images/hero-student-v2.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.35, -0.3),
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Days left in the trial or subscription, with a status pill.
/// Taps through to the Subscription screen.
class _AccessStatusCard extends StatelessWidget {
  final UserProfile profile;
  final bool isSw;
  final String Function(DateTime?) formatDate;

  const _AccessStatusCard({required this.profile, required this.isSw, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaid = profile.isPremium;
    final isTrial = !isPaid && profile.isTrialActive;

    final int? days;
    final String title;
    final String? subtitle;
    final String pill;
    final Color tone;
    if (isPaid) {
      days = profile.subscriptionDaysRemaining;
      title = isSw ? 'Siku Zilizobaki' : 'Days Remaining';
      final end = formatDate(profile.subscriptionExpiresAt);
      subtitle = end.isEmpty ? null : (isSw ? 'Inaisha tarehe $end' : 'Expires $end');
      pill = 'Premium';
      tone = AppColors.success;
    } else if (isTrial) {
      days = profile.trialDaysLeft;
      title = isSw ? 'Siku Zilizobaki' : 'Days Remaining';
      final end = formatDate(profile.createdAt?.add(const Duration(days: 6)));
      subtitle = end.isEmpty ? null : (isSw ? 'Inaisha tarehe $end' : 'Expires $end');
      pill = isSw ? 'Jaribio la Bure' : 'Free Trial';
      tone = AppColors.warning;
    } else {
      days = null;
      title = isSw ? 'Usajili Umeisha' : 'Subscription Expired';
      subtitle = isSw ? 'Lipia TSh 2,500 kwa mwezi uendelee kusoma.' : 'Subscribe for TSh 2,500 a month to keep learning.';
      pill = isSw ? 'Umeisha' : 'Expired';
      tone = AppColors.error;
    }

    final titleColor = days == null ? AppColors.error : (isDark ? AppColors.primaryLight : AppColors.primary);

    final pillWidget = StatusPill(label: pill, color: tone);

    return CardSurface(
      key: const Key('home-access-status'),
      onTap: () => context.push('/subscription'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On narrow phones the pill moves under the title instead of beside it.
          final narrow = constraints.maxWidth < 300;
          return Row(
            children: [
              IconTile(days == null ? Icons.lock_clock_outlined : Icons.calendar_month_outlined, size: 42, danger: days == null),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (days != null)
                          Text('$days ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: titleColor)),
                        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: titleColor)),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                    if (narrow) ...[
                      const SizedBox(height: AppSpacing.s),
                      pillWidget,
                    ],
                  ],
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: AppSpacing.s),
                pillWidget,
              ],
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ],
          );
        },
      ),
    );
  }
}
