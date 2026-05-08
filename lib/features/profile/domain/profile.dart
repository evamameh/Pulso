class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? bio;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'bio': bio,
        'avatar_url': avatarUrl,
      };
}
