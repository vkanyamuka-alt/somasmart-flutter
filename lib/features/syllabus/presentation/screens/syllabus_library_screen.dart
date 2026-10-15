import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/syllabus_document_model.dart';
import '../controllers/syllabus_library_controller.dart';

// ─── Subject colour map (mirrors React getCurriculumThumbnailSvg) ─────────────
const Map<String, Color> _subjectColors = {
  'physics': Color(0xFF0284C7),
  'mathematics': Color(0xFF2563EB),
  'chemistry': Color(0xFF7C3AED),
  'biology': Color(0xFF059669),
  'geography': Color(0xFFD97706),
  'history': Color(0xFFB45309),
  'civics': Color(0xFF4B5563),
  'english language': Color(0xFFDC2626),
  'kiswahili': Color(0xFF0891B2),
  'economics': Color(0xFF0D9488),
  'commerce': Color(0xFFEA580C),
  'basic applied mathematics': Color(0xFF4338CA),
  'general studies': Color(0xFF6366F1),
};

Color _subjectColor(String subjectName) {
  return _subjectColors[subjectName.toLowerCase()] ?? AppColors.primary;
}

// ─── Custom Book Cover Painter ────────────────────────────────────────────────

class _BookCoverPainter extends CustomPainter {
  final Color baseColor;
  final String subjectName;
  final String coverage;
  final String year;

  const _BookCoverPainter({
    required this.baseColor,
    required this.subjectName,
    required this.coverage,
    required this.year,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Gradient background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(10),
    );
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [baseColor, const Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Spine strip
    final spinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.07, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.07, h), spinePaint);

    // 3. "CURRICULUM DOCUMENT" header badge
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.11, h * 0.07, w * 0.77, h * 0.08),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // 4. Tanzania emblem circle
    final circleCentre = Offset(w / 2, h * 0.30);
    final circleR = w * 0.18;
    canvas.drawCircle(
      circleCentre,
      circleR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      circleCentre,
      circleR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 5. Divider line
    canvas.drawLine(
      Offset(w * 0.19, h * 0.63),
      Offset(w * 0.81, h * 0.63),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1.2,
    );

    // 6. Coverage badge
    final covRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.68, w * 0.56, h * 0.09),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      covRect,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(_BookCoverPainter old) =>
      old.baseColor != baseColor ||
      old.subjectName != subjectName ||
      old.coverage != coverage ||
      old.year != year;
}

// ─── Book Cover Widget ────────────────────────────────────────────────────────

class _SyllabusBookCover extends StatelessWidget {
  final SyllabusDocument doc;
  final double width;
  final double height;

  const _SyllabusBookCover({
    required this.doc,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(doc.subjectName);
    final coverage = doc.coverage ?? 'Form I – IV';
    final year = doc.academicYear ?? '2023';

    // If Supabase has a real thumbnail, prefer it
    if (doc.thumbnailUrl != null && doc.thumbnailUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          doc.thumbnailUrl!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _buildPaintedCover(color, coverage, year),
        ),
      );
    }

    return _buildPaintedCover(color, coverage, year);
  }

  Widget _buildPaintedCover(Color color, String coverage, String year) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Painted background
          CustomPaint(
            size: Size(width, height),
            painter: _BookCoverPainter(
              baseColor: color,
              subjectName: doc.subjectName,
              coverage: coverage,
              year: year,
            ),
          ),
          // Text overlays
          Positioned.fill(
            child: Column(
              children: [
                // Header label
                SizedBox(height: height * 0.09),
                Text(
                  'CURRICULUM DOCUMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.065,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Emblem area — flag emoji
                SizedBox(height: height * 0.03),
                Text(
                  '🇹🇿',
                  style: TextStyle(fontSize: width * 0.14),
                ),

                SizedBox(height: height * 0.01),
                Text(
                  'TANZANIA INSTITUTE OF EDUCATION',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: width * 0.048,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: height * 0.03),

                // Subject name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                  child: Text(
                    doc.subjectName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.12,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'SYLLABUS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: width * 0.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: height * 0.05),

                // Coverage badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.08,
                    vertical: height * 0.016,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    coverage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.075,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                // Bottom year
                Padding(
                  padding: EdgeInsets.only(bottom: height * 0.04),
                  child: Text(
                    'Official Curriculum • $year',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class SyllabusLibraryScreen extends ConsumerStatefulWidget {
  const SyllabusLibraryScreen({super.key});

  @override
  ConsumerState<SyllabusLibraryScreen> createState() =>
      _SyllabusLibraryScreenState();
}

class _SyllabusLibraryScreenState
    extends ConsumerState<SyllabusLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset state on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syllabusSearchQueryProvider.notifier).state = '';
      _searchCtrl.clear();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = ref.watch(syllabusLevelProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgBase : AppColors.lightBgBase,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maktaba ya Mitaala',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Syllabus Library',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Toolbar: level tabs + search ─────────────────────────────────
          Container(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Level selector tabs
                Row(
                  children: [
                    _LevelTab(
                      label: 'O-Level',
                      subtitle: 'Form I–IV',
                      icon: Icons.school_rounded,
                      isSelected: level == 'o-level',
                      onTap: () {
                        ref.read(syllabusLevelProvider.notifier).state =
                            'o-level';
                        ref
                            .read(syllabusSearchQueryProvider.notifier)
                            .state = '';
                        _searchCtrl.clear();
                      },
                    ),
                    const SizedBox(width: 10),
                    _LevelTab(
                      label: 'A-Level',
                      subtitle: 'Form V–VI',
                      icon: Icons.menu_book_rounded,
                      isSelected: level == 'a-level',
                      onTap: () {
                        ref.read(syllabusLevelProvider.notifier).state =
                            'a-level';
                        ref
                            .read(syllabusSearchQueryProvider.notifier)
                            .state = '';
                        _searchCtrl.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(syllabusSearchQueryProvider.notifier).state = v,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tafuta somo, mwaka... / Search subject, year…',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    suffixIcon: ref.watch(syllabusSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(syllabusSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBgContainer
                        : AppColors.lightBgContainer,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Document grid ─────────────────────────────────────────────────
          Expanded(
            child: _SyllabusDocumentGrid(),
          ),
        ],
      ),
    );
  }
}

// ─── Level Tab widget ─────────────────────────────────────────────────────────

class _LevelTab extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTab({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBgContainer
                    : AppColors.lightBgContainer),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Document Grid ────────────────────────────────────────────────────────────

class _SyllabusDocumentGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docsAsync = ref.watch(currentSyllabusDocsProvider);
    final level = ref.watch(syllabusLevelProvider);
    final query = ref.watch(syllabusSearchQueryProvider);

    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Hitilafu imetokea / Error loading: $e',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return _EmptyState(level: level, query: query);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.62,
          ),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _SyllabusCard(doc: docs[i]),
        );
      },
    );
  }
}

// ─── Syllabus Card ────────────────────────────────────────────────────────────

class _SyllabusCard extends StatelessWidget {
  final SyllabusDocument doc;

  const _SyllabusCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDocumentSheet(context, doc),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Book cover ──────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: isDark
                        ? AppColors.darkBgBase
                        : AppColors.lightBgContainer,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      child: _SyllabusBookCover(
                        doc: doc,
                        width: 94,
                        height: 136,
                      ),
                    ),
                  ),
                ),
                // Verified badge
                if (doc.isVerified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEB10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Card body ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              doc.coverage ?? 'Form I – IV',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doc.academicYear ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      doc.subjectName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // View button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showDocumentSheet(context, doc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Tazama Mtaala',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Document Details Bottom Sheet ───────────────────────────────────────────

void _showDocumentSheet(BuildContext context, SyllabusDocument doc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DocumentDetailsSheet(doc: doc),
  );
}

