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
-- Migration 2: Create discoveries table
-- File: supabase/migrations/20241101000002_create_discoveries.sql

create table if not exists public.discoveries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    scientific_name text not null,
    common_name text,
    family text,
    identification_score real,
    image_path text,
    ai_content jsonb not null default '{}'::jsonb,
    latitude double precision,
    longitude double precision,
    personal_notes text,
    is_favorite boolean not null default false,
    discovered_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Table & column documentation
comment on table public.discoveries is 'Recorded plant discoveries by users, including AI educational details and optional geo-location.';
comment on column public.discoveries.scientific_name is 'Botanical scientific name identified (e.g., Bellis perennis).';
comment on column public.discoveries.identification_score is 'Confidence score from identification provider (0.0 to 1.0).';
comment on column public.discoveries.ai_content is 'Structured educational payload (introduction, facts, observation tips, safety).';
comment on column public.discoveries.image_path is 'Supabase storage path to discovery image in discovery-photos bucket.';

-- Indexes
create index if not exists idx_discoveries_user_id on public.discoveries(user_id);
create index if not exists idx_discoveries_scientific_name on public.discoveries(scientific_name);
create index if not exists idx_discoveries_discovered_at on public.discoveries(discovered_at desc);
create index if not exists idx_discoveries_user_favorite on public.discoveries(user_id, is_favorite);
create index if not exists idx_discoveries_user_family on public.discoveries(user_id, family);

-- Updated_at trigger
create trigger set_discoveries_updated_at
    before update on public.discoveries
    for each row
    execute function public.handle_updated_at();

-- Enable Row Level Security (RLS)
alter table public.discoveries enable row level security;

-- RLS Policies: Users CRUD their own discoveries only
create policy "Users can view own discoveries"
    on public.discoveries
    for select
    using (auth.uid() = user_id);

create policy "Users can insert own discoveries"
    on public.discoveries
    for insert
    with check (auth.uid() = user_id);

create policy "Users can update own discoveries"
    on public.discoveries
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own discoveries"
    on public.discoveries
    for delete
    using (auth.uid() = user_id);
-- Migration 3: Create species_cache table
-- File: supabase/migrations/20241101000003_create_species_cache.sql

create table if not exists public.species_cache (
    id uuid primary key default gen_random_uuid(),
    scientific_name text not null,
    common_name text,
    family text,
    educational_content jsonb not null default '{}'::jsonb,
    language text not null default 'en',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_species_cache_scientific_name_lang unique (scientific_name, language)
);

-- Documentation
comment on table public.species_cache is 'Global cache of Gemini-generated educational content by species scientific name and language.';

-- Indexes for fast lookup
create index if not exists idx_species_cache_scientific_name on public.species_cache(scientific_name);
create index if not exists idx_species_cache_lookup on public.species_cache(lower(scientific_name), language);

-- Updated_at trigger
create trigger set_species_cache_updated_at
    before update on public.species_cache
    for each row
    execute function public.handle_updated_at();

-- Enable Row Level Security (RLS)
alter table public.species_cache enable row level security;

-- RLS Policies: Authenticated users can read cached species content
create policy "Authenticated users can read species cache"
    on public.species_cache
    for select
    to authenticated
    using (true);

-- Only service role can insert or update cache (no insert/update policy for authenticated/anon roles)
-- Service role automatically bypasses RLS in Supabase.
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
-- Migration 10: Seed initial achievements and missions
-- File: supabase/migrations/20241101000010_seed_data.sql

-- 1. Seed Achievements
insert into public.achievements (id, name, description, required_value, icon, category)
values
    (
        'a1000000-0000-0000-0000-000000000001',
        'First Discovery',
        'Record your very first plant discovery in nature.',
        1,
        'sprout',
        'discovery'
    ),
    (
        'a1000000-0000-0000-0000-000000000002',
        'Curious Explorer',
        'Identify and save 5 distinct plant discoveries.',
        5,
        'compass',
        'discovery'
    ),
    (
        'a1000000-0000-0000-0000-000000000003',
        'Flower Collector',
        'Identify and save 10 distinct botanical discoveries.',
        10,
        'flower',
        'discovery'
    ),
    (
        'a1000000-0000-0000-0000-000000000004',
        'Nature Enthusiast',
        'Document 25 discoveries across your journeys.',
        25,
        'leaf',
        'discovery'
    ),
    (
        'a1000000-0000-0000-0000-000000000005',
        'Botanical Expert',
        'Achieve a master collection of 50 plant discoveries.',
        50,
        'tree',
        'discovery'
    ),
    (
        'a1000000-0000-0000-0000-000000000006',
        'Adventure Seeker',
        'Complete 5 exploration missions.',
        5,
        'backpack',
        'missions'
    ),
    (
        'a1000000-0000-0000-0000-000000000007',
        'Mission Master',
        'Successfully complete 15 exploration challenges.',
        15,
        'trophy',
        'missions'
    ),
    (
        'a1000000-0000-0000-0000-000000000008',
        'Garden Keeper',
        'Evolve your virtual garden to level 3.',
        3,
        'watering_can',
        'garden'
    ),
    (
        'a1000000-0000-0000-0000-000000000009',
        'Master Gardener',
        'Nurture your garden sanctuary to reach level 7.',
        7,
        'garden',
        'garden'
    ),
    (
        'a1000000-0000-0000-0000-000000000010',
        'Botanist',
        'Identify plant species from 5 distinct plant families.',
        5,
        'microscope',
        'botanist'
    )
