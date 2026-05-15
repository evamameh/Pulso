import 'package:pulso/features/posts/domain/comment.dart';
import 'package:pulso/features/posts/domain/post.dart';

/// Supabase-backed post + storage operations (mocked in unit tests).
abstract class PostGateway {
  Future<String> uploadPostImage({
    required String userId,
    required List<int> bytes,
    required String objectPath,
  });

  Future<void> insertPost({
    required String userId,
    required String imageUrl,
    String? caption,
  });

  Future<List<Post>> fetchPosts({
    int limit = 20,
    String? currentUserId,
  });

  Future<List<Post>> fetchPostsForUser({
    required String userId,
    int limit = 60,
    String? currentUserId,
  });

  Future<Post?> fetchPostById({
    required String postId,
    String? currentUserId,
  });

  Future<void> deletePost(String postId);

  Future<void> updateCaption({
    required String postId,
    required String caption,
  });

  Future<void> likePost({
    required String postId,
    required String userId,
  });

  Future<void> unlikePost({
    required String postId,
    required String userId,
  });

  Future<List<Comment>> fetchComments({required String postId});

  Future<void> postComment({
    required String postId,
    required String userId,
    required String body,
    String? parentCommentId,
  });

  Future<void> updateComment({
    required String commentId,
    required String body,
  });

  Future<void> deleteComment(String commentId);

  Future<void> likeComment({
    required String commentId,
    required String userId,
  });

  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  });

  /// Returns comment IDs in [commentIds] that [viewerId] has liked.
  Future<Set<String>> fetchLikedCommentIds({
    required String viewerId,
    required List<String> commentIds,
  });

  /// Bookmark: only visible to [userId] via RLS on `post_saves`.
  Future<void> savePost({
    required String userId,
    required String postId,
  });

  Future<void> unsavePost({
    required String userId,
    required String postId,
  });

  Future<Set<String>> fetchSavedPostIds(String userId);

  Future<List<Post>> fetchSavedPosts({
    required String userId,
    String? currentUserId,
    int limit = 60,
  });
}
