import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/repositories/ask_me_repository.dart';
import '../../domain/models/ask_me_model.dart';

/// Quick educational suggestion prompts for secondary school students in Tanzania
final askMeQuickPromptsProvider = Provider.autoDispose<List<String>>((ref) {
  final lang = ref.watch(languageProvider);
  if (lang == 'sw') {
    return const [
      "Fafanua Newton's First Law",
      "Jinsi ya kujiandaa na NECTA",
      "Muhtasari wa Photosynthesis",
      "Fomula ya Quadratic Equation",
      "Tofauti ya Mitosis na Meiosis",
      "Kanuni ya Ohm's Law kwa vitendo",
    ];
  } else {
    return const [
      "Explain Newton's First Law",
      "How to prepare for NECTA exams",
      "Photosynthesis summary",
      "Quadratic equation formula",
      "Difference between Mitosis and Meiosis",
      "Practical explanation of Ohm's Law",
    ];
  }
});

class AskMeState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const AskMeState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  AskMeState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AskMeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final askMeControllerProvider = StateNotifierProvider.autoDispose<AskMeController, AskMeState>((ref) {
  final repository = ref.watch(askMeRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return AskMeController(ref, repository, lang);
});

class AskMeController extends StateNotifier<AskMeState> {
  final Ref _ref;
  final AskMeRepository _repository;

  AskMeController(this._ref, this._repository, String initialLang)
      : super(AskMeState(messages: [_getInitialWelcomeMessage(initialLang)]));

  static ChatMessageModel _getInitialWelcomeMessage(String lang) {
    if (lang == 'sw') {
      return ChatMessageModel(
        id: 'welcome-init',
        role: 'assistant',
        content: 'Mimi ni **SomaSmart AI**. Ninawezaje kukusaidia kujifunza leo?',
        createdAt: DateTime.now(),
      );
    } else {
      return ChatMessageModel(
        id: 'welcome-init',
        role: 'assistant',
        content: "I'm **SomaSmart AI**. How can I help you learn today?",
        createdAt: DateTime.now(),
      );
    }
  }

  /// Checks if the authenticated user has active access (Free Trial or Active Premium)
  bool checkEntitlement() {
    final profile = _ref.read(userProfileProvider).value;
    if (profile == null) return false;
    return profile.hasAccess;
  }

  /// Sends a user question to Ask Me AI
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final lang = _ref.read(languageProvider);
    final userMsg = ChatMessageModel.user(trimmed);

    final currentMessages = List<ChatMessageModel>.from(state.messages)..add(userMsg);
    state = state.copyWith(
      messages: currentMessages,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final responseText = await _repository.sendChatMessage(
        history: currentMessages,
        userPrompt: trimmed,
        language: lang,
      );

      final assistantMsg = ChatMessageModel.assistant(responseText);
      state = state.copyWith(
        messages: List<ChatMessageModel>.from(state.messages)..add(assistantMsg),
        isLoading: false,
      );
    } catch (e) {
      final isSwahili = lang == 'sw';
      final errorReply = ChatMessageModel.assistant(
        isSwahili
            ? 'Samahani, SomaSmart AI imeshindwa kujibu kwa sasa kutokana na hitilafu ya mtandao au huduma. Tafadhali jaribu tena.'
            : 'Sorry, SomaSmart AI was unable to respond at this time due to a network or service issue. Please try again.',
        isError: true,
      );

      state = state.copyWith(
        messages: List<ChatMessageModel>.from(state.messages)..add(errorReply),
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears the local chat history and resets back to initial welcome message
  void clearConversation() {
    final lang = _ref.read(languageProvider);
    state = AskMeState(
      messages: [_getInitialWelcomeMessage(lang)],
      isLoading: false,
      errorMessage: null,
    );
  }
}
