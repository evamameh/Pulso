-- Comment likes: allows users to like/unlike individual comments.
-- Run in Supabase SQL editor.

create table if not exists public.comment_likes (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(comment_id, user_id)
);

alter table public.comment_likes enable row level security;

create policy "comment_likes_select" on public.comment_likes
for select to authenticated using (true);

create policy "comment_likes_insert_own" on public.comment_likes
for insert to authenticated
with check (auth.uid() = user_id);

create policy "comment_likes_delete_own" on public.comment_likes
for delete to authenticated
using (auth.uid() = user_id);

-- Enable realtime for live like count updates on comments.
alter publication supabase_realtime add table public.comment_likes;

-- Full replica identity so DELETE events include comment_id + user_id.
alter table public.comment_likes replica identity full;
