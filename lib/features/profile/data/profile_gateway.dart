import 'package:pulso/features/profile/domain/profile.dart';

abstract class ProfileGateway {
  Future<Profile?> fetchProfile(String userId);

  Future<void> updateProfileFields({
    required String userId,
    String? username,
    String? bio,
    String? avatarUrl,
  });

  Future<String> uploadAvatarImage({
    required String userId,
    required List<int> bytes,
    required String objectPath,
  });
}
