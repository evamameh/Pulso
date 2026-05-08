-- Day 2: allow each user to create their own profile row (required for signup upsert).
-- Run in Supabase SQL editor after Day 1 schema.

drop policy if exists "profiles_insert_own" on public.profiles;

create policy "profiles_insert_own" on public.profiles
for insert to authenticated
with check (auth.uid() = id);
