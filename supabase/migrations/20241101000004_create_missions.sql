-- Migration 4: Create missions table
-- File: supabase/migrations/20241101000004_create_missions.sql

create table if not exists public.missions (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text,
    category text not null check (category in ('daily', 'general', 'special')),
    difficulty text not null check (difficulty in ('easy', 'medium', 'hard')),
    reward_points integer not null default 10 check (reward_points > 0),
    verification_criteria jsonb not null default '{}'::jsonb,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Documentation
comment on table public.missions is 'Available exploration challenges and missions with verification criteria.';
comment on column public.missions.category is 'Mission category: daily, general, or special.';
comment on column public.missions.difficulty is 'Difficulty tier: easy, medium, or hard.';
comment on column public.missions.verification_criteria is 'JSON rules used by verify-mission function (e.g. color, family, species criteria).';

-- Indexes
create index if not exists idx_missions_category_active on public.missions(category, is_active);
create index if not exists idx_missions_difficulty on public.missions(difficulty);
create index if not exists idx_missions_created_at on public.missions(created_at desc);

-- Updated_at trigger
create trigger set_missions_updated_at
    before update on public.missions
    for each row
    execute function public.handle_updated_at();

-- Enable Row Level Security (RLS)
alter table public.missions enable row level security;

-- RLS Policies: Authenticated users can read active missions
create policy "Authenticated users can read active missions"
    on public.missions
    for select
    to authenticated
    using (is_active = true);
