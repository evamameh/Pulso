import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the signed-in user's profile row (RLS: own row only).
abstract class ProfileWriter {
  Future<void> upsertOwnProfile({
    required String userId,
    required String username,
  });
}

class SupabaseProfileWriter implements ProfileWriter {
  SupabaseProfileWriter(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsertOwnProfile({
    required String userId,
    required String username,
  }) async {
    await _client.from('profiles').upsert(
      {
        'id': userId,
        'username': username,
      },
      onConflict: 'id',
    );
  }
}
