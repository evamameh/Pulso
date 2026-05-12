import 'package:pulso/features/profile/data/profile_gateway.dart';
import 'package:pulso/features/profile/domain/profile.dart';
import 'package:uuid/uuid.dart';

class ProfileRepository {
  ProfileRepository({
    required ProfileGateway gateway,
    required String? Function() currentUserId,
    Uuid? uuid,
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _uuid = uuid ?? const Uuid();

  final ProfileGateway _gateway;
  final String? Function() _currentUserId;
  final Uuid _uuid;

  Future<Profile?> fetchCurrentProfile() async {
    final uid = _currentUserId();
    if (uid == null) return null;
    return _gateway.fetchProfile(uid);
  }

  Future<Profile?> fetchProfileById(String userId) =>
      _gateway.fetchProfile(userId);

  Future<void> saveProfile({
    required String username,
    required String bio,
  }) async {
    if (username.trim().isEmpty) {
      throw ArgumentError('Username is required.');
    }
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot update profile without a signed-in user.');
    }
    await _gateway.updateProfileFields(
      userId: uid,
      username: username,
      bio: bio,
    );
  }

  Future<void> updateAvatar(List<int> imageBytes) async {
    final uid = _currentUserId();
    if (uid == null) {
      throw StateError('Cannot upload avatar without a signed-in user.');
    }
    final path = '$uid/${_uuid.v4()}.jpg';
    final publicUrl = await _gateway.uploadAvatarImage(
      userId: uid,
      bytes: imageBytes,
      objectPath: path,
    );
    await _gateway.updateProfileFields(
      userId: uid,
      avatarUrl: publicUrl,
    );
  }
}
