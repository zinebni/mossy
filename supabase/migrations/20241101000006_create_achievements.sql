-- Migration 6: Create achievements table
-- File: supabase/migrations/20241101000006_create_achievements.sql

create table if not exists public.achievements (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    description text,
    required_value integer not null default 1 check (required_value >= 1),
    icon text,
    category text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Documentation
comment on table public.achievements is 'Master catalog of unlockable badges and explorer achievements.';
comment on column public.achievements.name is 'Unique display name of achievement (e.g. First Discovery, Botanist).';
comment on column public.achievements.required_value is 'Threshold required to unlock (e.g. 5 discoveries, level 3).';

-- Indexes
create index if not exists idx_achievements_category on public.achievements(category);

-- Updated_at trigger
create trigger set_achievements_updated_at
    before update on public.achievements
    for each row
    execute function public.handle_updated_at();

-- Enable Row Level Security (RLS)
alter table public.achievements enable row level security;

-- RLS Policies: Authenticated users can read achievements
create policy "Authenticated users can read achievements"
    on public.achievements
    for select
    to authenticated
    using (true);
