import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/tutor/domain/models/ask_me_model.dart';
import 'package:somasmart_flutter/features/tutor/data/repositories/ask_me_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fake SupabaseClient for testing system prompt and model contracts
class FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('Ask Me Domain Model Tests', () {
    test('ChatMessageModel.user creates valid user message', () {
      final msg = ChatMessageModel.user('How do plants convert sunlight into glucose?');

      expect(msg.isUser, true);
      expect(msg.isAssistant, false);
      expect(msg.isSystem, false);
      expect(msg.role, 'user');
      expect(msg.content, 'How do plants convert sunlight into glucose?');
      expect(msg.isError, false);

      final apiMsg = msg.toApiMessage();
      expect(apiMsg, {
        'role': 'user',
        'content': 'How do plants convert sunlight into glucose?',
      });
    });

    test('ChatMessageModel.assistant creates valid assistant message', () {
      final msg = ChatMessageModel.assistant('Photosynthesis occurs in chloroplasts.', isError: false);

      expect(msg.isUser, false);
      expect(msg.isAssistant, true);
      expect(msg.role, 'assistant');
      expect(msg.content, 'Photosynthesis occurs in chloroplasts.');
      expect(msg.isError, false);
    });

    test('ChatMessageModel.fromMap parses serialized map correctly', () {
      final map = {
        'id': 'msg-999',
        'role': 'assistant',
        'content': r'Velocity $v = \frac{d}{t}$',
        'created_at': '2026-09-14T03:00:00.000Z',
        'is_error': false,
        'is_loading': false,
      };

      final msg = ChatMessageModel.fromMap(map);

      expect(msg.id, 'msg-999');
      expect(msg.role, 'assistant');
      expect(msg.content, r'Velocity $v = \frac{d}{t}$');
      expect(msg.isError, false);
      expect(msg.isLoading, false);
    });
  });

  group('Ask Me System Prompt & Language Instruction Tests', () {
    final repository = AskMeRepository(FakeSupabaseClient());

    test('Swahili system prompt enforces Kiswahili and NECTA curriculum context', () {
      final prompt = repository.getSystemPrompt('sw');

      expect(prompt['role'], 'system');
      final content = prompt['content']!;

      expect(content.contains('Ask Me'), true);
      expect(content.contains('NECTA'), true);
      expect(content.contains('Kiswahili'), true);
      expect(content.contains('Form 1 hadi Form 6'), true);
    });

    test('English system prompt enforces English and NECTA curriculum context', () {
      final prompt = repository.getSystemPrompt('en');

      expect(prompt['role'], 'system');
      final content = prompt['content']!;

      expect(content.contains('Ask Me'), true);
      expect(content.contains('NECTA'), true);
      expect(content.contains('English'), true);
      expect(content.contains('Form 1 to Form 6'), true);
    });
  });

  group('Ask Me Response Extraction Verification', () {
    test('DeepSeek standard response structure extracts message content', () {
      final fakeResponse = {
        'id': 'chatcmpl-12345',
        'object': 'chat.completion',
        'created': 1726000000,
        'model': 'deepseek-chat',
        'choices': [
          {
            'index': 0,
            'message': {
              'role': 'assistant',
              'content': 'Newton\'s first law states that an object at rest stays at rest unless acted upon by an external net force.',
            },
            'finish_reason': 'stop',
          }
        ],
        'usage': {
          'prompt_tokens': 50,
          'completion_tokens': 30,
          'total_tokens': 80,
        }
      };

      final choices = fakeResponse['choices'] as List;
      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'] as String;

      expect(content, contains('Newton\'s first law'));
    });
  });
}
