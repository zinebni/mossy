-- Migration 12: Configure Supabase Storage buckets and security policies
-- File: supabase/migrations/20241101000012_storage_setup.sql

-- 1. Create discovery-photos bucket (Private, user-scoped)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'discovery-photos',
    'discovery-photos',
    false,
    10485760, -- 10MB limit
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update set
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

-- 2. Create avatars bucket (Public read, user-scoped write)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'avatars',
    'avatars',
    true,
    5242880, -- 5MB limit
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- 3. Create mossy-assets bucket (Public static assets)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'mossy-assets',
    'mossy-assets',
    true,
    20971520, -- 20MB limit
    null
)
on conflict (id) do update set
    public = true,
    file_size_limit = 20971520;

-- 4. Enable RLS on storage.objects (if not already enabled)
alter table storage.objects enable row level security;

-- Policies for discovery-photos (folder convention: {user_id}/{filename})
create policy "Users can upload discovery photos to their own folder"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'discovery-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can view their own discovery photos"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'discovery-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can update their own discovery photos"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'discovery-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can delete their own discovery photos"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'discovery-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policies for avatars
create policy "Anyone can view avatars"
    on storage.objects
    for select
    using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can update their own avatar"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy "Users can delete their own avatar"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policies for mossy-assets (public read, service role write)
create policy "Public can view mossy assets"
    on storage.objects
    for select
    using (bucket_id = 'mossy-assets');
