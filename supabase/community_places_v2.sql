-- P1: Orte + Stimme-Pins. Additive. Apply when ready.
-- GET /api/community/places retries without this table (stub=true).
-- POST /api/community/places is P3; insert policy is ready.

alter table public.tour_reviews
  add column if not exists tags text[] not null default '{}',
  add column if not exists along_m double precision,
  add column if not exists pin_lat double precision,
  add column if not exists pin_lng double precision,
  add column if not exists difficulty_delta smallint,
  add column if not exists ride_id text;

alter table public.tour_reviews drop constraint if exists tour_reviews_difficulty_delta_check;
alter table public.tour_reviews
  add constraint tour_reviews_difficulty_delta_check
  check (difficulty_delta is null or difficulty_delta between -2 and 2);

alter table public.tour_photos
  add column if not exists lat double precision,
  add column if not exists lng double precision;

create table if not exists public.map_places (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'user',
  kind text not null,
  name text not null,
  lat double precision not null,
  lng double precision not null,
  tour_id text,
  tip text not null default '',
  along_m double precision,
  status text not null default 'pending'
    check (status in ('approved', 'pending', 'rejected', 'hidden')),
  author_id uuid references auth.users (id) on delete set null,
  ride_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists map_places_status_idx on public.map_places (status);
create index if not exists map_places_tour_id_idx on public.map_places (tour_id);
create index if not exists map_places_geo_idx on public.map_places (lat, lng);

alter table public.map_places enable row level security;

drop policy if exists "map_places approved read" on public.map_places;
create policy "map_places approved read"
  on public.map_places for select
  using (status = 'approved' or author_id = auth.uid());

drop policy if exists "map_places insert pending" on public.map_places;
create policy "map_places insert pending"
  on public.map_places for insert
  with check (
    auth.uid() is not null
    and status = 'pending'
    and author_id = auth.uid()
    and ride_id is not null
  );

grant select on table public.map_places to anon, authenticated;
grant insert on table public.map_places to authenticated;
