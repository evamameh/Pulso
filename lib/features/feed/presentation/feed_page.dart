import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
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
          ref.invalidate(postFeedProvider);
          await ref.read(postFeedProvider.future);
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
                      _PostCard(post: list[index]),
                ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caption = post.caption;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = currentUserId == post.userId;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.error),
                  ),
                ),
              ),
              if (isOwner)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditDialog(context, ref);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Caption'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(caption),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _LikeButton(post: post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final captionController = TextEditingController(text: post.caption ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(
            hintText: 'Enter caption',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () {
              captionController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCaption = captionController.text;
              captionController.dispose();
              
              // Close dialog and show loading
              if (context.mounted) {
                Navigator.pop(context);
              }

              try {
                debugPrint('Updating caption for post ${post.id}');
                debugPrint('New caption: $newCaption');
                
                // Update the caption in database
                await ref.read(postRepositoryProvider).updateCaption(
                      postId: post.id,
                      caption: newCaption,
                    );
                
                debugPrint('Caption update successful');
                
                // Wait a moment for database to sync
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Invalidate and refresh the feed
                ref.invalidate(postFeedProvider);
                
                // Wait for the new data to load
                await ref.read(postFeedProvider.future);
                
                debugPrint('Feed refreshed');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Caption updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint('Error updating caption: $e');
                debugPrint('Stack trace: $stackTrace');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating caption: $e'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (context.mounted) {
                Navigator.pop(context);
              }

              try {
                debugPrint('Deleting post ${post.id}');
                
                await ref.read(postRepositoryProvider).deletePost(post.id);
                
                debugPrint('Post deleted successfully');
                
                // Wait a moment for database to sync
                await Future.delayed(const Duration(milliseconds: 500));
                
                ref.invalidate(postFeedProvider);
                
                // Wait for the new data to load
                await ref.read(postFeedProvider.future);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                debugPrint('Error deleting post: $e');
                debugPrint('Stack trace: $stackTrace');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting post: $e'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        try {
          if (post.userLiked) {
            await ref.read(unlikePostProvider(post.id).future);
          } else {
            await ref.read(likePostProvider(post.id).future);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      child: Row(
        children: [
          Icon(
            post.userLiked ? Icons.favorite : Icons.favorite_border,
            color: post.userLiked ? Colors.red : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            post.likesCount.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}