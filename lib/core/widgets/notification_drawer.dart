import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../theme/app_colors.dart';

/// Modal bottom sheet for notifications & platform updates matching React `Updates.jsx` & `ClientShell.jsx`.
class NotificationDrawer extends ConsumerWidget {
  const NotificationDrawer({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationDrawer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);

    final notifications = [
      _NotifItemData(
        titleEn: 'Introducing Collapsible Sidebar & Native Sharing',
        titleSw: 'Kuanzisha Sidebar Mpya Inayokunjika na Kushare Rahisi',
        version: 'v2.1.0',
        dateEn: 'Jul 7, 2026',
        dateSw: '7 Jul, 2026',
        type: 'feature',
        descEn:
            "We've rebuilt the navigation system from the ground up! Enjoy collapsible left sidebar, native mobile sharing, direct language toggle, and dedicated notifications settings.",
        descSw:
            'Tumeboresha mfumo wa usogezaji kabisa! Furahia jopo la pembeni (sidebar) linalokunjika, uwezo wa kushare kirahisi, kubadili lugha moja kwa moja, na mipangilio mipya ya notification.',
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.primaryLight,
        isUnread: true,
      ),
      _NotifItemData(
        titleEn: 'SomaSmart 6-Day Access Policy Update',
        titleSw: 'Marekebisho ya Mfumo wa Siku 6 za Majaribio',
        version: 'v2.0.2',
        dateEn: 'Jul 6, 2026',
        dateSw: '6 Jul, 2026',
        type: 'maintenance',
        descEn:
            'All newly created student accounts now receive 6 days of full free trial access. After this, a TZS 2,500 subscription is requested to unlock all summaries and quizzes.',
        descSw:
            'Wanafunzi wote wapya watapata siku 6 za matumizi ya bure. Baada ya hapo, malipo ya TZS 2,500 yanahitajika ili kuendelea kusoma summaries na kufanya majaribio.',
        icon: Icons.memory_rounded,
        iconColor: AppColors.accentGold,
        isUnread: true,
      ),
      _NotifItemData(
        titleEn: 'Offline Mode Performance Fixes',
        titleSw: 'Maboresho ya Matumizi Nje ya Mtandao (Offline Mode)',
        version: 'v2.0.1',
        dateEn: 'Jul 1, 2026',
        dateSw: '1 Jul, 2026',
        type: 'fix',
        descEn:
            'Resolved rendering issues for offline cached topics and notes. Downloaded notes can now be accessed instantaneously without any network lag.',
        descSw:
            'Tumerekebisha changamoto za kufungua summaries zilizopakuliwa offline. Sasa unaweza kusoma notes zako ulizodownload bila usumbufu wowote wa mtandao.',
        icon: Icons.verified_user_rounded,
        iconColor: AppColors.success,
        isUnread: false,
      ),
      _NotifItemData(
        titleEn: 'SomaSmart Platform Release',
        titleSw: 'Uzinduzi wa SomaSmart Platform',
        version: 'v2.0.0',
        dateEn: 'Jun 25, 2026',
        dateSw: '25 Jun, 2026',
        type: 'announcement',
        descEn:
            "Welcome to SomaSmart! Study anytime and anywhere using our adaptive NECTA syllabus quiz engine and study summaries prepared by Tanzania's best tutors.",
        descSw:
            'Karibu SomaSmart! Soma wakati wowote na mahali popote kwa kutumia mfumo wetu unaojirekebisha wa quizzes za syllabus ya NECTA na summaries zilizoandaliwa na wataalamu hodari.',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.accentPurple,
        isUnread: false,
      ),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      lang == 'sw'
                          ? 'Marekebisho na Taarifa'
                          : 'Platform Updates & Alerts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        lang == 'sw' ? '2 mpya' : '2 new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    lang == 'sw' ? 'Funga' : 'Close',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final item = notifications[index];
                final title = lang == 'sw' ? item.titleSw : item.titleEn;
                final desc = lang == 'sw' ? item.descSw : item.descEn;
                final date = lang == 'sw' ? item.dateSw : item.dateEn;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.isUnread
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.05))
                        : (isDark
                            ? AppColors.darkBgBase
                            : AppColors.lightBgContainer),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isUnread
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.iconColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type.toUpperCase(),
                                    style: TextStyle(
                                      color: item.iconColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.version,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                const Spacer(),
                                if (item.isUnread)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: item.isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItemData {
  final String titleEn;
  final String titleSw;
  final String version;
  final String dateEn;
  final String dateSw;
  final String type;
  final String descEn;
  final String descSw;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  const _NotifItemData({
    required this.titleEn,
    required this.titleSw,
    required this.version,
    required this.dateEn,
    required this.dateSw,
    required this.type,
    required this.descEn,
    required this.descSw,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
  });
}
