import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/widgets/study_reminder_flow.dart';
import '../widgets/plant_cell_tablet_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final isSwahili = lang == 'sw';

    final quickAccessCards = [
      _QuickCardData(
        id: 'o-level',
        title: 'O-Level',
        icon: Icons.school_rounded,
        onTap: () {
          context.push('/subjects?level=o-level');
        },
      ),
      _QuickCardData(
        id: 'a-level',
        title: 'A-Level',
        icon: Icons.menu_book_rounded,
        onTap: () {
          context.push('/subjects?level=a-level');
        },
      ),
      _QuickCardData(
        id: 'practicals',
        title: isSwahili ? 'Vitendo' : 'Practicals',
        icon: Icons.science_rounded,
        onTap: () {
          context.push('/practicals');
        },
      ),
      _QuickCardData(
        id: 'syllabus',
        title: isSwahili ? 'Mtaala' : 'Syllabus',
        icon: Icons.description_outlined,
        onTap: () {
          context.push('/syllabus');
        },
      ),
      _QuickCardData(
        id: 'past-papers',
        title: isSwahili ? 'Mitihani ya zamani' : 'Past papers',
        icon: Icons.assignment_turned_in_outlined,
        onTap: () {
          context.push('/quiz-exams?tab=past_paper');
        },
      ),
      _QuickCardData(
        id: 'quiz-exams',
        title: isSwahili ? 'Majaribio na mitihani' : 'Quizzes and exams',
        icon: Icons.fact_check_outlined,
        onTap: () {
          context.push('/quiz-exams');
        },
      ),
      _QuickCardData(
        id: 'forum',
        title: isSwahili ? 'Jukwaa la majadiliano' : 'Discussion forum',
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () {
          context.push('/forum');
        },
      ),
    ];

    final userProfileAsync = ref.watch(userProfileProvider);
    final profile = userProfileAsync.valueOrNull;

    final rawName = profile?.fullName.trim();
    final firstName =
        (rawName != null && rawName.isNotEmpty && rawName != 'User')
        ? rawName.split(' ').first
        : (isSwahili ? 'Mwanafunzi' : 'Student');

    // One rule for every screen (UserProfile.accessAt = the server's
    // has_active_subscription). No card until the profile has loaded, so a
    // slow or failed load never shows "Usajili Umeisha".
    final access = profile?.access;

    int? daysCount;
    String statusTitle = '';
    String? statusSubtext;
    String badgeLabel = '';
    Color badgeTextColor = AppColors.error;
    Color badgeBgColor = Colors.transparent;
    Color badgeDotColor = AppColors.error;

    if (access != null && access.kind != AccessKind.expired) {
      daysCount = access.days;
      statusTitle = daysCount != null
          ? (isSwahili ? 'Siku Zilizobaki' : 'Days Remaining')
          : (isSwahili ? 'Ufikiaji Kamili' : 'Full Access');
      final expiryStr = _formatDate(access.endsAt);
      statusSubtext = expiryStr.isNotEmpty
          ? (isSwahili ? 'Inaisha tarehe $expiryStr' : 'Expires $expiryStr')
          : null;
      if (access.kind == AccessKind.paid) {
        badgeLabel = 'Premium';
        badgeTextColor = isDark ? const Color(0xFF2FA866) : AppColors.success;
        badgeBgColor = AppColors.success.withValues(alpha: isDark ? 0.16 : 0.12);
        badgeDotColor = badgeTextColor;
      } else {
        badgeLabel = isSwahili ? 'Jaribio la Bure' : 'Free Trial';
        badgeTextColor = isDark ? const Color(0xFFE0AA4F) : AppColors.warning;
        badgeBgColor = isDark
            ? AppColors.brandGold.withValues(alpha: 0.14)
            : AppColors.brandGoldSoft;
        badgeDotColor = isDark ? const Color(0xFFE0AA4F) : AppColors.brandGold;
      }
    } else if (access != null) {
      statusTitle = isSwahili ? 'Usajili Umeisha' : 'Subscription Expired';
      statusSubtext = isSwahili
          ? 'Boresha uendelee kusoma'
          : 'Upgrade to continue';
      badgeLabel = isSwahili ? 'Umeisha' : 'Expired';
      badgeBgColor = AppColors.error.withValues(alpha: isDark ? 0.16 : 0.10);
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 90, // Safe clearance for bottom nav & floating Ask Me
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 1. HERO CARD =====
            _DashboardHeroBanner(
              isDark: isDark,
              displayName: firstName,
              isSwahili: isSwahili,
              onContinue: () {
                context.push('/subjects');
              },
            ),
            const SizedBox(height: 12),

            // Daily study reminder offer (from the second day of use; hidden once answered).
            const StudyReminderPrompt(),

            // ===== 2. SUBSCRIPTION STATUS CARD =====
            if (access != null) ...[
            InkWell(
              onTap: () => context.push('/subscription'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Calendar icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryLight.withValues(alpha: 0.16)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 24,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Main remaining days & expiry text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wraps instead of overflowing on very narrow phones.
                          Wrap(
                            children: [
                              if (daysCount != null) ...[
                                Text(
                                  '$daysCount ',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                              Text(
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          if (statusSubtext != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              statusSubtext,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Premium badge + Chevron
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: badgeDotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ],

            // ===== 3. FEATURE GRID (2-Column) =====
            // ===== 3. FEATURE GRID: two per row, the forum tile across the full width =====
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final tileHeight = (constraints.maxWidth - spacing) / 2 / 2.25;
                final gridCards = quickAccessCards
                    .where((c) => c.id != 'forum')
                    .toList();
                final forum = quickAccessCards.firstWhere(
                  (c) => c.id == 'forum',
                );
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridCards.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: 2.25,
                          ),
                      itemBuilder: (ctx, index) =>
                          _buildTile(gridCards[index], isDark),
                    ),
                    const SizedBox(height: spacing),
                    SizedBox(
                      height: tileHeight,
                      width: double.infinity,
                      child: _buildTile(forum, isDark),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One quick-access tile (same size and style as before).
Widget _buildTile(_QuickCardData card, bool isDark) {
  return InkWell(
    key: Key('home-card-${card.id}'),
    onTap: card.onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              card.title,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 15,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
          ),
        ],
      ),
    ),
  );
}

class _QuickCardData {
  final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCardData({
    required this.id,
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// Compact, clean Hero Card matching the reference design:
/// - "Hi, [name]" with navy circular avatar
/// - "Learn." on first line
/// - "Practice, Excel." on second line ("Excel." in Royal Scholar Blue #0058BE)
/// - "Continue Learning →" pill button
/// - High-clarity academic tablet illustration displaying plant cell diagram on right
class _DashboardHeroBanner extends StatelessWidget {
  final bool isDark;
  final String displayName;
  final bool isSwahili;
  final VoidCallback onContinue;

  const _DashboardHeroBanner({
    required this.isDark,
    required this.displayName,
    required this.isSwahili,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F1D32) : const Color(0xFFEDF5FF);
    final borderColor = isDark
        ? const Color(0xFF1E3A5F)
        : const Color(0xFFD0E2FF);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Responsive tablet width allocation (~44% of width clamped)
        final tabletWidth = (totalWidth * 0.44).clamp(135.0, 185.0);
        final initial = displayName.isNotEmpty
            ? displayName[0].toLowerCase()
            : 'a';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content: Greeting, Headline, CTA button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hi, [Name] Row with initial avatar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0B1A36), // Navy Circle
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isSwahili
                                ? 'Habari, $displayName'
                                : 'Hi, $displayName',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // "Learn."
                    Text(
                      isSwahili ? 'Jifunze.' : 'Learn.',
                      style: TextStyle(
                        fontSize: totalWidth < 360 ? 22 : 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.05,
                        color: isDark ? Colors.white : const Color(0xFF0B1A36),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // "Practice, Excel."
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: totalWidth < 360 ? 22 : 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.05,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: isSwahili ? 'Jizoeze, ' : 'Practice, ',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0B1A36),
                            ),
                          ),
                          TextSpan(
                            text: isSwahili ? 'Fanikiwa.' : 'Excel.',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // "Continue Learning →" CTA Button
                    ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.primary
                            : const Color(0xFF0B1A36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isSwahili
                                    ? 'Endelea Kujifunza'
                                    : 'Continue Learning',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_rounded, size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right Content: Tablet illustration with plant cell diagram
              SizedBox(
                width: tabletWidth,
                child: const PlantCellTabletWidget(),
              ),
            ],
          ),
        );
      },
    );
  }
}
