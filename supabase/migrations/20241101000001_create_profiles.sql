-- Migration 1: Create profiles table and authentication signup triggers
-- File: supabase/migrations/20241101000001_create_profiles.sql

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Create profiles table
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    username text,
    avatar_url text,
    total_points integer not null default 0 check (total_points >= 0),
    explorer_level integer not null default 1 check (explorer_level >= 1),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Comments
comment on table public.profiles is 'User profile information including gamification points and explorer level.';
comment on column public.profiles.id is 'References auth.users(id) directly.';
comment on column public.profiles.total_points is 'Cumulative explorer points earned by the user.';
comment on column public.profiles.explorer_level is 'Current explorer level calculated from points.';

-- Indexes
create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_profiles_explorer_level on public.profiles(explorer_level);
create index if not exists idx_profiles_total_points on public.profiles(total_points desc);

-- Reusable timestamp updater
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger set_profiles_updated_at
    before update on public.profiles
    for each row
    execute function public.handle_updated_at();

-- Trigger function to automatically create profile when user signs up via auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_username text;
begin
    -- Determine default username from user metadata or email prefix
    v_username := coalesce(
        new.raw_user_meta_data->>'username',
        new.raw_user_meta_data->>'name',
        split_part(new.email, '@', 1),
        'Explorer_' || substr(new.id::text, 1, 8)
    );

    insert into public.profiles (id, username, avatar_url, total_points, explorer_level)
    values (
        new.id,
        v_username,
        new.raw_user_meta_data->>'avatar_url',
        0,
        1
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

-- Trigger on auth.users table
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- RLS Policies
-- Users can read their own profile
create policy "Users can read own profile"
    on public.profiles
    for select
    using (auth.uid() = id);

-- Users can update basic profile info (username, avatar_url)
-- Note: total_points and explorer_level are protected via BEFORE UPDATE trigger or backend RPC
create policy "Users can update own profile"
    on public.profiles
    for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- Protect total_points and explorer_level from direct client modification
create or replace function public.protect_profile_gamification_fields()
returns trigger
language plpgsql
as $$
begin
    -- If update is initiated by a regular authenticated user, forbid altering total_points or explorer_level
    if current_user <> 'postgres' and coalesce(current_setting('request.jwt.claim.role', true), '') <> 'service_role' then
        if new.total_points <> old.total_points then
            new.total_points := old.total_points;
        end if;
        if new.explorer_level <> old.explorer_level then
            new.explorer_level := old.explorer_level;
        end if;
    end if;
    return new;
end;
$$;

create trigger protect_profiles_gamification
    before update on public.profiles
    for each row
    execute function public.protect_profile_gamification_fields();
