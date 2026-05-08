import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/auth/application/auth_service.dart';
import 'package:pulso/features/auth/data/auth_operations.dart';
import 'package:pulso/features/auth/data/profile_writer.dart';

final authOperationsProvider = Provider<AuthOperations>(
  (ref) => SupabaseAuthOperations(ref.watch(supabaseClientProvider)),
);

final profileWriterProvider = Provider<ProfileWriter>(
  (ref) => SupabaseProfileWriter(ref.watch(supabaseClientProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    authOperations: ref.watch(authOperationsProvider),
    profileWriter: ref.watch(profileWriterProvider),
  ),
);

/// Drives auth-gated navigation; mirrors `onAuthStateChange` session.
final authSessionProvider = StreamProvider<Session?>(
  (ref) {
    final service = ref.watch(authServiceProvider);
    return service.authSessionChanges();
  },
);
