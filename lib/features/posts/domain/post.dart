class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
