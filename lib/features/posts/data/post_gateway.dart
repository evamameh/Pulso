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
  });

  Future<void> deleteComment(String commentId);
}
