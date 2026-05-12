import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/providers/current_user_provider.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/profile/application/profile_repository.dart';
import 'package:pulso/features/profile/data/profile_gateway.dart';
import 'package:pulso/features/profile/data/supabase_profile_gateway.dart';
import 'package:pulso/features/profile/domain/profile.dart';

final profileGatewayProvider = Provider<ProfileGateway>(
  (ref) => SupabaseProfileGateway(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    gateway: ref.watch(profileGatewayProvider),
    currentUserId: () => ref.read(currentUserIdProvider),
  ),
);

final currentProfileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).fetchCurrentProfile(),
);

final profileByIdProvider = FutureProvider.family<Profile?, String>(
  (ref, userId) =>
      ref.watch(profileRepositoryProvider).fetchProfileById(userId),
);
