# Pulso

Community social app built with Flutter, Supabase, and Riverpod.

## Day 1 Setup

1. Install dependencies:
   - `flutter pub get`
2. Run app:
   - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
3. Apply schema:
   - Run `supabase/schema_day1.sql` in Supabase SQL editor.

## Required Environment

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Use `.env.example` as reference (do not commit real values).
