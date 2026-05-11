import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/posts/application/post_repository.dart';
import 'package:pulso/features/posts/data/post_gateway.dart';
import 'package:pulso/features/posts/data/supabase_post_gateway.dart';
import 'package:pulso/features/posts/domain/post.dart';

final postGatewayProvider = Provider<PostGateway>(
  (ref) => SupabasePostGateway(ref.watch(supabaseClientProvider)),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(
    gateway: ref.watch(postGatewayProvider),
    currentUserId: () => ref.read(currentUserIdProvider),
  ),
);

final postFeedProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).fetchFeed(),
);

final likePostProvider = FutureProvider.family<void, String>((ref, postId) async {
  await ref.read(postRepositoryProvider).likePost(postId);
  ref.invalidate(postFeedProvider);
});

final unlikePostProvider =
    FutureProvider.family<void, String>((ref, postId) async {
  await ref.read(postRepositoryProvider).unlikePost(postId);
  ref.invalidate(postFeedProvider);
});
