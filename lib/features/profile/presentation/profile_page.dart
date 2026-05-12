import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/features/profile/domain/profile.dart';
import 'package:pulso/features/profile/presentation/profile_realtime_listener.dart';
import 'package:pulso/features/profile/providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentProfileProvider);

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
        title: const Text('Profile'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No profile found for this account.'),
            );
          }
          return ProfileRealtimeListener(
            profileUserId: profile.id,
            child: _ProfileBody(
              profile: profile,
              onSaved: () => ref.invalidate(currentProfileProvider),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.profile,
    required this.onSaved,
  });

  final Profile profile;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.profile.username != widget.profile.username ||
        oldWidget.profile.bio != widget.profile.bio) {
      _usernameCtrl.text = widget.profile.username;
      _bioCtrl.text = widget.profile.bio ?? '';
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateAvatar(bytes.toList());
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveFields() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).saveProfile(
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.profile.avatarUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: url == null || url.isEmpty
                      ? const ColoredBox(
                          color: Colors.black26,
                          child: Icon(Icons.person, size: 48),
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                ),
              ),
              Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _saving ? null : _pickAvatar,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.add_a_photo,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.profile.followerCount} '
          '${widget.profile.followerCount == 1 ? 'follower' : 'followers'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bioCtrl,
          decoration: const InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _saveFields,
          child: _saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile'),
        ),
      ],
    );
  }
}
