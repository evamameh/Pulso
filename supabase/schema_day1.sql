-- Pulso Day 1 schema + baseline RLS
-- Run in Supabase SQL editor.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  image_url text not null,
  caption text,
  created_at timestamptz not null default now()
);

create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(post_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(follower_id, following_id),
  check (follower_id <> following_id)
);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;

create policy "profiles_select" on public.profiles
for select to authenticated using (true);

create policy "profiles_update_own" on public.profiles
for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "posts_select" on public.posts
for select to authenticated using (true);

create policy "posts_insert_own" on public.posts
for insert to authenticated
with check (auth.uid() = user_id);

create policy "posts_delete_own" on public.posts
for delete to authenticated
using (auth.uid() = user_id);

create policy "likes_select" on public.likes
for select to authenticated using (true);

create policy "likes_insert_own" on public.likes
for insert to authenticated
with check (auth.uid() = user_id);

create policy "likes_delete_own" on public.likes
for delete to authenticated
using (auth.uid() = user_id);

create policy "comments_select" on public.comments
for select to authenticated using (true);

create policy "comments_insert" on public.comments
for insert to authenticated
with check (auth.uid() = user_id);

create policy "comments_delete_owner_or_author" on public.comments
for delete to authenticated
using (
  auth.uid() = user_id
  or exists (
    select 1
    from public.posts p
    where p.id = comments.post_id and p.user_id = auth.uid()
  )
);

create policy "follows_select" on public.follows
for select to authenticated using (true);

create policy "follows_insert_own" on public.follows
for insert to authenticated
with check (auth.uid() = follower_id);

create policy "follows_delete_own" on public.follows
for delete to authenticated
using (auth.uid() = follower_id);
