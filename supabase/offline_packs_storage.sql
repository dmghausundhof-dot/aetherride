-- Public region packs (graph tar.gz). Path: {regionId}/{regionId}.tar.gz
-- Uploaded via: bash scripts/routing/publish-offline-packs.sh

insert into storage.buckets (id, name, public, file_size_limit)
values ('offline-packs', 'offline-packs', true, 2147483648) -- 2 GiB (DACH z12 ~1.2 GB)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit;

drop policy if exists "offline packs public read" on storage.objects;
create policy "offline packs public read"
  on storage.objects for select
  using (bucket_id = 'offline-packs');
