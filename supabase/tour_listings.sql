-- User-Tour listing gate (candidate → listed | reverted).
-- Explore pins only for state = listed. Share links stay on candidate.
-- Confirmations = distinct riders (approved stimme or completed ride).

create table if not exists public.tour_listings (
  route_id text primary key,
  owner_id uuid references auth.users (id) on delete cascade,
  state text not null default 'candidate'
    check (state in ('candidate', 'listed', 'reverted')),
  candidate_since timestamptz not null default now(),
  listed_at timestamptz,
  share_epoch int not null default 0,
  center_lng double precision,
  center_lat double precision,
  name text not null default '',
  updated_at timestamptz not null default now()
);

create index if not exists tour_listings_state_idx
  on public.tour_listings (state);
create index if not exists tour_listings_center_idx
  on public.tour_listings (center_lng, center_lat)
  where state in ('candidate', 'listed');

create table if not exists public.tour_listing_confirmations (
  tour_id text not null,
  rider_id uuid not null references auth.users (id) on delete cascade,
  kind text not null default 'stimme'
    check (kind in ('stimme', 'ride')),
  created_at timestamptz not null default now(),
  primary key (tour_id, rider_id)
);

create index if not exists tour_listing_confirmations_tour_idx
  on public.tour_listing_confirmations (tour_id);

alter table public.tour_listings enable row level security;
alter table public.tour_listing_confirmations enable row level security;

drop policy if exists "tour_listings public read active" on public.tour_listings;
create policy "tour_listings public read active"
  on public.tour_listings for select
  using (
    state in ('candidate', 'listed')
    or owner_id = auth.uid()
  );

drop policy if exists "tour_listings upsert own" on public.tour_listings;
create policy "tour_listings upsert own"
  on public.tour_listings for insert
  with check (owner_id = auth.uid());

drop policy if exists "tour_listings update own" on public.tour_listings;
create policy "tour_listings update own"
  on public.tour_listings for update
  using (owner_id = auth.uid());

drop policy if exists "tour_listing_confirmations read" on public.tour_listing_confirmations;
create policy "tour_listing_confirmations read"
  on public.tour_listing_confirmations for select
  using (true);

drop policy if exists "tour_listing_confirmations insert own" on public.tour_listing_confirmations;
create policy "tour_listing_confirmations insert own"
  on public.tour_listing_confirmations for insert
  with check (rider_id = auth.uid());

grant select on table public.tour_listings to anon, authenticated;
grant insert, update on table public.tour_listings to authenticated;
grant select on table public.tour_listing_confirmations to anon, authenticated;
grant insert on table public.tour_listing_confirmations to authenticated;
