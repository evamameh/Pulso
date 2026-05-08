# Pulso Day 3 Checklist

## Supabase Storage

- [ ] Create buckets **`avatars`** and **`posts`**
- [ ] Choose **public buckets** (current app uses `getPublicUrl`) **or** private + signed URLs (requires code change)
- [ ] Run `supabase/schema_day3_storage.sql` so users can only upload under `{auth.uid()}/…`

## App features

- [ ] Profile: view avatar (placeholder if empty), edit username + bio, upload avatar
- [ ] Create post: pick image + optional caption, appears on feed
- [ ] Feed: pull-to-refresh posts

## Verify

- [ ] New files follow `{userId}/{uuid}.jpg` in Storage
- [ ] `flutter test` passes
