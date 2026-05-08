-- Day 3: Storage bucket policies for Pulso (public reads; users write only under their folder).
--
-- Prerequisites (Supabase Dashboard → Storage):
-- 1. Create buckets: `avatars`, `posts` (recommended: Public for simple public URLs — document this choice).
-- 2. If buckets are **private**, switch the app to signed URLs (`createSignedUrl`) instead of `getPublicUrl`.
--
-- Object paths must match: `{userId}/{uuid}.jpg`

-- Uncomment if Storage RLS isn't enabled yet in your project.
-- alter table storage.objects enable row level security;

drop policy if exists "Public read avatars" on storage.objects;
create policy "Public read avatars"
on storage.objects for select
using (bucket_id = 'avatars');

drop policy if exists "Users upload avatar to own folder" on storage.objects;
create policy "Users upload avatar to own folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users update own avatar folder" on storage.objects;
create policy "Users update own avatar folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users delete own avatar folder" on storage.objects;
create policy "Users delete own avatar folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Public read posts" on storage.objects;
create policy "Public read posts"
on storage.objects for select
using (bucket_id = 'posts');

drop policy if exists "Users upload post to own folder" on storage.objects;
create policy "Users upload post to own folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users update own post folder" on storage.objects;
create policy "Users update own post folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users delete own post folder" on storage.objects;
create policy "Users delete own post folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);