class _DocumentDetailsSheet extends ConsumerWidget {
  final SyllabusDocument doc;

  const _DocumentDetailsSheet({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prevAsync = ref.watch(previousVersionsProvider(doc));

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Header row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Taarifa za Mtaala',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Top banner: thumbnail + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SyllabusBookCover(
                          doc: doc,
                          width: 100,
                          height: 134,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (doc.coverage != null)
                                    _Chip(
                                      label: doc.coverage!,
                                      color: AppColors.primary,
                                    ),
                                  if (doc.academicYear != null)
                                    _Chip(
                                      label: doc.academicYear!,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (doc.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 13,
                                          color: AppColors.success),
                                      SizedBox(width: 5),
                                      Text(
                                        '✓ Nyaraka Iliyothibitishwa',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Metadata grid
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBgContainer
                                .withValues(alpha: 0.6)
                            : AppColors.lightBgContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _MetaRow(
                            icon: Icons.business_rounded,
                            label: 'Source',
                            value: doc.sourceOrganization ??
                                'Tanzania Institute of Education (TIE)',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Academic Year / Version',
                            value:
                                '${doc.academicYear ?? '—'} (${doc.version ?? 'Current'})',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.download_rounded,
                            label: 'Download Permission',
                            value: doc.downloadAllowed
                                ? 'Allowed'
                                : 'View Only (No Download)',
                            isDark: isDark,
                            valueColor: doc.downloadAllowed
                                ? AppColors.success
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Previous versions
                    prevAsync.whenOrNull(
                      data: (prevDocs) {
                        if (prevDocs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history_rounded,
                                    size: 14,
                                    color: AppColors.lightTextMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Matoleo Yaliyopita / Previous Versions',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...prevDocs.map(
                              (prev) => GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showDocumentSheet(context, prev);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkBgContainer
                                        : AppColors.lightBgContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${prev.title} (${prev.academicYear ?? ''})',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: AppColors.lightTextMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ) ??
                        const SizedBox.shrink(),

                    // ── Action buttons
                    // 1. View PDF
                    if (doc.fileUrl != null)
                      _ActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'Fungua Mtaala (View PDF)',
                        isPrimary: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUrl(context, doc.fileUrl!);
                        },
                      ),

                    if (doc.fileUrl != null) const SizedBox(height: 10),

                    // 2. Download
                    if (doc.downloadAllowed && doc.fileUrl != null)
                      _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Pakua PDF (Download)',
                        isPrimary: false,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUrl(context, doc.fileUrl!);
                        },
                      ),

                    if (doc.downloadAllowed && doc.fileUrl != null)
                      const SizedBox(height: 10),

                    // 3. Official source
                    if (doc.officialSourceUrl != null)
                      _ActionButton(
                        icon: Icons.open_in_new_rounded,
                        label: 'Fungua Tovuti Rasmi (TIE) ↗',
                        isPrimary: false,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUrl(context, doc.officialSourceUrl!);
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchUrl(BuildContext context, String url) {
    // Uses a SnackBar since url_launcher is not yet in pubspec.
    // Will be upgraded to url_launcher in the url_launcher addition step.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inafungua: $url'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: isPrimary
            ? ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              )
            : ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkBgContainer
                    : AppColors.lightBgContainer,
                foregroundColor: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                elevation: 0,
              ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String level;
  final String query;

  const _EmptyState({required this.level, required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isALevel = level == 'a-level';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.description_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isALevel
                  ? 'Hakuna mtaala kwa A-Level'
                  : 'Hakuna nyaraka za mtaala',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'Jaribu kubadilisha neno la utafutaji wako.'
                  : 'Nyaraka rasmi za mitaala zitawekwa hapa hivi karibuni.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
