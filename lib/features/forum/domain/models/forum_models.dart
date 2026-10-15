class DiscussionModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String? authorRole;
  final int replyCount;

  const DiscussionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.authorRole,
    this.replyCount = 0,
  });

  bool get isAdmin => authorRole == 'admin';

  factory DiscussionModel.fromMap(Map<String, dynamic> map) {
    String name = 'Mwanafunzi';
    String? role;

    if (map['profiles'] != null && map['profiles'] is Map) {
      final profile = map['profiles'] as Map<String, dynamic>;
      name = profile['full_name'] as String? ?? (map['author_name'] as String? ?? 'Mwanafunzi');
      role = profile['role'] as String?;
    } else if (map['author_name'] != null) {
      name = map['author_name'] as String;
      role = map['author_role'] as String?;
    }

    int replies = 0;
    if (map['discussion_replies'] != null) {
      if (map['discussion_replies'] is List) {
        replies = (map['discussion_replies'] as List).length;
      } else if (map['discussion_replies'] is Map && (map['discussion_replies'] as Map).containsKey('count')) {
        replies = map['discussion_replies']['count'] as int? ?? 0;
      }
    } else if (map['reply_count'] != null) {
      replies = map['reply_count'] as int? ?? 0;
    }

    DateTime created = DateTime.now();
    if (map['created_at'] != null) {
      created = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    }

    return DiscussionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: created,
      authorName: name,
      authorRole: role,
      replyCount: replies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'author_name': authorName,
      'author_role': authorRole,
      'reply_count': replyCount,
    };
  }

  DiscussionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    String? authorName,
    String? authorRole,
    int? replyCount,
  }) {
    return DiscussionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}

class DiscussionReplyModel {
  final String id;
  final String discussionId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String? authorRole;

  const DiscussionReplyModel({
    required this.id,
    required this.discussionId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.authorRole,
  });

  bool get isAdmin => authorRole == 'admin';

  factory DiscussionReplyModel.fromMap(Map<String, dynamic> map) {
    String name = 'Mwanafunzi';
    String? role;

    if (map['profiles'] != null && map['profiles'] is Map) {
      final profile = map['profiles'] as Map<String, dynamic>;
      name = profile['full_name'] as String? ?? (map['author_name'] as String? ?? 'Mwanafunzi');
      role = profile['role'] as String?;
    } else if (map['author_name'] != null) {
      name = map['author_name'] as String;
      role = map['role'] as String? ?? map['author_role'] as String?;
    }

    DateTime created = DateTime.now();
    if (map['created_at'] != null) {
      created = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    }

    return DiscussionReplyModel(
      id: map['id']?.toString() ?? '',
      discussionId: map['discussion_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      content: map['content'] as String? ?? '',
      createdAt: created,
      authorName: name,
      authorRole: role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'discussion_id': discussionId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'author_name': authorName,
      'author_role': authorRole,
    };
  }
}
