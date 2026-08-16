-- Tour-Share-Widerruf: Token bleibt in der URL, Server merkt route_id + epoch.
-- Landing /share/t prüft das — ohne Tabelle kein stilles „gültig“.
create table if not exists public.tour_share_revocations (
  route_id text not null,
  epoch int not null,
  owner_id uuid references auth.users (id) on delete set null,
  revoked_at timestamptz not null default now(),
  primary key (route_id, epoch)
);

alter table public.tour_share_revocations enable row level security;

drop policy if exists "tour_share_revocations public read" on public.tour_share_revocations;
create policy "tour_share_revocations public read"
  on public.tour_share_revocations for select
  using (true);

drop policy if exists "tour_share_revocations insert own" on public.tour_share_revocations;
create policy "tour_share_revocations insert own"
  on public.tour_share_revocations for insert
  with check (owner_id = auth.uid());

grant select on table public.tour_share_revocations to anon, authenticated;
grant insert on table public.tour_share_revocations to authenticated;