on conflict (name) do update
set
    description = excluded.description,
    required_value = excluded.required_value,
    icon = excluded.icon,
    category = excluded.category;

-- 2. Seed Initial Missions
insert into public.missions (id, title, description, category, difficulty, reward_points, verification_criteria, is_active)
values
    (
        'b1000000-0000-0000-0000-000000000001',
        'Discover a yellow flower',
        'Spot and photograph any wild or garden flower with bright yellow petals, such as a dandelion, buttercup, or sunflower.',
        'daily',
        'easy',
        10,
        '{
            "type": "color_match",
            "target_feature": "flower_color",
            "colors": ["yellow", "gold", "amber"],
            "description": "Plant or flower with yellow coloration"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000002',
        'Find a plant with 5 petals',
        'Observe nature closely and discover a flower featuring exactly five distinct petals (like a wild rose, strawberry, or periwinkle).',
        'general',
        'medium',
        20,
        '{
            "type": "morphology",
            "target_feature": "petal_count",
            "required_count": 5,
            "description": "Flower possessing 5 petals"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000003',
        'Discover a plant from the Asteraceae family',
        'Identify a member of the composite family (Asteraceae/Compositae) such as daisies, asters, chamomile, or marigolds.',
        'general',
        'medium',
        25,
        '{
            "type": "family_match",
            "family": "Asteraceae",
            "synonyms": ["Compositae"],
            "description": "Species belonging to Asteraceae family"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000004',
        'Identify a tree species',
        'Look up! Identify a deciduous or coniferous tree species in a park, forest, or neighborhood sidewalk.',
        'general',
        'medium',
        20,
        '{
            "type": "plant_type",
            "growth_forms": ["tree", "large arbor", "conifer"],
            "description": "Botanical tree or woody arbor"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000005',
        'Find a purple flower',
        'Locate and capture a flower with calming purple, violet, or lavender blooms like lavender, bellflower, or lilac.',
        'daily',
        'easy',
        10,
        '{
            "type": "color_match",
            "target_feature": "flower_color",
            "colors": ["purple", "violet", "lavender", "magenta", "lilac"],
            "description": "Flower with purple/violet hues"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000006',
        'Discover 3 different plant families',
        'Broaden your botanical horizons by identifying specimens from at least three distinct plant families in your journal.',
        'general',
        'hard',
        50,
        '{
            "type": "family_diversity",
            "required_unique_families": 3,
            "description": "User has logged at least 3 distinct plant families"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000007',
        'Find a plant with interesting leaf shapes',
        'Discover and photograph a plant distinguished by unusual leaf margins, deep lobes, or heart-shaped foliage (e.g. ivy, ferns, oak, or monstera).',
        'general',
        'easy',
        15,
        '{
            "type": "morphology",
            "target_feature": "leaf_shape",
            "attributes": ["lobed", "serrated", "compound", "cordate", "palmate"],
            "description": "Distinctive or complex leaf geometry"
        }'::jsonb,
        true
    ),
    (
        'b1000000-0000-0000-0000-000000000008',
        'Identify a medicinal herb',
        'Find and record a recognized traditional culinary or medicinal herb, such as mint, thyme, rosemary, chamomile, or sage.',
        'special',
        'hard',
        40,
        '{
            "type": "herb_medicinal",
            "keywords": ["herb", "medicinal", "culinary", "aromatic", "lamiaceae"],
            "description": "Recognized culinary or medicinal botanical herb"
        }'::jsonb,
        true
    )
