import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/posts/application/post_repository.dart';
import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/data/supabase_post_gateway.dart';
import 'package:pulso/features/posts/domain/comment.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final postGatewayProvider = Provider<PostGateway>(
  (ref) => SupabasePostGateway(ref.watch(supabaseClientProvider)),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(
    gateway: ref.watch(postGatewayProvider),
    currentUserId: () => ref.read(currentUserIdProvider),
  ),
);

final userPostsProvider = FutureProvider.family<List<Post>, String>(
  (ref, userId) =>
      ref.watch(postRepositoryProvider).fetchPostsByUser(userId),
);

final postCommentsProvider = FutureProvider.family<List<Comment>, String>(
  (ref, postId) => ref.watch(postRepositoryProvider).fetchComments(postId),
);

final postFeedProvider =
    AutoDisposeAsyncNotifierProvider<PostFeedNotifier, List<Post>>(
  PostFeedNotifier.new,
);

class PostFeedNotifier extends AutoDisposeAsyncNotifier<List<Post>> {
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _commentsChannel;

  @override
  Future<List<Post>> build() async {
    // Re-fetch when the signed-in user id appears (e.g. web session restore),
    // so `likedByMe` hydration in [SupabasePostGateway.fetchPosts] runs.
    ref.watch(currentUserIdProvider);
    final client = ref.watch(supabaseClientProvider);
    final posts = await ref.read(postRepositoryProvider).fetchFeed();

    void bumpLikeCount(String postId, int delta) {
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(
        current.map((p) {
          if (p.id != postId) return p;
          final n = p.likeCount + delta;
          return p.copyWith(likeCount: n < 0 ? 0 : n);
        }).toList(),
      );
    }

    void bumpCommentCount(String postId, int delta) {
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(
        current.map((p) {
          if (p.id != postId) return p;
          final n = p.commentCount + delta;
          return p.copyWith(commentCount: n < 0 ? 0 : n);
        }).toList(),
      );
    }

    final likesChannel = client.channel('pulso_feed_likes');
    likesChannel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'likes',
        callback: (payload) {
          final newRow = payload.newRecord;
          if (newRow == null) return;
          final postId = newRow['post_id'] as String?;
          final likerId = newRow['user_id'] as String?;
          if (postId == null || likerId == null) return;
          final myId = ref.read(currentUserIdProvider);
          if (likerId == myId) return;
          bumpLikeCount(postId, 1);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'likes',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          if (oldRow == null) return;
          final postId = oldRow['post_id'] as String?;
          final likerId = oldRow['user_id'] as String?;
          if (postId == null || likerId == null) return;
          final myId = ref.read(currentUserIdProvider);
          if (likerId == myId) return;
          bumpLikeCount(postId, -1);
        },
      );

    likesChannel.subscribe();
    _likesChannel = likesChannel;

    final commentsChannel = client.channel('pulso_feed_comments');
    commentsChannel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'comments',
        callback: (payload) {
          final newRow = payload.newRecord;
          if (newRow == null) return;
          final postId = newRow['post_id'] as String?;
          if (postId == null) return;
          bumpCommentCount(postId, 1);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'comments',
        callback: (payload) {
          final oldRow = payload.oldRecord;
          if (oldRow == null) return;
          final postId = oldRow['post_id'] as String?;
          if (postId == null) return;
          bumpCommentCount(postId, -1);
        },
      );

    commentsChannel.subscribe();
    _commentsChannel = commentsChannel;

    ref.onDispose(() {
      final likesCh = _likesChannel;
      if (likesCh != null) {
        client.removeChannel(likesCh);
        _likesChannel = null;
      }
      final commentsCh = _commentsChannel;
      if (commentsCh != null) {
        client.removeChannel(commentsCh);
        _commentsChannel = null;
      }
    });

    return posts;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(postRepositoryProvider).fetchFeed(),
    );
  }

  Future<void> toggleLike(Post post) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final current = state.valueOrNull;
    if (current == null) return;

    final liked = post.likedByMe;
    final nextList = current.map((p) {
      if (p.id != post.id) return p;
      final nextCount = liked
          ? (p.likeCount > 0 ? p.likeCount - 1 : 0)
          : p.likeCount + 1;
      return p.copyWith(
        likedByMe: !liked,
        likeCount: nextCount,
      );
    }).toList();

    state = AsyncData(nextList);

    try {
      final repo = ref.read(postRepositoryProvider);
      if (liked) {
        await repo.unlikePost(post.id);
      } else {
        await repo.likePost(post.id);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
