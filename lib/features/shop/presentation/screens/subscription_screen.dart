import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Subscription & Membership Plans Screen.
/// Faithfully reproduces React `Subscription.jsx` features and design.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int? _expandedFaqIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final profile = profileAsync.value;
    // Same rule as the home card and the server (UserProfile.accessAt).
    final access = profile?.access;
    final isPremium = access?.kind == AccessKind.paid;
    final isTrialActive = access?.kind == AccessKind.trial;
    final isExpired = access?.kind == AccessKind.expired;
    final daysLeft = isTrialActive ? access?.days ?? 0 : 0;
    final paidUntil = isPremium ? access?.endsAt : null;

    final faqItems = [
      _FaqItem(
        qSw: 'Je, nitalipiaje baada ya siku 6 za bure?',
        qEn: 'How do I pay after the 6-day free period?',
        aSw: 'Baada ya siku 6 za bure, unaweza kulipa TSh 2,500 kwa mwezi kupitia M-Pesa, Airtel Money au Tigo/Yas ili kuendelea kusoma bila kikomo.',
        aEn: 'After the 6-day free period, you can pay TSh 2,500 per month via M-Pesa, Airtel Money, or Tigo/Yas to continue studying with full access.',
      ),
      _FaqItem(
        qSw: 'Je, ninaweza kusoma notes bila mtandao (offline)?',
        qEn: 'Can I access content offline?',
        aSw: 'Wanafunzi wanaweza kufungua mada zilizopakuliwa nje ya mtandao baada ya kuzisoma mtandaoni mara moja.',
        aEn: 'Students can access downloaded topics offline after opening them once while connected to the internet.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'sw' ? 'Mipango ya Masomo' : 'Subscription Plans',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Text(
                lang == 'sw' ? 'Mipango ya Masomo' : 'Membership Plans',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lang == 'sw'
                    ? 'Chagua mpango unaokufaa kwa masomo ya Sekondari.'
                    : 'Choose an affordable plan for high school learning.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Plan 1: Free Trial Pass
              _PlanCard(
                isDark: isDark,
                borderColor: isTrialActive ? AppColors.warning : null,
                badgeText: isTrialActive
                    ? 'ACTIVE TRIAL'
                    : isExpired
                        ? 'TRIAL EXPIRED'
                        : 'COMPLETED',
                badgeColor: isTrialActive
                    ? AppColors.warning
                    : isExpired
                        ? AppColors.error
                        : AppColors.darkTextMuted,
                badgeBg: (isTrialActive
                        ? AppColors.warning
                        : isExpired
                            ? AppColors.error
                            : AppColors.darkTextMuted)
                    .withValues(alpha: 0.12),
                title: lang == 'sw' ? 'Majaribio ya Bure' : 'Free Trial Pass',
                price: '0',
                period: lang == 'sw' ? '/ 6 siku' : '/ 6 days',
                hint: lang == 'sw'
                    ? 'Jaribu huduma bila malipo'
                    : 'Evaluate platform features for free',
                benefits: [
                  lang == 'sw'
                      ? 'Siku 6 za masomo bure'
                      : '6 Days of full study access',
                  lang == 'sw'
                      ? 'Notes zote za O-Level na A-Level'
                      : 'All O-Level and A-Level summaries',
                  lang == 'sw'
                      ? 'Majaribio ya vitendo (Practicals)'
                      : 'Access practical lab sections',
                ],
                footerWidget: isTrialActive
                    ? _StatusBox(
                        icon: Icons.calendar_today_rounded,
                        text: lang == 'sw'
                            ? 'Zimebaki siku $daysLeft za majaribio'
                            : '$daysLeft trial days remaining',
                        color: AppColors.warning,
                        isDark: isDark,
                      )
                    : isExpired
                        ? _StatusBox(
                            icon: Icons.error_outline_rounded,
                            text: lang == 'sw'
                                ? 'Muda wa Majaribio Umeisha'
                                : 'Trial Period Expired',
                            color: AppColors.error,
                            isDark: isDark,
                          )
                        : _StatusBox(
                            icon: Icons.check_circle_outline_rounded,
                            text: lang == 'sw'
                                ? 'Muda wa Majaribio Ulikamilika'
                                : 'Trial Period Completed',
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            isDark: isDark,
                          ),
              ),
              const SizedBox(height: 16),

              // 3. Plan 2: Premium Monthly Pass
              _PlanCard(
                isDark: isDark,
                borderColor: isPremium ? AppColors.success : AppColors.primary,
                badgeText: isPremium ? 'ACTIVE PREMIUM' : 'RECOMMENDED',
                badgeColor: isPremium ? AppColors.success : AppColors.primary,
                badgeBg: (isPremium ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.12),
                title: 'Monthly Pass',
                price: '2,500',
                period: lang == 'sw' ? '/ mwezi' : '/ month',
                hint: lang == 'sw'
                    ? 'Bei nafuu ya kujisomea kila siku'
                    : 'Affordable learning for every student',
                benefits: [
                  lang == 'sw'
                      ? 'Notes zote za masomo 13 ya NECTA'
                      : 'All 13 NECTA subject summaries',
                  lang == 'sw'
                      ? 'Majaribio yote na mitihani ya NECTA'
                      : 'All quizzes & past exam papers',
                  lang == 'sw'
                      ? 'Majaribio ya Sayansi (Titration & Labs)'
                      : 'Science practical experiments',
                  lang == 'sw'
                      ? 'Msaada wa kusoma na AI (Ask Me)'
                      : 'AI study assistant (Ask Me)',
                  lang == 'sw'
                      ? 'Kusoma nje ya mtandao (Offline)'
                      : 'Offline study and revision access',
                ],
                footerWidget: isPremium
                    ? _StatusBox(
                        icon: Icons.verified_rounded,
                        text: paidUntil != null
                            ? '${lang == "sw" ? "Inaisha tarehe" : "Expires"} ${paidUntil.day}/${paidUntil.month}/${paidUntil.year}'
                            : (lang == 'sw' ? 'Uanachama Hai' : 'Active Membership'),
                        color: AppColors.success,
                        isDark: isDark,
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/payment');
                          },
                          icon: const Icon(Icons.credit_card_rounded, size: 18),
                          label: Text(
                            lang == 'sw' ? 'Lipia Sasa (TSh 2,500)' : 'Subscribe Now (TSh 2,500)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // 4. FAQ Accordion Section
              Text(
                lang == 'sw'
                    ? 'Maswali ya Mara kwa Mara (FAQs)'
                    : 'Frequently Asked Questions (FAQs)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqItems.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final item = faqItems[idx];
                  final isOpen = _expandedFaqIndex == idx;

                  return Material(
                    color: isDark ? AppColors.darkBgSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isOpen,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedFaqIndex = expanded ? idx : null;
                          });
                        },
                        title: Text(
                          lang == 'sw' ? item.qSw : item.qEn,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Text(
                              lang == 'sw' ? item.aSw : item.aEn,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool isDark;
  final Color? borderColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String price;
  final String period;
  final String hint;
  final List<String> benefits;
  final Widget footerWidget;

  const _PlanCard({
    required this.isDark,
    this.borderColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.price,
    required this.period,
    required this.hint,
    required this.benefits,
    required this.footerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Plan label + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'TSh ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                ' $period',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          const SizedBox(height: 14),

          // Benefits List
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),

          // Footer
          footerWidget,
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _StatusBox({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String qSw;
  final String qEn;
  final String aSw;
  final String aEn;

  const _FaqItem({
    required this.qSw,
    required this.qEn,
    required this.aSw,
    required this.aEn,
  });
}
