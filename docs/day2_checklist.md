# Pulso Day 2 Checklist

## Supabase

- [ ] Email/password auth enabled
- [ ] Run `supabase/schema_day2_profiles_insert.sql` (lets users insert their own profile)
- [ ] Confirm `profiles` table exists from Day 1

## App behavior

- [ ] Register stores username in user metadata and creates `profiles` row when a session is returned
- [ ] Login persists session (Supabase local storage) and navigates to feed
- [ ] Logout clears session and returns to login
- [ ] Unauthenticated users cannot open `/feed` (redirect to `/login`)

## Tests

- [ ] `flutter test` passes (AuthService unit tests)

## Riverpod

- [ ] `authSessionProvider` exposes `onAuthStateChange` as a `StreamProvider<Session?>`
