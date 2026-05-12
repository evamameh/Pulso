import 'package:pulso/features/profile/data/follow_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFollowGateway implements FollowGateway {
  SupabaseFollowGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final row = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  @override
  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    await _client.from('follows').delete().match({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }
}
