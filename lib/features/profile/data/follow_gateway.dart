/// Follow relationships (`public.follows` in Supabase).
abstract class FollowGateway {
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  });

  Future<void> follow({
    required String followerId,
    required String followingId,
  });

  Future<void> unfollow({
    required String followerId,
    required String followingId,
  });
}
