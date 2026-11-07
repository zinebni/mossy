-- Migration 7: Create user_achievements table
-- File: supabase/migrations/20241101000007_create_user_achievements.sql

create table if not exists public.user_achievements (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    achievement_id uuid not null references public.achievements(id) on delete cascade,
    earned_at timestamptz not null default now(),
    constraint uq_user_achievements_user_achievement unique (user_id, achievement_id)
);

-- Documentation
comment on table public.user_achievements is 'Achievements unlocked and earned by specific users.';

-- Indexes
create index if not exists idx_user_achievements_user_id on public.user_achievements(user_id);
create index if not exists idx_user_achievements_achievement_id on public.user_achievements(achievement_id);
create index if not exists idx_user_achievements_earned_at on public.user_achievements(user_id, earned_at desc);

-- Enable Row Level Security (RLS)
alter table public.user_achievements enable row level security;

-- RLS Policies: Users can read their own earned achievements
create policy "Users can view own achievements"
    on public.user_achievements
    for select
    using (auth.uid() = user_id);

-- Achievements cannot be self-awarded by client.
-- Writes are performed only via secure backend functions (SECURITY DEFINER) or service_role.
