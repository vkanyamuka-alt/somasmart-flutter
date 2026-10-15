import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somasmart_flutter/core/theme/app_colors.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/shop/data/repositories/shop_repository.dart';
import 'package:somasmart_flutter/features/shop/domain/models/shop_models.dart';
import 'package:somasmart_flutter/features/shop/presentation/controllers/shop_controller.dart';

/// Book Shop & Educational Materials Screen (Tab 1).
/// Dedicated solely to physical/digital learning products (books, guides, materials).
/// The subscription service is kept strictly separate in SubscriptionScreen.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final itemsAsync = ref.watch(shopItemsProvider);

    final categories = [
      {'id': 'All', 'label_sw': 'Vyote', 'label_en': 'All'},
      {'id': 'Books', 'label_sw': 'Vitabu', 'label_en': 'Books'},
      {'id': 'Past Papers', 'label_sw': 'Mitihani', 'label_en': 'Past Papers'},
      {'id': 'Pamphlets', 'label_sw': 'Vipeperushi', 'label_en': 'Pamphlets'},
      {'id': 'Lab Guides', 'label_sw': 'Miongozo ya Maabara', 'label_en': 'Lab Guides'},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgBase,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shopItemsProvider);
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Shop Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'sw' ? 'Duka la Vitabu' : 'Book Shop',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang == 'sw'
                                ? 'Vitabu na vifaa vya kujisomea'
                                : 'Educational books & learning materials',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Catalog Content or Empty State
                itemsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            lang == 'sw' ? 'Hitilafu ya kupakia bidhaa' : 'Error loading shop items',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(shopItemsProvider),
                            child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) {
                    // Empty State when no products are in the catalog
                    if (items.isEmpty) {
                      return _buildEmptyState(context, isDark: isDark, lang: lang);
                    }

                    // Active catalog with real products (Future-Ready)
                    final filtered = items.filter((item) {
                      final matchesCategory = _selectedCategory == 'All' ||
                          item.category.toLowerCase() == _selectedCategory.toLowerCase();
                      final title = item.getTitle(lang).toLowerCase();
                      final desc = item.getDesc(lang).toLowerCase();
                      final matchesSearch = _searchQuery.isEmpty ||
                          title.contains(_searchQuery) ||
                          desc.contains(_searchQuery);
                      return matchesCategory && matchesSearch;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBgSurface : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim().toLowerCase();
                                    });
                                  },
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: lang == 'sw'
                                        ? 'Tafuta vitabu, miongozo, vipeperushi...'
                                        : 'Search books, guides, pamphlets...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final id = cat['id']!;
                              final isSelected = _selectedCategory == id;
                              final label = lang == 'sw' ? cat['label_sw']! : cat['label_en']!;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkBgSurface : AppColors.lightBgContainer),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Filtered empty check
                        if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    lang == 'sw'
                                        ? 'Hakuna matokeo ya utafutaji.'
                                        : 'No matching items found.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _ShopItemCard(
                                item: item,
                                lang: lang,
                                isDark: isDark,
                                onPurchase: () async {
                                  final user = profileAsync.value;
                                  if (user == null || user.id == 'guest') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          lang == 'sw'
                                              ? 'Tafadhali ingia kwenye akaunti ili kununua.'
                                              : 'Please log in to purchase.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final repo = ref.read(shopRepositoryProvider);
                                  final ok = await repo.purchaseShopItem(
                                    userId: user.id,
                                    itemId: item.id,
                                    amount: item.price,
                                  );

                                  if (ok) {
                                    ref.invalidate(shopItemsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            lang == 'sw'
                                                ? 'Umenunua kikamilifu: ${item.getTitle(lang)}'
                                                : 'Purchase successful: ${item.getTitle(lang)}',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
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

  /// Clean, professional empty state when no products are available for sale.
  Widget _buildEmptyState(
    BuildContext context, {
    required bool isDark,
    required String lang,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48, bottom: 32, left: 16, right: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                lang == 'sw' ? 'Hakuna bidhaa kwa sasa' : 'No products available yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                lang == 'sw'
                    ? 'Bidhaa na vifaa vya masomo zitaonekana hapa zitakapopatikana.'
                    : 'Learning products will appear here when available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final String lang;
  final bool isDark;
  final VoidCallback onPurchase;

  const _ShopItemCard({
    required this.item,
    required this.lang,
    required this.isDark,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.getTitle(lang);
    final desc = item.getDesc(lang);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                color: isDark ? AppColors.darkBgBase : const Color(0xFFEFF6FF),
                child: item.coverImage.isNotEmpty
                    ? Image.network(
                        item.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) => const Center(
                          child: Icon(Icons.book_rounded, size: 36, color: AppColors.primary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.menu_book_rounded, size: 36, color: AppColors.primary),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),

          // Description
          Text(
            desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Price and Buy CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.formattedPrice,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (item.isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        lang == 'sw' ? 'Iko Wazi' : 'Unlocked',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: onPurchase,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lang == 'sw' ? 'Nunua' : 'Buy',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _IterableFilter<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    return where(test).toList();
  }
}
