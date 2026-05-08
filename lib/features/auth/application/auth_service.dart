import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pulso/features/auth/data/auth_operations.dart';
import 'package:pulso/features/auth/data/profile_writer.dart';

/// Wraps signup/login/logout plus first-time profile creation when a session exists.
class AuthService {
  AuthService({
    required AuthOperations authOperations,
    required ProfileWriter profileWriter,
  })  : _auth = authOperations,
        _profiles = profileWriter;

  final AuthOperations _auth;
  final ProfileWriter _profiles;

  Session? get currentSession => _auth.currentSession;

  Stream<Session?> authSessionChanges() =>
      _auth.onAuthStateChange.map((event) => event.session);

  /// Returns the auth response so callers can show "confirm email" when session is null.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    final user = response.session?.user ?? response.user;
    if (response.session != null && user != null) {
      await _profiles.upsertOwnProfile(userId: user.id, username: username);
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.session?.user;
    if (user != null) {
      final username = user.userMetadata?['username'] as String?;
      if (username != null && username.isNotEmpty) {
        await _profiles.upsertOwnProfile(userId: user.id, username: username);
      }
    }
    return response;
  }

  Future<void> signOut() => _auth.signOut();
}
