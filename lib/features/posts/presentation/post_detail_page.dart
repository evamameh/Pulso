import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/features/posts/presentation/post_comments_sheet.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';
import 'package:pulso/features/posts/widgets/post_author_avatar.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postByIdProvider(postId));
    final savedIds = ref.watch(savedPostIdSetProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: const Text('Post'),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('This post could not be found.'));
          }
          final scheme = Theme.of(context).colorScheme;
          final headerFg = scheme.onSurface;
          final caption = post.caption;
          final isSaved = savedIds.contains(post.id);

          Future<void> refreshPost() async {
            ref.invalidate(postByIdProvider(postId));
            ref.invalidate(postFeedProvider);
            await ref.read(postByIdProvider(postId).future);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/users/${post.userId}'),
                          child: PostAuthorAvatar(post: post),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/users/${post.userId}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                post.displayUsername,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: headerFg,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (_, __) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.error, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/users/${post.userId}'),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: PostAuthorAvatar(post: post, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: post.displayUsername,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (caption != null && caption.isNotEmpty) ...[
                                const TextSpan(text: ' '),
                                TextSpan(text: caption),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          try {
                            final repo = ref.read(postRepositoryProvider);
                            if (post.likedByMe) {
                              await repo.unlikePost(post.id);
                            } else {
                              await repo.likePost(post.id);
                            }
                            await refreshPost();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not update like: $e')),
                            );
                          }
                        },
                        icon: Icon(
                          post.likedByMe ? Icons.favorite : Icons.favorite_border,
                        ),
                        tooltip: post.likedByMe ? 'Unlike' : 'Like',
                        style: IconButton.styleFrom(
                          foregroundColor:
                              post.likedByMe ? scheme.error : scheme.onSurface,
                        ),
                      ),
                      Text('${post.likeCount}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      IconButton(
                        onPressed: () =>
                            showPostCommentsSheet(
                              context: context,
                              postId: post.id,
                              postAuthorUserId: post.userId,
                            ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'Comments',
                      ),
                      Text('${post.commentCount}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          try {
                            final repo = ref.read(postRepositoryProvider);
                            if (isSaved) {
                              await repo.unsavePost(post.id);
                            } else {
                              await repo.savePost(post.id);
                            }
                            ref.invalidate(savedPostIdSetProvider);
                            ref.invalidate(savedPostsProvider);
                            await refreshPost();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Save failed: $e')),
                            );
                          }
                        },
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        tooltip: isSaved ? 'Remove from saved' : 'Save',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
