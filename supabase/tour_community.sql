-- Tour community (reviews + photos) — Privacy-first, pending moderation.
-- Apply when Supabase project is ready. Mobile stays fully offline-capable
-- via TourCommunityStore; this schema is the future sync target.
-- No secrets; RLS: public read approved only; insert as pending for auth users.

-- Reviews
create table if not exists public.tour_reviews (
  id uuid primary key default gen_random_uuid(),
  tour_id text not null,
  author_id uuid references auth.users (id) on delete set null,
  author_label text not null default '',
  rating smallint not null check (rating between 1 and 5),
  body text not null default '',
  status text not null default 'pending'
    check (status in ('approved', 'pending', 'rejected', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tour_reviews_tour_id_idx
  on public.tour_reviews (tour_id);
create index if not exists tour_reviews_status_idx
  on public.tour_reviews (status);

-- Photos (pending moderation; storage paths, not blobs)
create table if not exists public.tour_photos (
  id uuid primary key default gen_random_uuid(),
  tour_id text not null,
  author_id uuid references auth.users (id) on delete set null,
  storage_path text not null,
  caption text not null default '',
  status text not null default 'pending'
    check (status in ('approved', 'pending', 'rejected', 'hidden')),
  created_at timestamptz not null default now()
);

create index if not exists tour_photos_tour_id_idx
  on public.tour_photos (tour_id);
create index if not exists tour_photos_status_idx
  on public.tour_photos (status);

alter table public.tour_reviews enable row level security;
alter table public.tour_photos enable row level security;

-- Public: only approved content
drop policy if exists "tour_reviews approved read" on public.tour_reviews;
create policy "tour_reviews approved read"
  on public.tour_reviews for select
  using (status = 'approved' or author_id = auth.uid());

drop policy if exists "tour_reviews insert pending" on public.tour_reviews;
create policy "tour_reviews insert pending"
  on public.tour_reviews for insert
  with check (
    auth.uid() is not null
    and status = 'pending'
    and author_id = auth.uid()
  );

drop policy if exists "tour_reviews delete own" on public.tour_reviews;
create policy "tour_reviews delete own"
  on public.tour_reviews for delete
  using (author_id = auth.uid());

drop policy if exists "tour_photos approved read" on public.tour_photos;
create policy "tour_photos approved read"
  on public.tour_photos for select
  using (status = 'approved' or author_id = auth.uid());

drop policy if exists "tour_photos insert pending" on public.tour_photos;
create policy "tour_photos insert pending"
  on public.tour_photos for insert
  with check (
    auth.uid() is not null
    and status = 'pending'
    and author_id = auth.uid()
  );

drop policy if exists "tour_photos delete own" on public.tour_photos;
create policy "tour_photos delete own"
  on public.tour_photos for delete
  using (author_id = auth.uid());

-- Optional storage bucket (paths referenced by tour_photos.storage_path)
insert into storage.buckets (id, name, public)
values ('tour-photos', 'tour-photos', false)
on conflict (id) do update set public = excluded.public;

grant select on table public.tour_reviews to anon, authenticated;
grant insert, delete on table public.tour_reviews to authenticated;
grant select on table public.tour_photos to anon, authenticated;
grant insert, delete on table public.tour_photos to authenticated;

drop policy if exists "tour photos owner read" on storage.objects;
create policy "tour photos owner read"
  on storage.objects for select
  using (
    bucket_id = 'tour-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "tour photos owner insert" on storage.objects;
create policy "tour photos owner insert"
  on storage.objects for insert
  with check (
    bucket_id = 'tour-photos'
    and auth.uid() is not null
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "tour photos owner delete" on storage.objects;
create policy "tour photos owner delete"
  on storage.objects for delete
  using (
    bucket_id = 'tour-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
