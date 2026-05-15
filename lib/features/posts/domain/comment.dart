class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.parentId,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;
  final String? parentId;
  final int likeCount;
  final bool likedByMe;

  bool get isReply => parentId != null;

  String get displayInitial =>
      username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? body,
    DateTime? createdAt,
    String? parentId,
    int? likeCount,
    bool? likedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  static int _countFrom(dynamic rel) {
    if (rel is! List || rel.isEmpty) return 0;
    final first = rel.first;
    if (first is! Map<String, dynamic>) return 0;
    final c = first['count'];
    if (c is num) return c.toInt();
    return 0;
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    final prof = map['profiles'];
    String username = 'user';
    String? avatarUrl;
    if (prof is Map<String, dynamic>) {
      final u = prof['username'] as String?;
      if (u != null && u.trim().isNotEmpty) username = u.trim();
      final a = prof['avatar_url'] as String?;
      if (a != null && a.trim().isNotEmpty) avatarUrl = a.trim();
    } else if (prof is List && prof.isNotEmpty) {
      final first = prof.first;
      if (first is Map<String, dynamic>) {
        final u = first['username'] as String?;
        if (u != null && u.trim().isNotEmpty) username = u.trim();
        final a = first['avatar_url'] as String?;
        if (a != null && a.trim().isNotEmpty) avatarUrl = a.trim();
      }
    }

    final bodyRaw = map['body'];
    final body = bodyRaw is String
        ? bodyRaw
        : (bodyRaw == null ? '' : bodyRaw.toString());

    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      username: username,
      avatarUrl: avatarUrl,
      body: body,
      createdAt: DateTime.parse(map['created_at'] as String),
      parentId: map['parent_id'] as String?,
      likeCount: _countFrom(map['comment_likes']),
    );
  }
}
