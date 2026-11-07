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
