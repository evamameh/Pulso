import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulso/features/auth/application/auth_service.dart';
import 'package:pulso/features/auth/data/auth_operations.dart';
import 'package:pulso/features/auth/data/profile_writer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthOperations extends Mock implements AuthOperations {}

class MockProfileWriter extends Mock implements ProfileWriter {}

void main() {
  late MockAuthOperations auth;
  late MockProfileWriter profiles;
  late AuthService subject;

  setUp(() {
    auth = MockAuthOperations();
    profiles = MockProfileWriter();
    subject = AuthService(authOperations: auth, profileWriter: profiles);
    registerFallbackValue(<String, dynamic>{});
  });

  test('signOut delegates to auth operations', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    await subject.signOut();
    verify(() => auth.signOut()).called(1);
  });

  test('signUp with no session does not write profile', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await subject.signUp(
      email: 'a@b.com',
      password: 'secret123',
      username: 'u1',
    );

    verifyNever(
      () => profiles.upsertOwnProfile(
        userId: any(named: 'userId'),
        username: any(named: 'username'),
      ),
    );
  });

  test('signIn delegates to password sign-in', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await subject.signIn(email: 'a@b.com', password: 'x');

    verify(
      () => auth.signInWithPassword(email: 'a@b.com', password: 'x'),
    ).called(1);
  });

  test('signUp forwards username metadata', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await subject.signUp(
      email: 'x@y.com',
      password: 'pass',
      username: 'alice',
    );

    verify(
      () => auth.signUp(
        email: 'x@y.com',
        password: 'pass',
        data: {'username': 'alice'},
      ),
    ).called(1);
  });
}
