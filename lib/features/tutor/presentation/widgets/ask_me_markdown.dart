import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/theme/app_colors.dart';

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

    return MarkdownBody(
      data: data,
      selectable: true,
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
      builders: {
        'math': _AskMeMathBuilder(isDark: isDark, isUser: isUser, display: false),
        'mathBlock': _AskMeMathBuilder(isDark: isDark, isUser: isUser, display: true),
      },
      inlineSyntaxes: [_DollarInlineMathSyntax()],
      blockSyntaxes: [_DollarDisplayMathSyntax()],
    );
  }
}

class _AskMeMathBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final bool isUser;
  final bool display;

  _AskMeMathBuilder({
    required this.isDark,
    required this.isUser,
    required this.display,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final latex = element.textContent.trim();
    final mathColor = isUser
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    try {
      if (display) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUser
                ? Colors.white.withValues(alpha: 0.1)
                : (isDark ? AppColors.darkBgContainer : AppColors.lightBgContainer),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              latex,
              mathStyle: MathStyle.display,
              textStyle: TextStyle(
                fontSize: 15,
                color: mathColor,
              ),
              onErrorFallback: (err) => Text(
                latex,
                style: TextStyle(fontFamily: 'monospace', color: mathColor, fontSize: 13),
              ),
            ),
          ),
        );
      } else {
        return Math.tex(
          latex,
          mathStyle: MathStyle.text,
          textStyle: TextStyle(
            fontSize: 14,
            color: mathColor,
          ),
          onErrorFallback: (err) => Text(
            latex,
            style: TextStyle(fontFamily: 'monospace', color: mathColor, fontSize: 13),
          ),
        );
      }
    } catch (_) {
      return Text(
        latex,
        style: TextStyle(fontFamily: 'monospace', color: mathColor, fontSize: 13),
      );
    }
  }
}

class _DollarInlineMathSyntax extends md.InlineSyntax {
  _DollarInlineMathSyntax() : super(r'\$([^\$\n]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(1) ?? '';
    final el = md.Element.text('math', raw);
    parser.addNode(el);
    return true;
  }
}

class _DollarDisplayMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$(.*?)\$\$', multiLine: true, dotAll: true);

  @override
  md.Node? parse(md.BlockParser parser) {
    final childLines = <String>[];
    final match = pattern.firstMatch(parser.current.content);

    if (match != null) {
      parser.advance();
      return md.Element.text('mathBlock', match.group(1) ?? '');
    }

    parser.advance();
    while (!parser.isDone) {
      final current = parser.current.content;
      if (current.contains(r'$$')) {
        parser.advance();
        break;
      }
      childLines.add(current);
      parser.advance();
    }

    return md.Element.text('mathBlock', childLines.join('\n'));
  }
}
