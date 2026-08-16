-- Additive: Zustand-Tags an Stimmen. Apply when ready; API retries without tags.
alter table public.tour_reviews
  add column if not exists tags text[] not null default '{}';
