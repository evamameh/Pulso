import 'package:pulso/features/profile/data/follow_gateway.dart';

class FollowRepository {
  FollowRepository({
    required FollowGateway gateway,
    required String? Function() currentUserId,
  })  : _gateway = gateway,
        _currentUserId = currentUserId;

  final FollowGateway _gateway;
  final String? Function() _currentUserId;

  Future<bool> isFollowing(String targetUserId) async {
    final me = _currentUserId();
    if (me == null) return false;
    if (me == targetUserId) return false;
    return _gateway.isFollowing(followerId: me, followingId: targetUserId);
  }

  Future<void> follow(String targetUserId) async {
    final me = _currentUserId();
    if (me == null) {
      throw StateError('Cannot follow without a signed-in user.');
    }
    if (me == targetUserId) {
      throw ArgumentError('Cannot follow yourself.');
    }
    await _gateway.follow(followerId: me, followingId: targetUserId);
  }

  Future<void> unfollow(String targetUserId) async {
    final me = _currentUserId();
    if (me == null) {
      throw StateError('Cannot unfollow without a signed-in user.');
    }
    await _gateway.unfollow(followerId: me, followingId: targetUserId);
  }
}
