import 'dart:typed_data';

import 'package:pulso/features/posts/data/post_gateway.dart';
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

  @override
  Future<List<Post>> fetchPosts({int limit = 20}) async {
    final rows = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final list = List<Map<String, dynamic>>.from(rows as List<dynamic>);
    return list.map(Post.fromMap).toList();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }
}
