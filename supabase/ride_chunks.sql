-- AetherRide ride sensor chunks (DM-10 style): private Storage + meta table.
-- Run in Supabase SQL editor (service role creates bucket via Dashboard or Storage API).

-- Meta table
create table if not exists public.ride_chunk_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  ride_id text not null,
  seq integer not null,
  storage_path text not null,
  bytes integer,
  sha256 text,
  created_at timestamptz not null default now(),
  unique (user_id, ride_id, seq)
);

create index if not exists ride_chunk_uploads_user_ride_idx
  on public.ride_chunk_uploads (user_id, ride_id);

alter table public.ride_chunk_uploads enable row level security;

create policy "Users read own ride chunks"
  on public.ride_chunk_uploads for select
  using (auth.uid() = user_id);

-- Inserts/updates go through service role from /api/ride-chunks (no direct client write).

-- Storage bucket (private). Create once:
--   insert into storage.buckets (id, name, public) values ('ride-chunks', 'ride-chunks', false);
insert into storage.buckets (id, name, public)
values ('ride-chunks', 'ride-chunks', false)
on conflict (id) do nothing;

-- No public storage policies — only service role uploads via API.
