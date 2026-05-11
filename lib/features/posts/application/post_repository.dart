import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:uuid/uuid.dart';

class PostRepository {
  PostRepository({
    required PostGateway gateway,
    required String? Function() currentUserId,
    Uuid? uuid,
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _uuid = uuid ?? const Uuid();

  final PostGateway _gateway;
  final String? Function() _currentUserId;
  final Uuid _uuid;

  Future<void> createPost({
    required List<int> imageBytes,
    String? caption,
    String Function()? newObjectPath,
  }) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot create a post without a signed-in user.');
    }
    final path = newObjectPath?.call() ?? '$uid/${_uuid.v4()}.jpg';
    final imageUrl = await _gateway.uploadPostImage(
      userId: uid,
      bytes: imageBytes,
      objectPath: path,
    );
    await _gateway.insertPost(
      userId: uid,
      imageUrl: imageUrl,
      caption: caption,
    );
  }

  Future<List<Post>> fetchFeed({int limit = 20}) {
    final uid = _currentUserId();
    return _gateway.fetchPosts(limit: limit, currentUserId: uid);
  }

  Future<void> deletePost(String postId) => _gateway.deletePost(postId);

  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) =>
      _gateway.updateCaption(postId: postId, caption: caption);

  Future<void> likePost(String postId) {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot like a post without a signed-in user.');
    }
    return _gateway.likePost(postId: postId, userId: uid);
  }

  Future<void> unlikePost(String postId) {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot unlike a post without a signed-in user.');
    }
    return _gateway.unlikePost(postId: postId, userId: uid);
  }
}
