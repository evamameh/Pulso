import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/features/auth/providers/auth_providers.dart';

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authSessionProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
});
