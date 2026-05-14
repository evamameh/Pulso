import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/features/posts/domain/post.dart';
import 'package:pulso/features/posts/providers/post_providers.dart';
import 'package:pulso/features/profile/presentation/profile_realtime_listener.dart';
import 'package:pulso/features/profile/providers/follow_providers.dart';
import 'package:pulso/features/profile/providers/profile_providers.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  /// 0 = posts grid, 1 = saved (only for own profile).
  int _tab = 0;

  @override
  void didUpdateWidget(covariant UserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() => _tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final me = ref.watch(currentUserIdProvider);
    final isSelf = me == userId;

    final postsAsync = !isSelf || _tab == 0
        ? ref.watch(userPostsProvider(userId))
        : ref.watch(savedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: profileAsync.when(
          data: (p) => Text(p?.username ?? 'Profile'),
          loading: () => const Text('Profile'),
          error: (_, __) => const Text('Profile'),
        ),
      ),
      body: ProfileRealtimeListener(
        profileUserId: userId,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileByIdProvider(userId));
            ref.invalidate(userPostsProvider(userId));
            if (isSelf) {
              ref.invalidate(savedPostsProvider);
            }
            if (!isSelf) {
              ref.invalidate(isFollowingUserProvider(userId));
            }
            await Future.wait([
              ref.read(profileByIdProvider(userId).future),
              if (!isSelf || _tab == 0)
                ref.read(userPostsProvider(userId).future),
              if (isSelf && _tab == 1) ref.read(savedPostsProvider.future),
              if (!isSelf) ref.read(isFollowingUserProvider(userId).future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.toString()),
                  ),
                  data: (profile) {
                    if (profile == null) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('User not found.')),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(
                            profileId: userId,
                            username: profile.username,
                            bio: profile.bio,
                            avatarUrl: profile.avatarUrl,
                            followerCount: profile.followerCount,
                            isSelf: isSelf,
                          ),
                          if (isSelf) ...[
                            const SizedBox(height: 12),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment<int>(
                                  value: 0,
                                  label: Text('Posts'),
                                  icon: Icon(Icons.grid_on_outlined),
                                ),
                                ButtonSegment<int>(
                                  value: 1,
                                  label: Text('Saved'),
                                  icon: Icon(Icons.bookmark_outline),
                                ),
                              ],
                              selected: {_tab},
                              onSelectionChanged: (s) {
                                setState(() => _tab = s.first);
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    final msg = !isSelf || _tab == 0
                        ? 'No posts yet.'
                        : 'No saved posts yet.';
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(msg)),
                    );
                  }
                  return _postGridSliver(context, posts);
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(e.toString()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _postGridSliver(BuildContext context, List<Post> posts) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = posts[index];
          final tileBg =
              Theme.of(context).colorScheme.surfaceContainerHighest;
          return Material(
            color: tileBg,
            child: InkWell(
              onTap: () => context.push('/posts/${p.id}'),
              child: CachedNetworkImage(
                imageUrl: p.imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                placeholder: (_, __) => ColoredBox(
                  color: tileBg,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: tileBg,
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
        childCount: posts.length,
      ),
    ),
  );
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.profileId,
    required this.username,
    this.bio,
    this.avatarUrl,
    required this.followerCount,
    required this.isSelf,
  });

  final String profileId;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final int followerCount;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final url = avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipOval(
            child: SizedBox(
              width: 96,
              height: 96,
              child: (url != null && url.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.person, size: 48),
                      ),
                    )
                  : ColoredBox(
                      color: Colors.black12,
                      child: Center(
                        child: Text(
                          username.isNotEmpty
                              ? username.substring(0, 1).toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          username,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$followerCount ${followerCount == 1 ? 'follower' : 'followers'}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (bio != null && bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            bio!.trim(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        if (isSelf)
          FilledButton.tonal(
            onPressed: () => context.push('/profile'),
            child: const Text('Edit profile'),
          )
        else
          _FollowActions(profileId: profileId),
      ],
    );
  }
}

class _FollowActions extends ConsumerStatefulWidget {
  const _FollowActions({required this.profileId});

  final String profileId;

  @override
  ConsumerState<_FollowActions> createState() => _FollowActionsState();
}

class _FollowActionsState extends ConsumerState<_FollowActions> {
  bool _busy = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(widget.profileId);
      } else {
        await repo.follow(widget.profileId);
      }
      ref.invalidate(isFollowingUserProvider(widget.profileId));
      ref.invalidate(profileByIdProvider(widget.profileId));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(isFollowingUserProvider(widget.profileId));

    return async.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString(), textAlign: TextAlign.center),
      data: (following) {
        if (_busy) {
          return const SizedBox(
            height: 44,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return following
            ? OutlinedButton(
                onPressed: () => _toggle(true),
                child: const Text('Unfollow'),
              )
            : FilledButton(
                onPressed: () => _toggle(false),
                child: const Text('Follow'),
              );
      },
    );
  }
}
