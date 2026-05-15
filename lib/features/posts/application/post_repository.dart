import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/domain/comment.dart';
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

  Future<List<Post>> fetchFeed({int limit = 20}) => _gateway.fetchPosts(
        limit: limit,
        currentUserId: _currentUserId(),
      );

  Future<List<Post>> fetchPostsByUser(String userId, {int limit = 60}) =>
      _gateway.fetchPostsForUser(
        userId: userId,
        limit: limit,
        currentUserId: _currentUserId(),
      );

  Future<Post?> fetchPostById(String postId) => _gateway.fetchPostById(
        postId: postId,
        currentUserId: _currentUserId(),
      );

  Future<void> deletePost(String postId) => _gateway.deletePost(postId);

  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) =>
      _gateway.updateCaption(postId: postId, caption: caption);

  Future<void> likePost(String postId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot like a post without a signed-in user.');
    }
    await _gateway.likePost(postId: postId, userId: uid);
  }

  Future<void> unlikePost(String postId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot unlike a post without a signed-in user.');
    }
    await _gateway.unlikePost(postId: postId, userId: uid);
  }

  Future<List<Comment>> fetchComments(String postId) async {
    final comments = await _gateway.fetchComments(postId: postId);
    final uid = _currentUserId();
    if (uid != null && comments.isNotEmpty) {
      final likedIds = await _gateway.fetchLikedCommentIds(
        viewerId: uid,
        commentIds: comments.map((c) => c.id).toList(),
      );
      if (likedIds.isNotEmpty) {
        return comments
            .map((c) => c.copyWith(likedByMe: likedIds.contains(c.id)))
            .toList();
      }
    }
    return comments;
  }

  Future<void> likeComment(String commentId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot like a comment without a signed-in user.');
    }
    await _gateway.likeComment(commentId: commentId, userId: uid);
  }

  Future<void> unlikeComment(String commentId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot unlike a comment without a signed-in user.');
    }
    await _gateway.unlikeComment(commentId: commentId, userId: uid);
  }

  Future<void> addComment(
    String postId,
    String body, {
    String? parentCommentId,
  }) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot comment without a signed-in user.');
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    if (parentCommentId != null) {
      final existing = await _gateway.fetchComments(postId: postId);
      Comment? parent;
      for (final c in existing) {
        if (c.id == parentCommentId) {
          parent = c;
          break;
        }
      }
      if (parent == null || parent.postId != postId) {
        throw ArgumentError('That comment is not on this post.');
      }
    }
    await _gateway.postComment(
      postId: postId,
      userId: uid,
      body: trimmed,
      parentCommentId: parentCommentId,
    );
  }

  Future<void> updateComment(String commentId, String body) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot update a comment without a signed-in user.');
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _gateway.updateComment(commentId: commentId, body: trimmed);
  }

  Future<void> deleteComment(String commentId) =>
      _gateway.deleteComment(commentId);

  Future<void> savePost(String postId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot save a post without a signed-in user.');
    }
    await _gateway.savePost(userId: uid, postId: postId);
  }

  Future<void> unsavePost(String postId) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot unsave a post without a signed-in user.');
    }
    await _gateway.unsavePost(userId: uid, postId: postId);
  }

  Future<Set<String>> fetchSavedPostIds() async {
    final uid = _currentUserId();
    if (uid == null) return {};
    return _gateway.fetchSavedPostIds(uid);
  }

  Future<List<Post>> fetchSavedPosts({int limit = 60}) async {
    final uid = _currentUserId();
    if (uid == null) return [];
    return _gateway.fetchSavedPosts(
      userId: uid,
      currentUserId: uid,
      limit: limit,
    );
  }
}
