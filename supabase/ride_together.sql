-- Freeride-Zusammen — Suche + Anfrage + Mate.
-- Session-Gruppe bleibt ride_groups mit saved_route_id = 'freeride'.
-- Looks/Requests: API (service role), kein Explore, kein Live-Radar.

create table if not exists public.ride_together_looks (
  user_id uuid primary key references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  display_label text not null default '',
  looking_until timestamptz not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.ride_together_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references auth.users (id) on delete cascade,
  to_user_id uuid not null references auth.users (id) on delete cascade,
  group_id uuid not null references public.ride_groups (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (from_user_id <> to_user_id)
);

create index if not exists ride_together_requests_to_pending_idx
  on public.ride_together_requests (to_user_id)
  where status = 'pending';

create table if not exists public.ride_mates (
  user_lo uuid not null references auth.users (id) on delete cascade,
  user_hi uuid not null references auth.users (id) on delete cascade,
  first_paired_at timestamptz not null default now(),
  last_paired_at timestamptz not null default now(),
  primary key (user_lo, user_hi),
  check (user_lo < user_hi)
);

alter table public.ride_together_looks enable row level security;
alter table public.ride_together_requests enable row level security;
alter table public.ride_mates enable row level security;

-- Kein Fremd-SELECT auf Looks. API nutzt service role.
drop policy if exists "ride_together_looks self" on public.ride_together_looks;
create policy "ride_together_looks self"
  on public.ride_together_looks for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "ride_together_requests self read" on public.ride_together_requests;
create policy "ride_together_requests self read"
  on public.ride_together_requests for select
  using (from_user_id = auth.uid() or to_user_id = auth.uid());

drop policy if exists "ride_together_requests self insert" on public.ride_together_requests;
create policy "ride_together_requests self insert"
  on public.ride_together_requests for insert
  with check (from_user_id = auth.uid());

drop policy if exists "ride_together_requests to update" on public.ride_together_requests;
create policy "ride_together_requests to update"
  on public.ride_together_requests for update
  using (to_user_id = auth.uid() or from_user_id = auth.uid())
  with check (to_user_id = auth.uid() or from_user_id = auth.uid());

drop policy if exists "ride_mates self read" on public.ride_mates;
create policy "ride_mates self read"
  on public.ride_mates for select
  using (user_lo = auth.uid() or user_hi = auth.uid());

grant select, insert, update, delete on table public.ride_together_looks to authenticated;
grant select, insert, update on table public.ride_together_requests to authenticated;
grant select on table public.ride_mates to authenticated;
