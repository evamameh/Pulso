class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.body,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String body;
  final DateTime createdAt;

  /// When set, this comment is a reply to another comment on the same post.
  final String? parentId;

  bool get isReply => parentId != null;

  factory Comment.fromMap(Map<String, dynamic> map) {
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

    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      username: username,
      body: body,
      createdAt: DateTime.parse(map['created_at'] as String),
      parentId: map['parent_id'] as String?,
    );
  }
}
