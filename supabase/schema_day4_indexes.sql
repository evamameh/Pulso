-- Day 4: optional indexes for profile grids and follow lookups.
-- Safe to run multiple times. Does not change RLS.
-- Run in Supabase SQL editor after Day 1 schema.

create index if not exists idx_posts_user_created
  on public.posts (user_id, created_at desc);

create index if not exists idx_follows_follower
  on public.follows (follower_id);

create index if not exists idx_follows_following
  on public.follows (following_id);
