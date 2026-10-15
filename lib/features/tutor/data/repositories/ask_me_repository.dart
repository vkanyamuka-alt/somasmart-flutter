import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/ask_me_model.dart';

final askMeRepositoryProvider = Provider<AskMeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AskMeRepository(client);
});

class AskMeRepository {
  final SupabaseClient _client;

  AskMeRepository(this._client);

  /// Builds the authoritative educational system prompt for the Tanzanian NECTA curriculum.
  Map<String, String> getSystemPrompt(String language) {
    if (language == 'sw') {
      return {
        'role': 'system',
        'content':
            'Wewe ni Ask Me, msaidizi mwerevu, mwenye urafiki na mwelewa wa masomo kwa wanafunzi wa sekondari nchini Tanzania chini ya mtaala wa NECTA (Form 1 hadi Form 6).\n'
            'Toa majibu sahihi, yenye kueleweka kwa urahisi, na yenye kutia moyo kwa lugha ya Kiswahili fasaha.\n'
            'Dumisha maneno ya kitaalamu (kama vile majina ya kanuni za sayansi, fomula za hisabati, au misamiati rasmi ya kitaaluma) pale inapohitajika kwa usahihi wa kielimu.\n'
            'Panga majibu yako vizuri kwa kutumia markdown (vichwa vya habari, orodha, vidokezo) na mifumo ya nukuu za hesabu za LaTeX pale inapofaa.',
      };
    } else {
      return {
        'role': 'system',
        'content':
            'You are Ask Me, an expert, friendly, and highly knowledgeable educational assistant for secondary school students in Tanzania studying under the NECTA syllabus (Form 1 to Form 6).\n'
            'Provide accurate, encouraging, clear, and easy-to-understand explanations in English.\n'
            'Maintain scientific and mathematical precision. Format responses neatly using markdown (headings, bullet points, code blocks) and LaTeX math notation (\$...\$ or \$\$...\$\$) where appropriate.',
      };
    }
  }

  /// Sends the chat conversation to the server-authoritative `somasmart-ai` Edge Function.
  Future<String> sendChatMessage({
    required List<ChatMessageModel> history,
    required String userPrompt,
    required String language,
    String model = 'deepseek-chat',
    double temperature = 0.7,
  }) async {
    final systemPrompt = getSystemPrompt(language);

    // Filter out previous error messages and map valid history
    final validHistory = history.where((m) => !m.isError && !m.isLoading && m.content.isNotEmpty).toList();

    final messages = [
      systemPrompt,
      ...validHistory.map((m) => m.toApiMessage()),
      {'role': 'user', 'content': userPrompt.trim()},
    ];

    try {
      final response = await _client.functions.invoke(
        'somasmart-ai',
        body: {
          'messages': messages,
          'model': model,
          'temperature': temperature,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception(language == 'sw'
            ? 'Hakuna jibu lililopokelewa kutoka Ask Me.'
            : 'No response data received from Ask Me.');
      }

      if (data is Map && data.containsKey('error')) {
        final err = data['error'];
        final errMsg = err is String ? err : (err['message'] ?? 'Unknown AI service error');
        throw Exception(errMsg);
      }

      // Extract content from DeepSeek chat completion standard response
      if (data is Map && data.containsKey('choices')) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices.first as Map<String, dynamic>;
          final message = firstChoice['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
      }

      throw Exception(language == 'sw'
          ? 'Muundo wa jibu la Ask Me haukutambuliwa.'
          : 'Unrecognized response format from Ask Me.');
    } catch (e) {
      rethrow;
    }
  }
}
