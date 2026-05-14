import 'dart:typed_data';

import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/domain/comment.dart';
import 'package:pulso/features/posts/domain/post.dart';
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

  // Single FK posts.user_id → profiles.id: unhinted `profiles(...)` is used
  // intentionally because constraint-name hints differ between local and
  // hosted DBs. PostgREST returns a single object for this one-to-one embed;
  // `Post.fromMap` also accepts a one-element list for forward compatibility.
  // RLS: `profiles_select` allows authenticated users to read every profile,
  // so the join hydrates author info for every feed row regardless of poster.
  static const _postSelect = 'id, user_id, image_url, caption, created_at, '
      'profiles(username, avatar_url), '
      'likes(count), '
      'comments(count)';

  Future<Set<String>> _likedPostIds({
    required String viewerId,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) return {};
    final rows = await _client
        .from('likes')
        .select('post_id')
        .eq('user_id', viewerId)
        .inFilter('post_id', postIds);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    return list.map((r) => '${r['post_id']}').toSet();
  }

  List<Post> _mergeLikedByMe(
    List<Post> posts,
    Set<String> likedIds,
  ) {
    if (likedIds.isEmpty) return posts;
    return posts
        .map((p) => p.copyWith(likedByMe: likedIds.contains(p.id)))
        .toList();
  }

  @override
  Future<List<Post>> fetchPosts({
    int limit = 20,
    String? currentUserId,
  }) async {
    final rows = await _client
        .from('posts')
        .select(_postSelect)
        .order('created_at', ascending: false)
        .limit(limit);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    var posts = list.map(Post.fromMap).toList();
    if (currentUserId != null && posts.isNotEmpty) {
      final liked = await _likedPostIds(
        viewerId: currentUserId,
        postIds: posts.map((p) => p.id).toList(),
      );
      posts = _mergeLikedByMe(posts, liked);
    }
    return posts;
  }

  @override
  Future<List<Post>> fetchPostsForUser({
    required String userId,
    int limit = 60,
    String? currentUserId,
  }) async {
    final rows = await _client
        .from('posts')
        .select(_postSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    var posts = list.map(Post.fromMap).toList();
    if (currentUserId != null && posts.isNotEmpty) {
      final liked = await _likedPostIds(
        viewerId: currentUserId,
        postIds: posts.map((p) => p.id).toList(),
      );
      posts = _mergeLikedByMe(posts, liked);
    }
    return posts;
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
        .match({'post_id': postId, 'user_id': userId});
  }

  @override
  Future<List<Comment>> fetchComments({required String postId}) async {
    final rows = await _client
        .from('comments')
        .select(
            'id, post_id, user_id, body, created_at, profiles(username, avatar_url), comment_likes(count)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    return list.map(Comment.fromMap).toList();
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

  @override
  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) async {
    await _client.from('comment_likes').insert({
      'comment_id': commentId,
      'user_id': userId,
    });
  }

  @override
  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  }) async {
    await _client
        .from('comment_likes')
        .delete()
        .match({'comment_id': commentId, 'user_id': userId});
  }

  @override
  Future<Set<String>> fetchLikedCommentIds({
    required String viewerId,
    required List<String> commentIds,
  }) async {
    if (commentIds.isEmpty) return {};
    final rows = await _client
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', viewerId)
        .inFilter('comment_id', commentIds);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    return list.map((r) => '${r['comment_id']}').toSet();
  }
}
