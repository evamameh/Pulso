import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/providers/supabase_provider.dart';
import 'package:pulso/core/router/go_router_refresh.dart';
import 'package:pulso/features/auth/presentation/login_page.dart';
import 'package:pulso/features/auth/presentation/register_page.dart';
import 'package:pulso/features/feed/presentation/feed_page.dart';
import 'package:pulso/features/posts/presentation/create_post_page.dart';
import 'package:pulso/features/profile/presentation/profile_page.dart';
import 'package:pulso/features/profile/presentation/user_profile_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = client.auth.currentSession;
      final loggedIn = session != null;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register';

      if (!loggedIn && !isAuthRoute) {
        return '/login';
      }
      if (loggedIn && isAuthRoute) {
        return '/feed';
      }
      return null;
    },
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/users/:userId',
        builder: (context, state) {
          final id = state.pathParameters['userId']!;
          return UserProfilePage(userId: id);
        },
      ),
      GoRoute(
        path: '/compose',
        builder: (context, state) => const CreatePostPage(),
      ),
    ],
  );
});
