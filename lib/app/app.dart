import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/router/app_router.dart';
import 'package:pulso/features/auth/providers/auth_providers.dart';

class PulsoApp extends ConsumerWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSessionProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Pulso',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
