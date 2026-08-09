-- Bike photo Storage bucket + RLS (path: {userId}/{bikeId}.jpg).

insert into storage.buckets (id, name, public)
values ('bike-photos', 'bike-photos', true)
on conflict (id) do update set public = excluded.public;

-- Public read (URLs in sync payload); write only own folder.
drop policy if exists "bike photos public read" on storage.objects;
create policy "bike photos public read"
  on storage.objects for select
  using (bucket_id = 'bike-photos');

drop policy if exists "bike photos owner insert" on storage.objects;
create policy "bike photos owner insert"
  on storage.objects for insert
  with check (
    bucket_id = 'bike-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "bike photos owner update" on storage.objects;
create policy "bike photos owner update"
  on storage.objects for update
  using (
    bucket_id = 'bike-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "bike photos owner delete" on storage.objects;
create policy "bike photos owner delete"
  on storage.objects for delete
  using (
    bucket_id = 'bike-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
