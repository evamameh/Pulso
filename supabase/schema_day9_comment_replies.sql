-- Day 9: optional parent comment for replies (same post enforced in the app).
-- Run in Supabase SQL editor on existing projects.

alter table public.comments
  add column if not exists parent_id uuid references public.comments(id) on delete cascade;
