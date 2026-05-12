-- Run once in Supabase SQL editor so like counts can update live in the app.
-- 1) Broadcast row changes for `likes` to Realtime subscribers.
-- 2) Full replica identity so DELETE events include post_id + user_id (needed
--    to adjust counts when someone unlikes).

alter publication supabase_realtime add table public.likes;

alter table public.likes replica identity full;
