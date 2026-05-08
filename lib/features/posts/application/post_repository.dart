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

  Future<List<Post>> fetchFeed({int limit = 20}) =>
      _gateway.fetchPosts(limit: limit);

  Future<void> deletePost(String postId) => _gateway.deletePost(postId);
}
