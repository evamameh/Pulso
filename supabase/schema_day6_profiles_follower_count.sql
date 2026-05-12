-- Migration: denormalized follower_count on profiles + triggers + Realtime
-- Run in Supabase SQL editor after schema_day1 (existing projects).
-- New installs that use updated schema_day1 already include follower_count;
--   this file is still safe (IF NOT EXISTS / OR REPLACE).

alter table public.profiles
  add column if not exists follower_count integer not null default 0;

alter table public.profiles
  drop constraint if exists profiles_follower_count_nonnegative;

alter table public.profiles
  add constraint profiles_follower_count_nonnegative
  check (follower_count >= 0);

-- Backfill from follows (idempotent)
update public.profiles p
set follower_count = coalesce(
  (select count(*)::integer from public.follows f where f.following_id = p.id),
  0
);

-- Keep follower_count in sync when follows rows change (SECURITY DEFINER so
-- RLS on profiles does not block updating another user's count).
create or replace function public.increment_profile_follower_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set follower_count = follower_count + 1
  where id = new.following_id;
  return new;
end;
$$;

create or replace function public.decrement_profile_follower_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set follower_count = greatest(0, follower_count - 1)
  where id = old.following_id;
  return old;
end;
$$;

drop trigger if exists trg_follows_insert_follower_count on public.follows;
create trigger trg_follows_insert_follower_count
after insert on public.follows
for each row execute procedure public.increment_profile_follower_count();

drop trigger if exists trg_follows_delete_follower_count on public.follows;
create trigger trg_follows_delete_follower_count
after delete on public.follows
for each row execute procedure public.decrement_profile_follower_count();

-- Realtime: clients can subscribe to profiles updates (follower_count).
-- If this errors because the table is already in the publication, skip it.
alter publication supabase_realtime add table public.profiles;
