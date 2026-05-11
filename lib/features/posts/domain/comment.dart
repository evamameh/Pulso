class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String body;
  final DateTime createdAt;

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      username: map['profiles']?['username'] as String? ?? 'Unknown',
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
