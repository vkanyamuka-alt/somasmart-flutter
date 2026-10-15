class ChatMessageModel {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;
  final bool isError;
  final bool isLoading;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
    this.isLoading = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

  factory ChatMessageModel.user(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessageModel.assistant(String content, {bool isError = false}) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
      isError: isError,
    );
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: map['role'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isError: map['is_error'] as bool? ?? false,
      isLoading: map['is_loading'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_error': isError,
      'is_loading': isLoading,
    };
  }

  Map<String, dynamic> toApiMessage() {
    return {
      'role': role,
      'content': content,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isError,
    bool? isLoading,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isError: isError ?? this.isError,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
