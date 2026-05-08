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

## Day 2 — Auth flow

Day 2 adds signup, login (email/password via `signInWithPassword`), logout (`signOut`), session persistence via `supabase_flutter`, Riverpod `authSessionProvider` wired to `onAuthStateChange`, and GoRouter redirects that gate `/feed`.

### Supabase

1. Enable **Email** auth in Authentication → Providers.
2. Run **after** Day 1 schema:
   - `supabase/schema_day2_profiles_insert.sql`

### Run

```powershell
flutter pub get
flutter test
flutter run -d windows --dart-define=SUPABASE_URL="..." --dart-define=SUPABASE_ANON_KEY="..."
```

Optional checklist: see `docs/day2_checklist.md`.

## Day 3 — Profile + Storage + posts

### Supabase

1. Create Storage buckets **`avatars`** and **`posts`** (this code assumes **public** buckets + `getPublicUrl`).
2. Run `supabase/schema_day3_storage.sql` (policies: public read, authenticated writes only under `auth.uid()` folder names).

### App

- Profile: `/profile` (avatar upload, username + bio)
- New post: `/compose` (image + caption)
- Feed lists posts with pull-to-refresh

Checklist: `docs/day3_checklist.md`
