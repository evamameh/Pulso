-- Day 7: private saved posts (`post_saves` only — no notifications).
-- Run in Supabase SQL editor after Day 1.

create table if not exists public.post_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, post_id)
);

create index if not exists idx_post_saves_user_created
  on public.post_saves (user_id, created_at desc);

alter table public.post_saves enable row level security;

create policy "post_saves_select_own" on public.post_saves
for select to authenticated using (auth.uid() = user_id);

create policy "post_saves_insert_own" on public.post_saves
for insert to authenticated with check (auth.uid() = user_id);

create policy "post_saves_delete_own" on public.post_saves
for delete to authenticated using (auth.uid() = user_id);
