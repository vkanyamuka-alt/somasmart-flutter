import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/forum_models.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ForumRepository(client);
});

class ForumRepository {
  final SupabaseClient _client;

  ForumRepository(this._client);

  /// Author name and role from the `forum_authors` view, never the `profiles`
  /// table (students may read only their own profile). The `profiles:` alias
  /// keeps the JSON key that [DiscussionModel.fromMap] and
  /// [DiscussionReplyModel.fromMap] read.
  static const authorEmbed = 'profiles:forum_authors(full_name, role)';

  /// Fetch all discussions ordered by created_at descending
  Future<List<DiscussionModel>> getDiscussions({String? searchQuery}) async {
    try {
      final query = _client
          .from('discussions')
          .select('*, $authorEmbed, discussion_replies(id)')
          .order('created_at', ascending: false);

      final response = await query;
      final list = (response as List).map((row) {
        return DiscussionModel.fromMap(row as Map<String, dynamic>);
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return list.where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.content.toLowerCase().contains(q) ||
            d.authorName.toLowerCase().contains(q)).toList();
      }

      return list;
    } catch (e) {
      // Fallback without join in case relationship name varies
      try {
        final response = await _client
            .from('discussions')
            .select('*')
            .order('created_at', ascending: false);

        final list = (response as List).map((row) {
          return DiscussionModel.fromMap(row as Map<String, dynamic>);
        }).toList();

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          return list.where((d) =>
              d.title.toLowerCase().contains(q) ||
              d.content.toLowerCase().contains(q) ||
              d.authorName.toLowerCase().contains(q)).toList();
        }

        return list;
      } catch (err) {
        rethrow;
      }
    }
  }

  /// Fetch single discussion by id
  Future<DiscussionModel> getDiscussion(String id) async {
    try {
      final response = await _client
          .from('discussions')
          .select('*, $authorEmbed, discussion_replies(id)')
          .eq('id', id)
          .single();

      return DiscussionModel.fromMap(response);
    } catch (e) {
      final response = await _client
          .from('discussions')
          .select('*')
          .eq('id', id)
          .single();

      return DiscussionModel.fromMap(response);
    }
  }

  /// Fetch replies for a given discussion
  Future<List<DiscussionReplyModel>> getReplies(String discussionId) async {
    try {
      final response = await _client
          .from('discussion_replies')
          .select('*, $authorEmbed')
          .eq('discussion_id', discussionId)
          .order('created_at', ascending: true);

      return (response as List).map((row) {
        return DiscussionReplyModel.fromMap(row as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // Fallback
      final response = await _client
          .from('discussion_replies')
          .select('*')
          .eq('discussion_id', discussionId)
          .order('created_at', ascending: true);

      return (response as List).map((row) {
        return DiscussionReplyModel.fromMap(row as Map<String, dynamic>);
      }).toList();
    }
  }

  /// Create a new discussion thread
  Future<DiscussionModel> createDiscussion({
    required String title,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated: Tafadhali ingia kwanza.');
    }

    // Attempt to get user's display name from profiles
    String authorName = 'Mwanafunzi';
    try {
      final profileRes = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes != null && profileRes['full_name'] != null) {
        authorName = profileRes['full_name'] as String;
      }
    } catch (_) {}

    final insertData = {
      'user_id': user.id,
      'title': title.trim(),
      'content': content.trim(),
    };

    final res = await _client
        .from('discussions')
        .insert(insertData)
        .select('*, $authorEmbed')
        .single();

    final model = DiscussionModel.fromMap(res);
    return model.copyWith(authorName: model.authorName.isEmpty ? authorName : model.authorName);
  }

  /// Create a reply to an existing discussion
  Future<DiscussionReplyModel> createReply({
    required String discussionId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated: Tafadhali ingia kwanza.');
    }

    final insertData = {
      'discussion_id': discussionId,
      'user_id': user.id,
      'content': content.trim(),
    };

    final res = await _client
        .from('discussion_replies')
        .insert(insertData)
        .select('*, $authorEmbed')
        .single();

    return DiscussionReplyModel.fromMap(res);
  }

  /// Delete a discussion thread (author or admin)
  Future<void> deleteDiscussion(String id) async {
    await _client.from('discussions').delete().eq('id', id);
  }

  /// Delete a reply (author or admin)
  Future<void> deleteReply(String id) async {
    await _client.from('discussion_replies').delete().eq('id', id);
  }
}
