import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/features/auth/presentation/login_page.dart';
import 'package:pulso/features/auth/presentation/register_page.dart';
import 'package:pulso/features/feed/presentation/feed_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedPage(),
      ),
    ],
  );
});
