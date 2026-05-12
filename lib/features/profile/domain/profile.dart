class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.followerCount = 0,
  });

  final String id;
  final String username;
  final String? bio;
  final String? avatarUrl;

  /// Denormalized count of rows in `follows` where `following_id` = [id].
  /// Maintained by database triggers; subscribe to Realtime on `profiles` for
  /// live updates.
  final int followerCount;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final raw = map['follower_count'];
    final count = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      followerCount: count < 0 ? 0 : count,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'bio': bio,
        'avatar_url': avatarUrl,
      };
}
