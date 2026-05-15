import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/profile/providers/profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to `profiles` row updates for [profileUserId] (e.g. follower_count)
/// and invalidates [profileByIdProvider] so the UI refetches.
class ProfileRealtimeListener extends ConsumerStatefulWidget {
  const ProfileRealtimeListener({
    super.key,
    required this.profileUserId,
    required this.child,
  });

  final String profileUserId;
  final Widget child;

  @override
  ConsumerState<ProfileRealtimeListener> createState() =>
      _ProfileRealtimeListenerState();
}

class _ProfileRealtimeListenerState
    extends ConsumerState<ProfileRealtimeListener> {
  RealtimeChannel? _channel;
  SupabaseClient? _supabase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  @override
  void didUpdateWidget(covariant ProfileRealtimeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileUserId != widget.profileUserId) {
      _detach();
      _attach();
    }
  }

  void _detach() {
    final ch = _channel;
    final client = _supabase;
    if (ch != null && client != null) {
      client.removeChannel(ch);
      _channel = null;
    }
  }

  void _attach() {
    if (widget.profileUserId.isEmpty) return;
    _detach();
    final client = ref.read(supabaseClientProvider);
    _supabase = client;
    final id = widget.profileUserId;
    final channel = client.channel('profile_row_$id');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        final row = payload.newRecord;
        if (row.isEmpty) return;
        if (!mounted) return;
        final rid = row['id'] as String?;
        if (rid != id) return;
        ref.invalidate(profileByIdProvider(id));
        final me = ref.read(currentUserIdProvider);
        if (me == id) {
          ref.invalidate(currentProfileProvider);
        }
      },
    );
    channel.subscribe();
    _channel = channel;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
