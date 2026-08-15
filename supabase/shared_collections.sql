-- Shared collections (short links). Payload = metadata + tour IDs, no GPS tracks.
create table if not exists public.shared_collections (
  short_id text primary key,
  owner_id uuid references auth.users (id) on delete set null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.shared_collections enable row level security;

drop policy if exists "shared_collections public read" on public.shared_collections;
create policy "shared_collections public read"
  on public.shared_collections for select
  using (true);

drop policy if exists "shared_collections insert own" on public.shared_collections;
create policy "shared_collections insert own"
  on public.shared_collections for insert
  with check (owner_id = auth.uid());

drop policy if exists "shared_collections delete own" on public.shared_collections;
create policy "shared_collections delete own"
  on public.shared_collections for delete
  using (owner_id = auth.uid());

grant select on table public.shared_collections to anon, authenticated;
grant insert, delete on table public.shared_collections to authenticated;
