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
        'm1000000-0000-0000-0000-000000000001',
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
        'm1000000-0000-0000-0000-000000000002',
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
        'm1000000-0000-0000-0000-000000000003',
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
        'm1000000-0000-0000-0000-000000000004',
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
        'm1000000-0000-0000-0000-000000000005',
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
        'm1000000-0000-0000-0000-000000000006',
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
        'm1000000-0000-0000-0000-000000000007',
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
        'm1000000-0000-0000-0000-000000000008',
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
