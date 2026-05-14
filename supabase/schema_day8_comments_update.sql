-- Day 8: allow comment authors to edit their own comments (RLS update).
-- Run once in Supabase SQL editor if your project was created before this policy existed.

drop policy if exists "comments_update_own" on public.comments;

create policy "comments_update_own" on public.comments
for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
