import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/card_surface.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controllers.dart';
import '../../../../core/utils/learning_language.dart';

/// Screen representing the Quiz & Exams Discovery Hub.
/// Faithfully mirrors React `QuizExams.jsx` functionality, tabs, filters, and access rules.
class QuizExamsScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const QuizExamsScreen({super.key, this.initialTab});

  @override
  ConsumerState<QuizExamsScreen> createState() => _QuizExamsScreenState();
}

class _QuizExamsScreenState extends ConsumerState<QuizExamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // "practice" is the old name of the past-papers tab.
        ref.read(quizTabFilterProvider.notifier).state =
            widget.initialTab == 'practice' ? 'past_paper' : widget.initialTab!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasAccess(UserProfile? profile) {
    if (profile == null) return false;
    return profile.isPremium || profile.isTrialActive;
  }

  void _handleStartQuiz(BuildContext context, QuizModel quiz, bool hasAccess, String lang) {
    if (!hasAccess) {
      _showPremiumModal(context, lang);
      return;
    }
    context.push('/quiz/${quiz.id}');
  }

  void _showPremiumModal(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'sw'
                  ? 'Majaribio Yanahitaji Usajili (Premium)'
                  : 'Subscription Required for Quizzes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              lang == 'sw'
                  ? 'Fanya mazoezi ya mitihani na majaribio yote kwa kulipia TSh 2,500 tu kwa mwezi.'
                  : 'Practice exams and quizzes require an active SomaSmart Premium subscription (TSh 2,500/month).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  lang == 'sw'
                      ? 'Lipia Usajili Sasa (TSh 2,500)'
                      : 'Activate Subscription (TSh 2,500)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                lang == 'sw' ? 'Baadaye' : 'Maybe Later',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = learningLanguage();
    final activeTab = ref.watch(quizTabFilterProvider);
    final selectedForm = ref.watch(quizFormFilterProvider);
    final quizzesAsync = ref.watch(quizListProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final hasAccess = _hasAccess(userProfileAsync.value);

    final tabs = [
      // Same types, labels and order as the web Quiz & exams page.
      {'key': 'topic', 'label_sw': 'Mada', 'label_en': 'Topic quizzes'},
      {'key': 'exam', 'label_sw': 'Mitihani ya masomo', 'label_en': 'Subject exams'},
      {'key': 'past_paper', 'label_sw': 'Mitihani ya zamani', 'label_en': 'Past papers'},
      {'key': 'timed', 'label_sw': 'Ya muda', 'label_en': 'Timed'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'sw' ? 'Majaribio na mitihani' : 'Quizzes and exams',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(quizListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header Info & Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'sw'
                          ? 'Pima ulichojifunza na ujiandae kwa mitihani ya NECTA.'
                          : 'Test what you have learned and prepare for NECTA exams.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search input
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: lang == 'sw'
                            ? 'Tafuta jaribio au somo'
                            : 'Search a quiz or subject',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Category Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tabs.map((tab) {
                          final isSelected = activeTab == tab['key'];
                          final label = lang == 'sw'
                              ? tab['label_sw'] as String
                              : tab['label_en'] as String;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              showCheckmark: false,
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                ref.read(quizTabFilterProvider.notifier).state =
                                    tab['key'] as String;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Form Level Filter Chips (All, Form 1..6)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(lang == 'sw' ? 'Vidato vyote' : 'All forms'),
                              showCheckmark: false,
                              selected: selectedForm == null,
                              onSelected: (_) {
                                ref.read(quizFormFilterProvider.notifier).state = null;
                              },
                            ),
                          ),
                          ...List.generate(6, (idx) {
                            final form = idx + 1;
                            final isSel = selectedForm == form;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(lang == 'sw' ? 'Kidato $form' : 'Form $form'),
                                showCheckmark: false,
                                selected: isSel,
                                onSelected: (_) {
                                  ref.read(quizFormFilterProvider.notifier).state =
                                      isSel ? null : form;
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quizzes List
            quizzesAsync.when(
              data: (allQuizzes) {
                // Each quiz's type is set by admins in the admin panel.
                var tabQuizzes = allQuizzes
                    .where((q) => q.isPublished && q.quizType == activeTab)
                    .toList();

                // Apply text search
                if (_searchQuery.isNotEmpty) {
                  tabQuizzes = tabQuizzes.where((q) {
                    final title = q.title.toLowerCase();
                    final subSw = (q.subjectNameSw ?? '').toLowerCase();
                    final subEn = (q.subjectNameEn ?? '').toLowerCase();
                    return title.contains(_searchQuery) ||
                        subSw.contains(_searchQuery) ||
                        subEn.contains(_searchQuery);
                  }).toList();
                }

                if (tabQuizzes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang == 'sw'
                                  ? 'Hakuna majaribio yaliyopatikana'
                                  : 'No quizzes found',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang == 'sw'
                                  ? 'Walimu wetu wanaongeza majaribio mapya ya mada hii hivi karibuni.'
                                  : 'Our teachers are adding new assessments for this topic soon.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final quiz = tabQuizzes[index];
                        return _buildQuizCard(
                          context,
                          quiz: quiz,
                          hasAccess: hasAccess,
                          lang: lang,
                          isDark: isDark,
                        );
                      },
                      childCount: tabQuizzes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang == 'sw'
                              ? 'Hitilafu katika kupakia majaribio'
                              : 'Failed to load quizzes',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(quizListProvider),
                          child: Text(lang == 'sw' ? 'Jaribu Tena' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    BuildContext context, {
    required QuizModel quiz,
    required bool hasAccess,
    required String lang,
    required bool isDark,
  }) {
    final sw = lang == 'sw';
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final level = switch (quiz.difficulty) {
      'easy' => sw ? 'Rahisi' : 'Easy',
      'hard' => sw ? 'Ngumu' : 'Hard',
      _ => sw ? 'Wastani' : 'Medium',
    };
    final count = quiz.totalQuestions;
    final hasSubject = quiz.subjectNameSw != null || quiz.subjectNameEn != null;

    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
          ),
        );

    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: secondary),
            const SizedBox(width: 5),
            Text(text, style: TextStyle(fontSize: 13, color: secondary)),
          ],
        );

    return CardSurface(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              tag(level),
              tag(sw ? 'Kidato cha ${quiz.formLevel}' : 'Form ${quiz.formLevel}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (hasSubject)
                meta(Icons.menu_book_outlined, quiz.getSubjectDisplayName(lang)),
              if (count > 0)
                meta(
                  Icons.help_outline_rounded,
                  sw
                      ? (count == 1 ? 'Swali 1' : 'Maswali $count')
                      : (count == 1 ? '1 question' : '$count questions'),
                ),
              if (quiz.timeLimitMinutes > 0)
                meta(
                  Icons.access_time_rounded,
                  sw ? 'Dakika ${quiz.timeLimitMinutes}' : '${quiz.timeLimitMinutes} min',
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _handleStartQuiz(context, quiz, hasAccess, lang),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sw ? 'Anza jaribio' : 'Start quiz',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    hasAccess ? Icons.arrow_forward_rounded : Icons.lock_rounded,
                    size: 16,
                    semanticLabel: hasAccess ? null : (sw ? 'Inahitaji Premium' : 'Needs Premium'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
