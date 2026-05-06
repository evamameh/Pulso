# Pulso Day 1 Checklist

## Project Scaffold

- [x] Core app structure created in `lib/`
- [x] Dependencies added in `pubspec.yaml`
- [x] App router scaffolded (`/login`, `/register`, `/feed`)
- [x] Supabase bootstrap file added

## Supabase Setup

- [x] SQL schema and baseline RLS script added: `supabase/schema_day1.sql`
- [ ] Create Supabase project
- [ ] Run `supabase/schema_day1.sql` in SQL editor
- [ ] Enable Email auth provider
- [ ] Create storage buckets: `avatars`, `posts`

## Local Run

- [ ] Install dependencies: `flutter pub get`
- [ ] Start app with defines:
  - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Day 1 Exit Criteria

- [ ] Repository initialized and pushed
- [ ] App starts and shows scaffolded login/register/feed flow
- [ ] Schema exists in Supabase with RLS enabled
- [ ] Team can proceed to Day 2 auth implementation
