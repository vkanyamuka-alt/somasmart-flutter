import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../services/announcements_service.dart';
import '../theme/app_colors.dart';

/// Bottom sheet listing the announcements admins post in the admin panel
/// (the same list as the web app's bell). Opening it marks them as read.
class NotificationDrawer extends ConsumerStatefulWidget {
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
  ConsumerState<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends ConsumerState<NotificationDrawer> {
  // What was unread when the sheet opened, so the dots stay visible while it is open.
  late final Set<String> _readAtOpen = ref.read(readAnnouncementsProvider);
  bool _marked = false;

  String _date(DateTime? d, bool isSw) {
    if (d == null) return '';
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const sw = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    final local = d.toLocal();
    return '${local.day} ${(isSw ? sw : en)[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSw = ref.watch(languageProvider) == 'sw';
    final async = ref.watch(announcementsProvider);
    final items = async.valueOrNull ?? const <Announcement>[];
    final unread = items.where((a) => !_readAtOpen.contains(a.id)).length;

    if (!_marked && items.isNotEmpty) {
      _marked = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(readAnnouncementsProvider.notifier).markAll(items.map((a) => a.id)),
      );
    }

    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  isSw ? 'Matangazo' : 'Announcements',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      isSw ? '$unread mpya' : '$unread new',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isSw ? 'Funga' : 'Close', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined, size: 32, color: muted),
                            const SizedBox(height: 8),
                            Text(
                              isSw ? 'Hakuna matangazo kwa sasa' : 'No announcements yet',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          final isUnread = !_readAtOpen.contains(item.id);
                          final high = item.priority == 'high';
                          final tone = high ? AppColors.brandGold : (isDark ? AppColors.primaryLight : AppColors.primary);
                          return Container(
                            key: Key('announcement-${item.id}'),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05)
                                  : (isDark ? AppColors.darkBgBase : AppColors.lightBgContainer),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isUnread
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: tone.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(high ? Icons.priority_high_rounded : Icons.campaign_outlined, color: tone, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.content,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 12, color: muted),
                                          const SizedBox(width: 4),
                                          Text(_date(item.createdAt, isSw), style: TextStyle(fontSize: 10.5, color: muted)),
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
