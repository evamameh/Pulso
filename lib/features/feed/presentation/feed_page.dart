import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/features/auth/providers/auth_providers.dart';
import 'package:pulso/features/posts/domain/comment.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:pulso/features/posts/presentation/post_comments_sheet.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';
import 'package:pulso/features/posts/widgets/post_author_avatar.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulso Feed'),
        actions: [
          IconButton(
            tooltip: 'My profile & saved',
            onPressed: () {
              final id = ref.read(currentUserIdProvider);
              if (id != null) {
                context.push('/users/$id');
              } else {
                context.push('/profile');
              }
            },
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'New post',
            onPressed: () => context.push('/compose'),
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(postFeedProvider.notifier).refresh();
        },
        child: posts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [Text(e.toString())],
          ),
          data: (list) {
            final savedIds = ref.watch(savedPostIdSetProvider).valueOrNull ?? {};
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  Text(
                    'No posts yet.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) => _PostCard(
                post: list[index],
                ref: ref,
                isSaved: savedIds.contains(list[index].id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.ref,
    required this.isSaved,
  });

  final Post post;
  final WidgetRef ref;
  final bool isSaved;

  Future<void> _openComments(BuildContext context) async {
<<<<<<< HEAD
    await showPostCommentsSheet(context: context, postId: post.id);
=======
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _CommentsSheet(post: post, ref: ref),
    );
>>>>>>> ff4f7255b6d33b887cf872c885026593f490edfe
  }

  Future<void> _editCaption(BuildContext context) async {
    final controller = TextEditingController(text: post.caption ?? '');
    final newCaption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Write a caption...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newCaption == null) return; // dialog dismissed
    if (newCaption == (post.caption ?? '')) return; // no change

    try {
      await ref.read(postFeedProvider.notifier).updateCaption(
            postId: post.id,
            caption: newCaption,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update caption: $e')),
      );
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(postFeedProvider.notifier).deletePost(post.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerForeground = scheme.onSurface;
    final caption = post.caption;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = currentUserId != null && currentUserId == post.userId;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Post header: GestureDetector avoids web ink painting over avatar
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            post.displayUsername,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: headerForeground,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: headerForeground),
                    tooltip: 'More',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCaption(context);
                          break;
                        case 'delete':
                          _deletePost(context);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Caption'),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: scheme.error),
                          title: Text('Delete Post',
                              style: TextStyle(color: scheme.error)),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                    tooltip: 'More',
                    style:
                        IconButton.styleFrom(foregroundColor: headerForeground),
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
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(postFeedProvider.notifier)
                          .toggleLike(post);
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
                  onPressed: () => _openComments(context),
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
  }
}


class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.comment, this.size = 32});

  final Comment comment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = comment.displayInitial;
    final url = comment.avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    final initialStyle = TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: size * 0.42,
    );

    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Text(initial, style: initialStyle)),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post, required this.ref});

  final Post post;
  final WidgetRef ref;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    try {
      await ref.read(postRepositoryProvider).postComment(
            postId: widget.post.id,
            body: body,
          );
      _commentController.clear();
      // Refresh comments
      ref.invalidate(postCommentsProvider(widget.post.id));
      // Refresh feed to update comment count
      ref.invalidate(postFeedProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post comment: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(postRepositoryProvider).deleteComment(commentId);
      ref.invalidate(postCommentsProvider(widget.post.id));
      ref.invalidate(postFeedProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete comment: $e')),
      );
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    try {
      final repo = ref.read(postRepositoryProvider);
      if (comment.likedByMe) {
        await repo.unlikeComment(comment.id);
      } else {
        await repo.likeComment(comment.id);
      }
      ref.invalidate(postCommentsProvider(widget.post.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update comment like: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(postCommentsProvider(widget.post.id));
    final currentUserId = ref.watch(currentUserIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                    width: 48), // Balances the back button for centering
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: comments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading comments: $e'),
                ),
              ),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No comments yet.'),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final comment = list[i];
                        final canDelete = currentUserId == comment.userId ||
                            currentUserId == widget.post.userId;

                        final diff =
                            DateTime.now().difference(comment.createdAt);
                        String timeAgo;
                        if (diff.inDays > 7) {
                          timeAgo =
                              '${comment.createdAt.month}/${comment.createdAt.day}/${comment.createdAt.year}';
                        } else if (diff.inDays > 0) {
                          timeAgo = '${diff.inDays}d';
                        } else if (diff.inHours > 0) {
                          timeAgo = '${diff.inHours}h';
                        } else if (diff.inMinutes > 0) {
                          timeAgo = '${diff.inMinutes}m';
                        } else {
                          timeAgo = 'now';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CommentAvatar(comment: comment, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.body,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    // Like button row
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            iconSize: 18,
                                            onPressed: () =>
                                                _toggleCommentLike(comment),
                                            icon: Icon(
                                              comment.likedByMe
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                            ),
                                            tooltip: comment.likedByMe
                                                ? 'Unlike'
                                                : 'Like',
                                            style: IconButton.styleFrom(
                                              foregroundColor:
                                                  comment.likedByMe
                                                      ? scheme.error
                                                      : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${comment.likeCount}',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (canDelete)
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20),
                                    onPressed: () =>
                                        _deleteComment(comment.id),
                                    tooltip: 'Delete comment',
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send),
                  tooltip: 'Post comment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

