import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY dart-define values.',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;

final supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);
