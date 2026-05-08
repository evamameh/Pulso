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

  Future<List<Post>> fetchPosts({int limit});

  Future<void> deletePost(String postId);
}
