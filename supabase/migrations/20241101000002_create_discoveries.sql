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
