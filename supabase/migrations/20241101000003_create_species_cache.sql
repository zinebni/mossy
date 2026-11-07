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
