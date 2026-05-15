-- Day 10: live comment threads — broadcast INSERT/UPDATE/DELETE on `comments`.
-- Run in Supabase SQL editor. If the table is already in the publication, skip.

alter publication supabase_realtime add table public.comments;
