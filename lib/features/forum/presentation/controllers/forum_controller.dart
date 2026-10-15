import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../data/repositories/forum_repository.dart';
import '../../domain/models/forum_models.dart';

/// Search query provider for forum list
final forumSearchQueryProvider = StateProvider<String>((ref) => '');

/// Discussions list provider (refreshes automatically or when invalidated)
final discussionsListProvider = FutureProvider.autoDispose<List<DiscussionModel>>((ref) async {
  final repository = ref.watch(forumRepositoryProvider);
  final searchQuery = ref.watch(forumSearchQueryProvider);
  return repository.getDiscussions(searchQuery: searchQuery);
});

/// Discussion details provider
final discussionDetailsProvider = FutureProvider.autoDispose.family<DiscussionModel, String>((ref, id) async {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.getDiscussion(id);
});

/// Replies provider for a given discussion
final discussionRepliesProvider = FutureProvider.autoDispose.family<List<DiscussionReplyModel>, String>((ref, discussionId) async {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.getReplies(discussionId);
});

/// Controller for mutating forum data (posting question, replying, deleting)
final forumControllerProvider = StateNotifierProvider<ForumController, AsyncValue<void>>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return ForumController(ref, repository);
});

class ForumController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ForumRepository _repository;

  ForumController(this._ref, this._repository) : super(const AsyncValue.data(null));

  /// Check whether current authenticated user has active access (Premium or active trial)
  bool checkEntitlement() {
    final profile = _ref.read(userProfileProvider).value;
    if (profile == null) return false;
    return profile.isPremium || profile.isTrialActive;
  }

  /// Create a new discussion post
  Future<DiscussionModel?> createDiscussion({
    required String title,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createDiscussion(
        title: title,
        content: content,
      );
      state = const AsyncValue.data(null);
      // Invalidate list to refresh UI
      _ref.invalidate(discussionsListProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Post a reply to a discussion
  Future<DiscussionReplyModel?> postReply({
    required String discussionId,
    required String content,
  }) async {
    state = const AsyncValue.loading();
    try {
      final reply = await _repository.createReply(
        discussionId: discussionId,
        content: content,
      );
      state = const AsyncValue.data(null);
      // Invalidate replies and discussion list (for reply counts)
      _ref.invalidate(discussionRepliesProvider(discussionId));
      _ref.invalidate(discussionDetailsProvider(discussionId));
      _ref.invalidate(discussionsListProvider);
      return reply;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a discussion thread
  Future<void> deleteDiscussion(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDiscussion(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(discussionsListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete a reply
  Future<void> deleteReply({
    required String discussionId,
    required String replyId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReply(replyId);
      state = const AsyncValue.data(null);
      _ref.invalidate(discussionRepliesProvider(discussionId));
      _ref.invalidate(discussionDetailsProvider(discussionId));
      _ref.invalidate(discussionsListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
