class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
<<<<<<< HEAD
    this.parentId,
=======
    this.likeCount = 0,
    this.likedByMe = false,
>>>>>>> ff4f7255b6d33b887cf872c885026593f490edfe
  });

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

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
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  /// When set, this comment is a reply to another comment on the same post.
  final String? parentId;

  bool get isReply => parentId != null;

  factory Comment.fromMap(Map<String, dynamic> map) {
<<<<<<< HEAD
    final prof = map['profiles'];
    String username = 'user';
    if (prof is Map<String, dynamic>) {
      final u = prof['username'] as String?;
      if (u != null && u.trim().isNotEmpty) username = u.trim();
    } else if (prof is List && prof.isNotEmpty) {
      final first = prof.first;
      if (first is Map<String, dynamic>) {
        final u = first['username'] as String?;
        if (u != null && u.trim().isNotEmpty) username = u.trim();
      }
    }

    final bodyRaw = map['body'];
    final body = bodyRaw is String
        ? bodyRaw
        : (bodyRaw == null ? '' : bodyRaw.toString());

=======
    int countFrom(dynamic rel) {
      if (rel is! List || rel.isEmpty) return 0;
      final first = rel.first;
      if (first is! Map<String, dynamic>) return 0;
      final c = first['count'];
      if (c is num) return c.toInt();
      return 0;
    }

>>>>>>> ff4f7255b6d33b887cf872c885026593f490edfe
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
<<<<<<< HEAD
      username: username,
      body: body,
      createdAt: DateTime.parse(map['created_at'] as String),
      parentId: map['parent_id'] as String?,
=======
      username: map['profiles']?['username'] as String? ?? 'Unknown',
      avatarUrl: map['profiles']?['avatar_url'] as String?,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      likeCount: countFrom(map['comment_likes']),
>>>>>>> ff4f7255b6d33b887cf872c885026593f490edfe
    );
  }
}
