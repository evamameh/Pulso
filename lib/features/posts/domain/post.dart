class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    this.likesCount = 0,
    this.userLiked = false,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final int likesCount;
  final bool userLiked;

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      likesCount: map['likes_count'] as int? ?? 0,
      userLiked: map['user_liked'] as bool? ?? false,
    );
  }
}
