import 'dart:typed_data';

import 'package:pulso/features/profile/data/profile_gateway.dart';
import 'package:pulso/features/profile/domain/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileGateway implements ProfileGateway {
  SupabaseProfileGateway(this._client);

  final SupabaseClient _client;
  static const _bucket = 'avatars';

  @override
  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> updateProfileFields({
    required String userId,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final patch = <String, dynamic>{};
    if (username != null) patch['username'] = username;
    if (bio != null) patch['bio'] = bio;
    if (avatarUrl != null) patch['avatar_url'] = avatarUrl;
    if (patch.isEmpty) return;
    await _client.from('profiles').update(patch).eq('id', userId);
  }

  @override
  Future<String> uploadAvatarImage({
    required String userId,
    required List<int> bytes,
    required String objectPath,
  }) async {
    await _client.storage.from(_bucket).uploadBinary(
          objectPath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(_bucket).getPublicUrl(objectPath);
  }
}
