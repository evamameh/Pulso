class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;

  String get displayInitial =>
      username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      username: map['profiles']?['username'] as String? ?? 'Unknown',
      avatarUrl: map['profiles']?['avatar_url'] as String?,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
