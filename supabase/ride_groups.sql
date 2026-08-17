-- Zusammen raus — Gruppe vor dem Tor.
-- Wired: GET/POST /api/ride-groups, /join, /close, /leave, /presence (service role).
-- Not wired: presence realtime, Explore pins. No demo riders.
-- Presence is last-point only (overwrite). Not a track log. Not heatmap.
-- RLS: members of the group only. Never public / Explore.

create table if not exists public.ride_groups (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references auth.users (id) on delete cascade,
  saved_route_id text not null,
  catalog_tour_id text,
  title text not null default '',
  start_window_start timestamptz not null,
  start_window_end timestamptz not null,
  join_code text not null,
  visibility text not null default 'private'
    check (visibility in ('public', 'private')),
  status text not null default 'scheduled'
    check (status in ('scheduled', 'open', 'riding', 'closed')),
  live_pins_allowed boolean not null default false,
  meeting_point text,
  created_at timestamptz not null default now()
);

create unique index if not exists ride_groups_join_code_active_idx
  on public.ride_groups (join_code)
  where status <> 'closed';

create table if not exists public.ride_group_members (
  group_id uuid not null references public.ride_groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  display_label text not null default '',
  joined_at timestamptz not null default now(),
  live_opt_in boolean not null default false,
  primary key (group_id, user_id)
);

-- Ephemeral last point. No history. Quantize in the client before write.
create table if not exists public.ride_group_presence (
  group_id uuid not null references public.ride_groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  lng double precision,
  lat double precision,
  updated_at timestamptz not null default now(),
  visibility text not null default 'hidden_opt_out'
    check (visibility in (
      'live',
      'stale',
      'hidden_zone',
      'hidden_offline',
      'hidden_opt_out',
      'hidden_window',
      'hidden_not_member'
    )),
  primary key (group_id, user_id)
);

alter table public.ride_groups enable row level security;
alter table public.ride_group_members enable row level security;
alter table public.ride_group_presence enable row level security;

-- Avoid recursive RLS. Join-by-code is an API (service role), not a public SELECT.
create or replace function public.is_ride_group_member(gid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1 from public.ride_groups g
      where g.id = gid and g.host_user_id = auth.uid()
    )
    or exists (
      select 1 from public.ride_group_members m
      where m.group_id = gid and m.user_id = auth.uid()
    );
$$;

drop policy if exists "ride_groups member read" on public.ride_groups;
create policy "ride_groups member read"
  on public.ride_groups for select
  using (public.is_ride_group_member(id));

drop policy if exists "ride_groups host insert" on public.ride_groups;
create policy "ride_groups host insert"
  on public.ride_groups for insert
  with check (auth.uid() is not null and host_user_id = auth.uid());

drop policy if exists "ride_groups host update" on public.ride_groups;
create policy "ride_groups host update"
  on public.ride_groups for update
  using (host_user_id = auth.uid());

drop policy if exists "ride_group_members member read" on public.ride_group_members;
create policy "ride_group_members member read"
  on public.ride_group_members for select
  using (public.is_ride_group_member(group_id));

-- No client INSERT. Join-by-code and host-as-member go through
-- POST /api/ride-groups (service role). UUID-guessing must not work.

drop policy if exists "ride_group_members self insert" on public.ride_group_members;

drop policy if exists "ride_group_members host self insert" on public.ride_group_members;
create policy "ride_group_members host self insert"
  on public.ride_group_members for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.ride_groups g
      where g.id = group_id and g.host_user_id = auth.uid()
    )
  );

drop policy if exists "ride_group_members self update" on public.ride_group_members;
create policy "ride_group_members self update"
  on public.ride_group_members for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "ride_group_presence member read" on public.ride_group_presence;
create policy "ride_group_presence member read"
  on public.ride_group_presence for select
  using (public.is_ride_group_member(group_id));

drop policy if exists "ride_group_presence self write" on public.ride_group_presence;
create policy "ride_group_presence self write"
  on public.ride_group_presence for all
  using (user_id = auth.uid() and public.is_ride_group_member(group_id))
  with check (user_id = auth.uid() and public.is_ride_group_member(group_id));

-- Join-by-code: POST /api/ride-groups/join, not a world-readable lookup.
-- P1: postgres_changes on ride_group_presence filtered by group_id.
-- Do not enable Realtime Presence channels until the HUD layer exists.
-- Heatmap (heatmap_cells, k≥5, no timestamps) stays a separate pipeline.

grant select, insert, update on table public.ride_groups to authenticated;
grant select, insert, update on table public.ride_group_members to authenticated;
grant select, insert, update, delete on table public.ride_group_presence to authenticated;
grant execute on function public.is_ride_group_member(uuid) to authenticated;
