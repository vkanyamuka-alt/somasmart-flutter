import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/ask_me_controller.dart';
import 'ask_me_markdown.dart';

/// Floating Liquid-Glass AI Assistant Panel.
/// Opens as a responsive floating glassmorphic overlay above the current screen.
/// Automatically adapts to on-screen keyboard via Scaffold resizeToAvoidBottomInset
/// and flexible constraints so the input field and messages stay visible while typing.
class AskMeFloatingPanel extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const AskMeFloatingPanel({
    super.key,
    this.initialPrompt,
  });

  /// Displays the floating SomaSmart AI assistant above the active screen.
  static Future<void> show(BuildContext context, {String? initialPrompt}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss SomaSmart AI',
      barrierColor: Colors.black.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) {
        return AskMeFloatingPanel(initialPrompt: initialPrompt);
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<AskMeFloatingPanel> createState() => _AskMeFloatingPanelState();
}

class _AskMeFloatingPanelState extends ConsumerState<AskMeFloatingPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPremiumModal(BuildContext context, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSwahili ? 'Maudhui ya Premium' : 'Premium Access Required',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? 'Kutumia SomaSmart AI kunahitaji usajili uliolipwa (Premium) au kipindi cha majaribio (Free Trial). Tafadhali jiunge sasa ili upate majibu yasiyo na kikomo.'
                    : 'Using SomaSmart AI requires an active Premium subscription or Free Trial. Subscribe now to unlock unlimited AI learning support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop(); // Dismiss AI panel
                        context.push('/subscription');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSwahili ? 'Jiunge (TSh 2,500)' : 'Subscribe',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSend([String? customPrompt]) {
    final text = customPrompt ?? _inputController.text;
    if (text.trim().isEmpty) return;

    final isSwahili = ref.read(languageProvider) == 'sw';
    final hasAccess = ref.read(askMeControllerProvider.notifier).checkEntitlement();

    if (!hasAccess) {
      _showPremiumModal(context, isSwahili);
      return;
    }

    if (customPrompt == null) {
      _inputController.clear();
    }
    _focusNode.unfocus();

    ref.read(askMeControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showResetConfirmation(BuildContext context, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isSwahili ? 'Futa Mazungumzo' : 'Reset Conversation'),
          content: Text(
            isSwahili
                ? 'Je, una uhakika unataka kuanza mazungumzo mapya na SomaSmart AI? Ujumbe uliopita utafutwa.'
                : 'Are you sure you want to start a new conversation with SomaSmart AI? Previous messages will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(askMeControllerProvider.notifier).clearConversation();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSwahili ? 'Mazungumzo yamefutwa.' : 'Conversation reset.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(isSwahili ? 'Anza Upya' : 'Reset'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String content, bool isSwahili) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        content: Text(
          isSwahili ? 'Jibu limekiliwa kwenye clipboard!' : 'Response copied to clipboard!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSwahili = ref.watch(languageProvider) == 'sw';
    final askMeState = ref.watch(askMeControllerProvider);
    final quickPrompts = ref.watch(askMeQuickPromptsProvider);

    // Auto-scroll when messages update
    ref.listen<AskMeState>(askMeControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || prev?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;

            // Responsive sizing that adapts dynamically when keyboard opens
            final panelWidth = (availableWidth * 0.94).clamp(300.0, 520.0);
            final panelMaxHeight = (availableHeight - 16.0).clamp(240.0, 680.0);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: panelWidth,
                    maxHeight: panelMaxHeight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xF40F172A),
                                    const Color(0xEA1E293B),
                                  ]
                                : [
                                    const Color(0xF8FFFFFF),
                                    const Color(0xF0F0F9FF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.9),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.black : AppColors.primary).withValues(
                                alpha: isDark ? 0.55 : 0.16,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Liquid Glass Header
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.45),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : AppColors.primary.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: isDark ? 0.25 : 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppColors.primary,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'SomaSmart AI',
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.3,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'AI ASSISTANT',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          isSwahili
                                              ? 'Msaidizi Wako wa Kujifunzia'
                                              : 'Your learning assistant',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Reset Chat action
                                  IconButton(
                                    icon: Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                    tooltip:
                                        isSwahili ? 'Anza upya mazungumzo' : 'Reset conversation',
                                    onPressed: () => _showResetConfirmation(context, isSwahili),
                                  ),
                                  // Close/Dismiss action
                                  InkWell(
                                    onTap: () => Navigator.of(context).pop(),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. NECTA Curriculum Context Tag
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.primary.withValues(alpha: 0.04),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : AppColors.primary.withValues(alpha: 0.05),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isSwahili
                                          ? 'Imebinafsishwa kwa masomo ya NECTA (Form 1 - 6)'
                                          : 'Aligned with NECTA Curriculum (Form 1 - 6)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Chat Messages Stream (Scrollable and Expanded)
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                                itemCount:
                                    askMeState.messages.length + (askMeState.isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Thinking indicator
                                  if (index == askMeState.messages.length &&
                                      askMeState.isLoading) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.white,
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(14),
                                                bottomLeft: Radius.circular(14),
                                                bottomRight: Radius.circular(14),
                                              ),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.1)
                                                    : AppColors.lightBorder,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isSwahili
                                                      ? 'SomaSmart AI inafikiria...'
                                                      : 'SomaSmart AI is thinking...',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontStyle: FontStyle.italic,
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
                                    );
                                  }

                                  final msg = askMeState.messages[index];
                                  final isUser = msg.isUser;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isUser) ...[
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: msg.isError
                                                  ? AppColors.error.withValues(alpha: 0.15)
                                                  : AppColors.primary.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              msg.isError
                                                  ? Icons.error_outline_rounded
                                                  : Icons.auto_awesome_rounded,
                                              size: 14,
                                              color:
                                                  msg.isError ? AppColors.error : AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isUser
                                                  ? AppColors.primary
                                                  : (isDark
                                                      ? Colors.white.withValues(alpha: 0.08)
                                                      : Colors.white),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(16),
                                                topRight: const Radius.circular(16),
                                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                                bottomRight: Radius.circular(isUser ? 4 : 16),
                                              ),
                                              border: isUser
                                                  ? null
                                                  : Border.all(
                                                      color: msg.isError
                                                          ? AppColors.error.withValues(alpha: 0.3)
                                                          : (isDark
                                                              ? Colors.white.withValues(alpha: 0.1)
                                                              : AppColors.lightBorder),
                                                    ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: isDark ? 0.25 : 0.03,
                                                  ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                AskMeMarkdown(
                                                  data: msg.content,
                                                  isDark: isDark,
                                                  isUser: isUser,
                                                ),
                                                if (!isUser &&
                                                    !msg.isError &&
                                                    msg.content.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _copyToClipboard(
                                                          msg.content,
                                                          isSwahili,
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                Icons.copy_rounded,
                                                                size: 11,
                                                                color: isDark
                                                                    ? AppColors.darkTextMuted
                                                                    : AppColors.lightTextMuted,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                isSwahili ? 'Kili' : 'Copy',
                                                                style: TextStyle(
                                                                  fontSize: 10.5,
                                                                  color: isDark
                                                                      ? AppColors.darkTextMuted
                                                                      : AppColors.lightTextMuted,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkBgContainerHigh
                                                  : Colors.grey.shade300,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 4. Quick Prompts (Initial state)
                            if (askMeState.messages.length <= 2 && !askMeState.isLoading)
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: quickPrompts.map((prompt) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ActionChip(
                                          label: Text(
                                            prompt,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          backgroundColor: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.white,
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : AppColors.lightBorder,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          onPressed: () => _handleSend(prompt),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                            // 5. Message Input Composer (Pinned above bottom border / keyboard)
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.65),
                                border: Border(
                                  top: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : AppColors.lightBorder,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkBgContainer
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _inputController,
                                        focusNode: _focusNode,
                                        maxLines: 3,
                                        minLines: 1,
                                        textCapitalization: TextCapitalization.sentences,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: isSwahili
                                              ? 'Uliza swali lolote kwa SomaSmart AI...'
                                              : 'Ask SomaSmart AI anything...',
                                          hintStyle: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: askMeState.isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 17,
                                            ),
                                      tooltip: isSwahili ? 'Tuma' : 'Send',
                                      padding: EdgeInsets.zero,
                                      onPressed: askMeState.isLoading ? null : () => _handleSend(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
