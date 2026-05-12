import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/profile/application/follow_repository.dart';
import 'package:pulso/features/profile/data/follow_gateway.dart';
import 'package:pulso/features/profile/data/supabase_follow_gateway.dart';

final followGatewayProvider = Provider<FollowGateway>(
  (ref) => SupabaseFollowGateway(ref.watch(supabaseClientProvider)),
);

final followRepositoryProvider = Provider<FollowRepository>(
  (ref) => FollowRepository(
    gateway: ref.watch(followGatewayProvider),
    currentUserId: () => ref.read(currentUserIdProvider),
  ),
);

/// Whether the signed-in user follows [targetUserId]. False if same user or logged out.
final isFollowingUserProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) async {
    return ref.watch(followRepositoryProvider).isFollowing(targetUserId);
  },
);
