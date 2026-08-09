-- Strava OAuth tokens bound to AetherRide users.
-- Apply in Supabase SQL editor (service role / dashboard).

create table if not exists public.strava_connections (
  user_id uuid primary key references auth.users (id) on delete cascade,
  athlete_id bigint,
  access_token text not null,
  refresh_token text,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

create unique index if not exists strava_connections_athlete_uidx
  on public.strava_connections (athlete_id)
  where athlete_id is not null;

alter table public.strava_connections enable row level security;

-- No direct client access — API uses service role.
drop policy if exists "Users read own strava" on public.strava_connections;
create policy "Users read own strava"
  on public.strava_connections for select
  using (auth.uid() = user_id);
