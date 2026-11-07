-- Migration 5: Create user_missions table
-- File: supabase/migrations/20241101000005_create_user_missions.sql

create table if not exists public.user_missions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    mission_id uuid not null references public.missions(id) on delete cascade,
    status text not null default 'available' check (status in ('available', 'in_progress', 'completed', 'failed')),
    verification_result jsonb,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_user_missions_user_mission unique (user_id, mission_id)
);

-- Documentation
comment on table public.user_missions is 'User mission progress, status tracking, and verification results.';

-- Indexes
create index if not exists idx_user_missions_user_id on public.user_missions(user_id);
create index if not exists idx_user_missions_mission_id on public.user_missions(mission_id);
create index if not exists idx_user_missions_status on public.user_missions(user_id, status);

-- Updated_at trigger
create trigger set_user_missions_updated_at
    before update on public.user_missions
    for each row
    execute function public.handle_updated_at();

-- Enable Row Level Security (RLS)
alter table public.user_missions enable row level security;

-- RLS Policies: Users manage their own mission progress
create policy "Users can view own mission progress"
    on public.user_missions
    for select
    using (auth.uid() = user_id);

create policy "Users can insert own mission progress"
    on public.user_missions
    for insert
    with check (auth.uid() = user_id);

create policy "Users can update own mission progress"
    on public.user_missions
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own mission progress"
    on public.user_missions
    for delete
    using (auth.uid() = user_id);
