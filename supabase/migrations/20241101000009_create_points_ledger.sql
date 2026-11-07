-- Migration 9: Create points_ledger table
-- File: supabase/migrations/20241101000009_create_points_ledger.sql

create table if not exists public.points_ledger (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    points integer not null check (points <> 0),
    reason text not null,
    reference_id text,
    created_at timestamptz not null default now()
);

-- Documentation
comment on table public.points_ledger is 'Immutable ledger of all point transactions awarded or deducted, providing an audit trail and idempotency.';
comment on column public.points_ledger.reason is 'Descriptive reason for points (e.g. plant_identified, mission_completed, achievement_earned).';
comment on column public.points_ledger.reference_id is 'Optional unique external reference (e.g., mission_123_user_456, discovery_789) to prevent duplicate rewards.';

-- Indexes
create index if not exists idx_points_ledger_user_created on public.points_ledger(user_id, created_at desc);
create unique index if not exists idx_points_ledger_user_ref on public.points_ledger(user_id, reference_id) where reference_id is not null;

-- Enable Row Level Security (RLS)
alter table public.points_ledger enable row level security;

-- RLS Policies: Users can read their own points ledger
create policy "Users can view own points ledger"
    on public.points_ledger
    for select
    using (auth.uid() = user_id);

-- No direct INSERT, UPDATE, or DELETE policy for authenticated or anon users!
-- Points can ONLY be inserted via trusted backend functions (award_points_to_user) or service_role.
