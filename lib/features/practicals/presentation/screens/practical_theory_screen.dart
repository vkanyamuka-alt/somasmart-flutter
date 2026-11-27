import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/soma_markdown.dart';
import '../../data/repositories/practical_repository_impl.dart';
import 'practical_mode_screen.dart';

/// A practical's theory (`assets/lab_theory/<id>.md`, the same files as the
/// website's src/lab/theory/), read like a note: aim, background, equations,
/// apparatus, procedure and precautions.
class PracticalTheoryScreen extends ConsumerStatefulWidget {
  final String practicalId;

  const PracticalTheoryScreen({super.key, required this.practicalId});

  /// The theory text, or null when the practical has none yet.
  static Future<String?> load(String practicalId, {AssetBundle? bundle}) async {
    try {
      return await (bundle ?? rootBundle).loadString('assets/lab_theory/$practicalId.md');
    } catch (_) {
      return null;
    }
  }

  @override
  ConsumerState<PracticalTheoryScreen> createState() => _PracticalTheoryScreenState();
}

class _PracticalTheoryScreenState extends ConsumerState<PracticalTheoryScreen> {
  // Loaded once, not on every rebuild.
  late final Future<String?> _theory = PracticalTheoryScreen.load(widget.practicalId);

  @override
  Widget build(BuildContext context) {
    final practicalId = widget.practicalId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final practical = ref.watch(practicalRepositoryProvider).getPracticalById(practicalId);
    final title = practical?.title ?? 'Practical';
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/practical/mode-selection/$practicalId'),
        ),
      ),
      body: FutureBuilder<String?>(
        future: _theory,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final theory = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text('Theory', style: TextStyle(fontSize: 13.5, color: secondary)),
              const SizedBox(height: 4),
              if (theory == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('The theory for this practical is being written.', style: TextStyle(color: secondary)),
                )
              else
                SomaMarkdown(
                  data: theory,
                  errorColor: isDark ? Colors.amber : Colors.deepOrange,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 15.5, height: 1.65, color: text),
                    h2: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: text, height: 1.3),
                    h2Padding: const EdgeInsets.only(top: 20, bottom: 6),
                    listBullet: TextStyle(fontSize: 15.5, color: text),
                    strong: TextStyle(fontWeight: FontWeight.w800, color: text),
                    tableBorder: TableBorder.all(color: border),
                    tableHead: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text),
                    tableBody: TextStyle(fontSize: 14, color: text),
                    tableCellsPadding: const EdgeInsets.all(8),
                  ),
                ),
              if (practical != null && practical.hasSimulationEngine) ...[
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => showPracticalModeSheet(context, practicalId),
                    icon: const Icon(Icons.science_outlined, size: 20),
                    label: const Text('Open practical', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
