-- AetherRide — Supabase Postgres Schema (Roadmap 4)
-- Im Supabase SQL Editor ausführen oder via CLI: supabase db push
-- Users: auth.users (Supabase Auth). profiles = Anzeigenamen/Soft-Delete.
-- Sync: user-scoped State + append-only Ops (LWW clientseitig gemerged).

-- ── Profiles ──────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text not null default 'Fahrer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_upsert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-Profile bei Auth-Signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.raw_user_meta_data->>'full_name',
      split_part(new.email, '@', 1),
      'Fahrer'
    )
  )
  on conflict (id) do update
    set email = excluded.email,
        display_name = coalesce(excluded.display_name, profiles.display_name),
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Sync State (Snapshot pro User) ────────────────────────
create table if not exists public.sync_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  revision text not null default 'rev_0',
  revision_seq integer not null default 0,
  seen_op_ids jsonb not null default '[]'::jsonb,
  entities jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.sync_state enable row level security;

create policy "sync_state_select_own"
  on public.sync_state for select
  using (auth.uid() = user_id);

create policy "sync_state_insert_own"
  on public.sync_state for insert
  with check (auth.uid() = user_id);

create policy "sync_state_update_own"
  on public.sync_state for update
  using (auth.uid() = user_id);

-- ── Sync Ops (append-only Log) ────────────────────────────
create table if not exists public.sync_ops (
  id bigserial primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  operation_id text not null,
  entity text not null,
  entity_id text not null,
  op text not null check (op in ('create', 'update', 'delete')),
  client_ts timestamptz not null,
  server_ts timestamptz not null default now(),
  revision text not null,
  payload jsonb,
  unique (user_id, operation_id)
);

create index if not exists sync_ops_user_id_idx
  on public.sync_ops (user_id, id);

create index if not exists sync_ops_user_revision_idx
  on public.sync_ops (user_id, revision);

alter table public.sync_ops enable row level security;

create policy "sync_ops_select_own"
  on public.sync_ops for select
  using (auth.uid() = user_id);

create policy "sync_ops_insert_own"
  on public.sync_ops for insert
  with check (auth.uid() = user_id);

-- Timescale optional (wenn Extension verfügbar) — Hypertable nicht erzwungen
-- select create_hypertable('sync_ops', by_range('server_ts'), if_not_exists => true);
