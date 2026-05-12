class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  /// From joined `profiles` row when feed query embeds author.
  final String? authorUsername;
  final String? authorAvatarUrl;

  final int likeCount;
  final int commentCount;

  /// Whether the signed-in user has a row in `likes` for this post (hydrated
  /// on fetch when `currentUserId` is known).
  final bool likedByMe;

  Post copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    String? authorUsername,
    String? authorAvatarUrl,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  String get displayUsername => authorUsername?.trim().isNotEmpty == true
      ? authorUsername!.trim()
      : 'user';

  /// Stable single-character initial for the circular avatar fallback.
  /// Prefers the author username; if absent (RLS hid the profile, or no
  /// `profiles` row yet) falls back to the first character of `userId` so
  /// the badge is still deterministic per author rather than a generic 'U'.
  String get displayInitial {
    final name = authorUsername?.trim();
    if (name != null && name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    if (userId.isNotEmpty) {
      return userId.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  /// PostgREST usually returns a single object for many-to-one embeds; some
  /// clients or hints may surface a one-element list — accept both.
  static Map<String, dynamic>? _profilesRow(dynamic profiles) {
    if (profiles == null) return null;
    if (profiles is Map<String, dynamic>) return profiles;
    if (profiles is Map) return Map<String, dynamic>.from(profiles);
    if (profiles is List) {
      if (profiles.isEmpty) return null;
      final first = profiles.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    String? authorUsername;
    String? authorAvatarUrl;
    final prof = _profilesRow(map['profiles']);
    if (prof != null) {
      final rawName = prof['username'];
      if (rawName is String && rawName.trim().isNotEmpty) {
        authorUsername = rawName.trim();
      }
      final rawAvatar = prof['avatar_url'];
      if (rawAvatar is String) {
        final trimmed = rawAvatar.trim();
        if (trimmed.isNotEmpty) authorAvatarUrl = trimmed;
      }
    }

    int countFrom(dynamic rel) {
      if (rel is! List || rel.isEmpty) return 0;
      final first = rel.first;
      if (first is! Map<String, dynamic>) return 0;
      final c = first['count'];
      if (c is num) return c.toInt();
      return 0;
    }

    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      imageUrl: map['image_url'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      likeCount: countFrom(map['likes']),
      commentCount: countFrom(map['comments']),
    );
  }
}
