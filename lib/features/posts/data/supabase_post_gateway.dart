import 'dart:typed_data';

import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:pulso/features/posts/domain/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePostGateway implements PostGateway {
  SupabasePostGateway(this._client);

  final SupabaseClient _client;
  static const _bucket = 'posts';

  @override
  Future<String> uploadPostImage({
    required String userId,
    required List<int> bytes,
    required String objectPath,
  }) async {
    await _client.storage.from(_bucket).uploadBinary(
          objectPath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }

  @override
  Future<void> insertPost({
    required String userId,
    required String imageUrl,
    String? caption,
  }) async {
    await _client.from('posts').insert({
      'user_id': userId,
      'image_url': imageUrl,
      'caption': caption,
    });
  }

  @override
  Future<List<Post>> fetchPosts({int limit = 20, String? currentUserId}) async {
    // Fetch posts with likes count
    final rows = await _client
        .from('posts')
        .select('''
          *,
          likes:likes(count)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);

    // If we have currentUserId, check which posts they've liked
    Set<String> likedPostIds = {};
    if (currentUserId != null) {
      final likedPosts = await _client
          .from('likes')
          .select('post_id')
          .eq('user_id', currentUserId);
      likedPostIds = (likedPosts as List).map((e) => e['post_id'] as String).toSet();
    }

    return list.map((postData) {
      final likesCount = (postData['likes'] as List?)?.length ?? 0;
      final postId = postData['id'] as String;
      final userLiked = likedPostIds.contains(postId);

      return Post(
        id: postId,
        userId: postData['user_id'] as String,
        imageUrl: postData['image_url'] as String,
        caption: postData['caption'] as String?,
        createdAt: DateTime.parse(postData['created_at'] as String),
        likesCount: likesCount,
        userLiked: userLiked,
      );
    }).toList();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  @override
  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) async {
    await _client.from('posts').update({'caption': caption}).eq('id', postId);
  }

  @override
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    await _client.from('likes').insert({
      'post_id': postId,
      'user_id': userId,
    });
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    await _client
        .from('likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Comment>> fetchComments({required String postId}) async {
    final rows = await _client
        .from('comments')
        .select('*, profiles(username)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .map((commentData) => Comment.fromMap(commentData as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> postComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'body': body,
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }
}
