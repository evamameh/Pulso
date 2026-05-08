import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal auth surface for [AuthService] and tests.
abstract class AuthOperations {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<AuthState> get onAuthStateChange;

  Session? get currentSession;
}

class SupabaseAuthOperations implements AuthOperations {
  SupabaseAuthOperations(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;
}
