import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/app/app.dart';
import 'package:pulso/core/config/env.dart';
import 'package:pulso/core/providers/supabase_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    runApp(const _MissingConfigApp());
    return;
  }

  if (_looksLikePlaceholderSupabaseUrl(Env.supabaseUrl) ||
      _looksLikePlaceholderAnonKey(Env.supabaseAnonKey)) {
    runApp(const _PlaceholderCredentialsApp());
    return;
  }

  try {
    await initializeSupabase();
  } catch (e, stackTrace) {
    debugPrint('Supabase init failed: $e');
    debugPrint('$stackTrace');
    runApp(_SupabaseInitErrorApp(error: e));
    return;
  }

  runApp(const ProviderScope(child: PulsoApp()));
}

bool _looksLikePlaceholderSupabaseUrl(String url) {
  final u = url.trim().toLowerCase();
  return u.contains('your_ref') ||
      u.contains('your_real_ref') ||
      u.contains('your-project-ref') ||
      u.contains('replace-with') ||
      u == 'https://your-project-ref.supabase.co';
}

bool _looksLikePlaceholderAnonKey(String key) {
  final k = key.trim().toLowerCase();
  return k.contains('your_anon') ||
      k.contains('your_real') ||
      k.contains('your_long') ||
      k.contains('public_anon') ||
      k == 'anon';
}

/// Visible when `--dart-define` values were not passed (common cause of a blank web page).
class _PlaceholderCredentialsApp extends StatelessWidget {
  const _PlaceholderCredentialsApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar:
            AppBar(title: const Text('Pulso — replace Supabase placeholders')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SelectableText(
              'Your app is still using example Supabase credentials (for example '
              'your_ref.supabase.co or your_anon_key). Network calls will fail '
              'with ClientException / Failed to fetch.\n\n'
              'In Supabase: Project Settings → API\n'
              '- Copy Project URL into SUPABASE_URL\n'
              '- Copy anon public key into SUPABASE_ANON_KEY\n\n'
              'Windows PowerShell (use ONE line — trailing \\ is bash, not PowerShell):\n\n'
              'flutter run -d chrome --dart-define=SUPABASE_URL="https://abcdefghijklmnop.supabase.co" '
              '--dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIs…"\n\n'
              'Or split lines with a backtick ` at the end of each continued line:\n\n'
              'flutter run -d chrome `\n'
              '--dart-define=SUPABASE_URL="https://abcdefghijklmnop.supabase.co" `\n'
              '--dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIs…"\n\n'
              'Full restart required after changing dart-defines.',
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Pulso — configuration needed')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SelectableText(
              'Supabase environment variables are missing.\n\n'
              'Windows PowerShell: use ONE line — do not use \\ at line ends '
              '(that is bash; PowerShell treats it wrong and you get "Missing expression").\n\n'
              'flutter run -d chrome --dart-define=SUPABASE_URL="https://YOUR_REF.supabase.co" '
              '--dart-define=SUPABASE_ANON_KEY="YOUR_LONG_ANON_PUBLIC_KEY"\n\n'
              'Replace YOUR_REF / keys with Supabase Dashboard → Project Settings → API.\n\n'
              'VS Code / Cursor: add those --dart-define=... pairs to your launch '
              'configuration.',
            ),
          ),
        ),
      ),
    );
  }
}

class _SupabaseInitErrorApp extends StatelessWidget {
  const _SupabaseInitErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Pulso — Supabase error')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              'Supabase failed to initialize:\n\n$error\n\n'
              'Open the browser developer console (F12) for more detail, '
              'and double-check your SUPABASE_URL / SUPABASE_ANON_KEY values.',
            ),
          ),
        ),
      ),
    );
  }
}
