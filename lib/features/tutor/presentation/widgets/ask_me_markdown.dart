import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/soma_markdown.dart';

/// Renders rich academic Markdown with LaTeX math notation for Ask Me messages.
class AskMeMarkdown extends StatelessWidget {
  final String data;
  final bool isDark;
  final bool isUser;

  const AskMeMarkdown({
    super.key,
    required this.data,
    required this.isDark,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isUser
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final textSecondary = isUser
        ? Colors.white.withValues(alpha: 0.85)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final borderColor = isUser
        ? Colors.white.withValues(alpha: 0.2)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final codeBackground = isUser
        ? Colors.black.withValues(alpha: 0.2)
        : (isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer);

    return SomaMarkdown(
      data: data,
      selectable: true,
      errorColor: textColor,
      displayMathDecoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer),
        borderRadius: BorderRadius.circular(8),
      ),
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: textColor,
        ),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.3,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.3,
        ),
        h3: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.3,
        ),
        h4: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        listBullet: TextStyle(fontSize: 14, color: textColor),
        blockquote: TextStyle(fontSize: 13.5, color: textSecondary),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isUser ? Colors.white : AppColors.primary,
              width: 3,
            ),
          ),
          color: isUser
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.08),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          color: isUser
              ? Colors.white
              : (isDark ? const Color(0xFFE879F9) : const Color(0xFF9333EA)),
          backgroundColor: codeBackground,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        tableBorder: TableBorder.all(color: borderColor, width: 1),
        tableHead: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: textColor,
        ),
        tableBody: TextStyle(fontSize: 12.5, color: textColor),
        tableCellsPadding: const EdgeInsets.all(6),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        strong: TextStyle(fontWeight: FontWeight.w800, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textSecondary),
      ),
    );
  }
}
