-- Migration 8: Create garden_states table
-- File: supabase/migrations/20241101000008_create_garden_states.sql

create table if not exists public.garden_states (
    user_id uuid primary key references public.profiles(id) on delete cascade,
    garden_level integer not null default 1 check (garden_level >= 1),
    unlocked_items jsonb not null default '["moss_patch_starter", "wooden_sign"]'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Documentation
comment on table public.garden_states is 'User virtual garden growth state and unlocked botanical decorative items.';
comment on column public.garden_states.garden_level is 'Current level of virtual garden evolution.';
comment on column public.garden_states.unlocked_items is 'Array of item IDs unlocked in the garden.';

-- Updated_at trigger
create trigger set_garden_states_updated_at
    before update on public.garden_states
    for each row
    execute function public.handle_updated_at();

-- Auto-initialize garden_state for all existing profiles
insert into public.garden_states (user_id, garden_level, unlocked_items)
select id, 1, '["moss_patch_starter", "wooden_sign"]'::jsonb
from public.profiles
on conflict (user_id) do nothing;

-- Update handle_new_user to also initialize garden_state on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_username text;
begin
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

    insert into public.garden_states (user_id, garden_level, unlocked_items)
    values (
        new.id,
        1,
        '["moss_patch_starter", "wooden_sign"]'::jsonb
    )
    on conflict (user_id) do nothing;

    return new;
end;
$$;

-- Enable Row Level Security (RLS)
alter table public.garden_states enable row level security;

-- RLS Policies: Users manage their own garden state
create policy "Users can view own garden state"
    on public.garden_states
    for select
    using (auth.uid() = user_id);

create policy "Users can insert own garden state"
    on public.garden_states
    for insert
    with check (auth.uid() = user_id);

create policy "Users can update own garden state"
    on public.garden_states
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
