-- Moderation columns + public profiles. Safe to re-run.
-- AI/human/rule write via service role; users still insert pending only.

alter table public.tour_reviews
  add column if not exists moderated_at timestamptz,
  add column if not exists moderation_source text,
  add column if not exists moderation_note text,
  add column if not exists ai_labels jsonb not null default '[]'::jsonb,
  add column if not exists ai_confidence real,
  add column if not exists ai_model text;

alter table public.tour_photos
  add column if not exists moderated_at timestamptz,
  add column if not exists moderation_source text,
  add column if not exists moderation_note text,
  add column if not exists ai_labels jsonb not null default '[]'::jsonb,
  add column if not exists ai_confidence real,
  add column if not exists ai_model text,
  add column if not exists review_id uuid references public.tour_reviews (id) on delete set null;

alter table public.tour_reviews drop constraint if exists tour_reviews_moderation_source_check;
alter table public.tour_reviews
  add constraint tour_reviews_moderation_source_check
  check (moderation_source is null or moderation_source in ('ai', 'human', 'rule'));

alter table public.tour_photos drop constraint if exists tour_photos_moderation_source_check;
alter table public.tour_photos
  add constraint tour_photos_moderation_source_check
  check (moderation_source is null or moderation_source in ('ai', 'human', 'rule'));

create index if not exists tour_reviews_pending_idx
  on public.tour_reviews (created_at desc)
  where status = 'pending';
create index if not exists tour_photos_pending_idx
  on public.tour_photos (created_at desc)
  where status = 'pending';

-- Opt-in public profile (no tracks).
create table if not exists public.public_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  handle text not null,
  display_name text not null default '',
  bio text not null default '',
  sports text[] not null default '{}',
  show_ride_count boolean not null default false,
  show_preferred_sports boolean not null default true,
  region_label text,
  enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint public_profiles_handle_fmt
    check (handle ~ '^[a-z0-9_]{3,24}$')
);

create unique index if not exists public_profiles_handle_idx
  on public.public_profiles (handle);

alter table public.public_profiles enable row level security;

drop policy if exists "public_profiles read enabled" on public.public_profiles;
create policy "public_profiles read enabled"
  on public.public_profiles for select
  using (enabled = true or user_id = auth.uid());

drop policy if exists "public_profiles upsert own" on public.public_profiles;
create policy "public_profiles upsert own"
  on public.public_profiles for insert
  with check (user_id = auth.uid());

drop policy if exists "public_profiles update own" on public.public_profiles;
create policy "public_profiles update own"
  on public.public_profiles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select on table public.public_profiles to anon, authenticated;
grant insert, update on table public.public_profiles to authenticated;

-- Storage: owner can replace own tour photo (upsert).
drop policy if exists "tour photos owner update" on storage.objects;
create policy "tour photos owner update"
  on storage.objects for update
  using (
    bucket_id = 'tour-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'tour-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
