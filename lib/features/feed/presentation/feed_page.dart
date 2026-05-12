import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/auth/providers/auth_providers.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';

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
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
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
          data: (list) => list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    Text(
                      'No posts yet.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _PostCard(post: list[index], ref: ref),
                ),
        ),
      ),
    );
  }
}

/// Instagram-style circular author avatar shown left of the username in the
/// feed post header. Uses [CachedNetworkImage] when [Post.authorAvatarUrl] is
/// present; otherwise falls back to [Post.displayInitial] over a tinted
/// circle. A 1px ring sits flush with the avatar edge for the polished look.
class _PostAuthorAvatar extends StatelessWidget {
  const _PostAuthorAvatar({required this.post, this.size = 38});

  final Post post;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = post.displayInitial;
    final url = post.authorAvatarUrl?.trim();
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

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.ref});

  final Post post;
  final WidgetRef ref;

  Future<void> _openComments(BuildContext context) async {
    final client = ref.read(supabaseClientProvider);
    List<Map<String, dynamic>> rows = [];
    try {
      final data = await client
          .from('comments')
          .select('id, body, created_at, profiles(username)')
          .eq('post_id', post.id)
          .order('created_at', ascending: true);
      rows = List<Map<String, dynamic>>.from(data as List<dynamic>);
    } catch (_) {
      rows = [];
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: rows.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No comments yet.'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = rows[i];
                    final prof = r['profiles'];
                    final name = prof is Map<String, dynamic>
                        ? (prof['username'] as String? ?? 'user')
                        : 'user';
                    return ListTile(
                      dense: true,
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(r['body'] as String? ?? ''),
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerForeground = scheme.onSurface;
    final caption = post.caption;
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
                    child: _PostAuthorAvatar(post: post),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'More',
                  style: IconButton.styleFrom(foregroundColor: headerForeground),
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
                      child: _PostAuthorAvatar(post: post, size: 32),
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
                      await ref.read(postFeedProvider.notifier).toggleLike(post);
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
                Text('${post.likeCount}', style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  onPressed: () => _openComments(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Comments',
                ),
                Text('${post.commentCount}', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Save',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