on conflict (id) do update
set
    title = excluded.title,
    description = excluded.description,
    category = excluded.category,
    difficulty = excluded.difficulty,
    reward_points = excluded.reward_points,
    verification_criteria = excluded.verification_criteria,
    is_active = excluded.is_active;
-- Migration 11: Create core gamification and reward database functions
-- File: supabase/migrations/20241101000011_create_functions.sql

-- 1. Function: calculate_explorer_level(points INT) -> INT
-- Formula designed with progressive milestones:
-- Level 1: 0 - 49 pts (Novice Explorer)
-- Level 2: 50 - 149 pts (Sprout Scout)
-- Level 3: 150 - 299 pts (Pathfinder)
-- Level 4: 300 - 499 pts (Flora Observer)
-- Level 5: 500 - 749 pts (Botanical Ranger)
-- Level 6: 750 - 1049 pts (Canopy Master)
-- Level 7: 1050 - 1399 pts (Ecosystem Naturalist)
-- Level 8: 1400 - 1799 pts (Wilderness Sage)
-- Level 9: 1800 - 2249 pts (Nature Guardian)
-- Level 10+: 2250+ (Grand Mossy Steward, +1 level per 500 pts)
create or replace function public.calculate_explorer_level(p_points integer)
returns integer
language plpgsql
immutable
as $$
begin
    if p_points is null or p_points < 50 then
        return 1;
    elsif p_points < 150 then
        return 2;
    elsif p_points < 300 then
        return 3;
    elsif p_points < 500 then
        return 4;
    elsif p_points < 750 then
        return 5;
    elsif p_points < 1050 then
        return 6;
    elsif p_points < 1400 then
        return 7;
    elsif p_points < 1800 then
        return 8;
    elsif p_points < 2250 then
        return 9;
    else
        return 10 + floor((p_points - 2250) / 500)::integer;
    end if;
end;
$$;

comment on function public.calculate_explorer_level is 'Calculates explorer level based on cumulative total points.';

