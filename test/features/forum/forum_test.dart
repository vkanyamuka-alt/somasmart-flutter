import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/forum/domain/models/forum_models.dart';

void main() {
  group('Forum Domain Models & Parsing', () {
    test('DiscussionModel.fromMap parses standard payload with profiles join', () {
      final payload = {
        'id': 'disc-101',
        'user_id': 'usr-001',
        'title': 'How to calculate velocity vs acceleration?',
        'content': 'Can someone explain the fundamental differences and formulas?',
        'created_at': '2026-09-14T02:00:00.000Z',
        'profiles': {
          'full_name': 'Baraka Juma',
          'role': 'student',
        },
        'discussion_replies': [
          {'id': 'rep-1'},
          {'id': 'rep-2'},
        ],
      };

      final model = DiscussionModel.fromMap(payload);

      expect(model.id, 'disc-101');
      expect(model.userId, 'usr-001');
      expect(model.title, 'How to calculate velocity vs acceleration?');
      expect(model.content, 'Can someone explain the fundamental differences and formulas?');
      expect(model.authorName, 'Baraka Juma');
      expect(model.authorRole, 'student');
      expect(model.isAdmin, false);
      expect(model.replyCount, 2);
    });

    test('DiscussionModel.fromMap recognizes admin role', () {
      final payload = {
        'id': 'disc-102',
        'user_id': 'admin-001',
        'title': 'Official Exam Guidelines 2026',
        'content': 'Please review the official syllabus structure for NECTA exams.',
        'created_at': '2026-09-14T02:00:00.000Z',
        'profiles': {
          'full_name': 'Mwl. Makonda',
          'role': 'admin',
        },
        'discussion_replies': [],
      };

      final model = DiscussionModel.fromMap(payload);

      expect(model.authorName, 'Mwl. Makonda');
      expect(model.authorRole, 'admin');
      expect(model.isAdmin, true);
      expect(model.replyCount, 0);
    });

    test('DiscussionReplyModel.fromMap parses reply payload with admin role', () {
      final payload = {
        'id': 'reply-501',
        'discussion_id': 'disc-101',
        'user_id': 'admin-001',
        'content': 'Velocity is displacement over time (vector), acceleration is rate of change of velocity.',
        'created_at': '2026-09-14T02:15:00.000Z',
        'profiles': {
          'full_name': 'Admin Support',
          'role': 'admin',
        },
      };

      final reply = DiscussionReplyModel.fromMap(payload);

      expect(reply.id, 'reply-501');
      expect(reply.discussionId, 'disc-101');
      expect(reply.userId, 'admin-001');
      expect(reply.authorName, 'Admin Support');
      expect(reply.authorRole, 'admin');
      expect(reply.isAdmin, true);
    });

    test('DiscussionReplyModel.fromMap handles fallback student payload', () {
      final payload = {
        'id': 'reply-502',
        'discussion_id': 'disc-101',
        'user_id': 'usr-002',
        'content': 'Asante sana kwa maelezo mazuri!',
        'created_at': '2026-09-14T02:20:00.000Z',
      };

      final reply = DiscussionReplyModel.fromMap(payload);

      expect(reply.authorName, 'Mwanafunzi');
      expect(reply.authorRole, isNull);
      expect(reply.isAdmin, false);
      expect(reply.content, 'Asante sana kwa maelezo mazuri!');
    });
  });

  group('Forum Permission & Filter Logic', () {
    final sampleDiscussions = [
      DiscussionModel(
        id: '1',
        userId: 'student-A',
        title: 'Photosynthesis light reactions',
        content: 'What happens in thylakoid membrane during stage 1?',
        createdAt: DateTime.now(),
        authorName: 'Amina Salum',
        authorRole: 'student',
        replyCount: 3,
      ),
      DiscussionModel(
        id: '2',
        userId: 'student-B',
        title: 'O-Level Chemistry Periodic Trends',
        content: 'Electronegativity increases across periods from left to right.',
        createdAt: DateTime.now(),
        authorName: 'Kelvin Mwamba',
        authorRole: 'student',
        replyCount: 0,
      ),
      DiscussionModel(
        id: '3',
        userId: 'admin-1',
        title: 'Syllabus Updates for Physics Practical',
        content: 'New pendulum length measurements added.',
        createdAt: DateTime.now(),
        authorName: 'Head Teacher',
        authorRole: 'admin',
        replyCount: 5,
      ),
    ];

    test('Search filter matches title and content correctly', () {
      final q = 'chemistry';
      final filtered = sampleDiscussions.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.content.toLowerCase().contains(q) ||
          d.authorName.toLowerCase().contains(q)).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('Search filter matches author name', () {
      final q = 'amina';
      final filtered = sampleDiscussions.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.content.toLowerCase().contains(q) ||
          d.authorName.toLowerCase().contains(q)).toList();

      expect(filtered.length, 1);
      expect(filtered.first.authorName, 'Amina Salum');
    });

    test('Delete authorization allows owner or admin', () {
      bool canDelete(DiscussionModel disc, String currentUserId, String currentRole) {
        return currentRole == 'admin' || disc.userId == currentUserId;
      }

      final discA = sampleDiscussions[0]; // owner: student-A

      // Owner student-A can delete
      expect(canDelete(discA, 'student-A', 'student'), true);

      // Other student-B cannot delete
      expect(canDelete(discA, 'student-B', 'student'), false);

      // Admin can delete any discussion
      expect(canDelete(discA, 'random-admin', 'admin'), true);
    });
  });
}
