-- Community heatmap contributions (k≥5 aggregation server-side).
-- No ride timestamps; one row per (user, cell).

create table if not exists public.heatmap_cells (
  cell_id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  updated_at timestamptz not null default now(),
  primary key (cell_id, user_id)
);

create index if not exists heatmap_cells_cell_idx
  on public.heatmap_cells (cell_id);

alter table public.heatmap_cells enable row level security;

-- Clients do not read raw rows (would leak counts < k). Writes via service role API.
drop policy if exists "Users manage own heatmap cells" on public.heatmap_cells;
create policy "Users manage own heatmap cells"
  on public.heatmap_cells for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