-- 2. Function: check_and_award_achievement(p_user_id UUID, p_achievement_name TEXT) -> JSONB
create or replace function public.check_and_award_achievement(
    p_user_id uuid,
    p_achievement_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_achievement record;
    v_already_earned boolean;
    v_qualifies boolean := false;
    v_discovery_count integer := 0;
    v_mission_count integer := 0;
    v_family_count integer := 0;
    v_garden_level integer := 1;
begin
    -- 1. Find achievement record
    select * into v_achievement
    from public.achievements
    where lower(name) = lower(p_achievement_name);

    if not found then
        return jsonb_build_object(
            'awarded', false,
            'reason', 'Achievement not found: ' || p_achievement_name
        );
    end if;

    -- 2. Check if already unlocked
    select exists (
        select 1 from public.user_achievements
        where user_id = p_user_id and achievement_id = v_achievement.id
    ) into v_already_earned;

    if v_already_earned then
        return jsonb_build_object(
            'awarded', false,
            'reason', 'Already earned',
            'achievement_id', v_achievement.id,
            'name', v_achievement.name
        );
    end if;

    -- 3. Evaluate criteria based on achievement name
    case lower(v_achievement.name)
        when 'first discovery' then
            select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
            v_qualifies := v_discovery_count >= 1;

        when 'curious explorer' then
            select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
            v_qualifies := v_discovery_count >= 5;

        when 'flower collector' then
            select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
            v_qualifies := v_discovery_count >= 10;

        when 'nature enthusiast' then
            select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
            v_qualifies := v_discovery_count >= 25;

        when 'botanical expert' then
            select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
            v_qualifies := v_discovery_count >= 50;

        when 'adventure seeker' then
            select count(*) into v_mission_count from public.user_missions
            where user_id = p_user_id and status = 'completed';
            v_qualifies := v_mission_count >= 5;

        when 'mission master' then
            select count(*) into v_mission_count from public.user_missions
            where user_id = p_user_id and status = 'completed';
            v_qualifies := v_mission_count >= 15;

        when 'garden keeper' then
            select coalesce(garden_level, 1) into v_garden_level
            from public.garden_states where user_id = p_user_id;
            v_qualifies := v_garden_level >= 3;

        when 'master gardener' then
            select coalesce(garden_level, 1) into v_garden_level
            from public.garden_states where user_id = p_user_id;
            v_qualifies := v_garden_level >= 7;

        when 'botanist' then
            select count(distinct lower(trim(family))) into v_family_count
            from public.discoveries
            where user_id = p_user_id and family is not null and trim(family) <> '';
            v_qualifies := v_family_count >= 5;

        else
            -- Generic fallback based on required_value if known category
            if v_achievement.category = 'discovery' then
                select count(*) into v_discovery_count from public.discoveries where user_id = p_user_id;
                v_qualifies := v_discovery_count >= v_achievement.required_value;
            elsif v_achievement.category = 'missions' then
                select count(*) into v_mission_count from public.user_missions
                where user_id = p_user_id and status = 'completed';
                v_qualifies := v_mission_count >= v_achievement.required_value;
            elsif v_achievement.category = 'garden' then
                select coalesce(garden_level, 1) into v_garden_level
                from public.garden_states where user_id = p_user_id;
                v_qualifies := v_garden_level >= v_achievement.required_value;
            end if;
    end case;

    -- 4. If qualified, insert into user_achievements
    if v_qualifies then
        insert into public.user_achievements (user_id, achievement_id, earned_at)
        values (p_user_id, v_achievement.id, now())
        on conflict (user_id, achievement_id) do nothing;

        return jsonb_build_object(
            'awarded', true,
            'achievement_id', v_achievement.id,
            'name', v_achievement.name,
            'description', v_achievement.description,
            'icon', v_achievement.icon
        );
    end if;

    return jsonb_build_object(
        'awarded', false,
        'reason', 'Criteria not yet met',
        'name', v_achievement.name
    );
end;
$$;

comment on function public.check_and_award_achievement is 'Evaluates qualification criteria for an achievement and records unlock if met.';

-- Helper: evaluate_all_achievements(p_user_id UUID) -> JSONB array
create or replace function public.evaluate_all_achievements(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_ach record;
    v_res jsonb;
    v_newly_awarded jsonb := '[]'::jsonb;
begin
    for v_ach in select name from public.achievements order by required_value asc loop
        v_res := public.check_and_award_achievement(p_user_id, v_ach.name);
        if (v_res->>'awarded')::boolean is true then
            v_newly_awarded := v_newly_awarded || jsonb_build_array(v_res);
        end if;
    end loop;
    return v_newly_awarded;
end;
$$;

-- 3. Function: award_points_to_user(p_user_id UUID, p_points INT, p_reason TEXT, p_reference_id TEXT)
create or replace function public.award_points_to_user(
    p_user_id uuid,
    p_points integer,
    p_reason text,
    p_reference_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_current_points integer;
    v_current_level integer;
    v_new_points integer;
    v_new_level integer;
    v_ledger_id uuid;
    v_new_achievements jsonb := '[]'::jsonb;
begin
    -- 1. Validate user existence
    select total_points, explorer_level into v_current_points, v_current_level
    from public.profiles
    where id = p_user_id
    for update;

    if not found then
        raise exception 'Profile for user % not found', p_user_id;
    end if;

    -- 2. Idempotency Check on reference_id
    if p_reference_id is not null and trim(p_reference_id) <> '' then
        if exists (
            select 1 from public.points_ledger
            where user_id = p_user_id and reference_id = trim(p_reference_id)
        ) then
            return jsonb_build_object(
                'success', true,
                'status', 'already_awarded',
                'idempotent', true,
                'user_id', p_user_id,
                'points_awarded', 0,
                'total_points', v_current_points,
                'explorer_level', v_current_level,
                'new_achievements', '[]'::jsonb
            );
        end if;
    end if;

    -- 3. Insert transaction into points_ledger
    insert into public.points_ledger (
        user_id,
        points,
        reason,
        reference_id
    ) values (
        p_user_id,
        p_points,
        p_reason,
        nullif(trim(p_reference_id), '')
    )
    returning id into v_ledger_id;

    -- 4. Calculate new totals
    v_new_points := greatest(0, v_current_points + p_points);
    v_new_level := public.calculate_explorer_level(v_new_points);

    -- 5. Update profiles record directly
    update public.profiles
    set
        total_points = v_new_points,
        explorer_level = v_new_level,
        updated_at = now()
    where id = p_user_id;

    -- 6. Evaluate any achievements newly unlocked by this activity
    v_new_achievements := public.evaluate_all_achievements(p_user_id);

    return jsonb_build_object(
        'success', true,
        'status', 'awarded',
        'idempotent', false,
        'ledger_id', v_ledger_id,
        'user_id', p_user_id,
        'points_awarded', p_points,
        'total_points', v_new_points,
        'explorer_level', v_new_level,
        'level_up', (v_new_level > v_current_level),
        'new_achievements', v_new_achievements
    );
end;
$$;

comment on function public.award_points_to_user is 'Secure transactional point awarding with idempotency, profile recalculation, and achievement progression checks.';
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
