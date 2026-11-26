-- ============================================================================
-- Smart Muezzin — Supabase schema (PostgreSQL)
-- ============================================================================
-- Run order in the Supabase SQL Editor:
--   1. schema.sql  (this file)
--   2. rls.sql
--   3. seed.sql
-- No secrets are stored in this repo. The app reads SUPABASE_URL and
-- SUPABASE_ANON_KEY from `.env` / --dart-define (see supabase/README.md).
-- Religious content rule: every row in `azkar` / `hadith` MUST carry a
-- `source`. Rows are created with `review_status = 'pending'` and are
-- only visible to the public app when `is_active = true` AND
-- `review_status = 'approved'`. See rls.sql.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type user_role as enum ('user', 'moderator', 'admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type review_status as enum ('pending', 'approved', 'rejected');
exception when duplicate_object then null; end $$;

do $$ begin
  create type report_status as enum ('open', 'in_review', 'resolved');
exception when duplicate_object then null; end $$;

do $$ begin
  create type notification_audience as enum ('all', 'admins', 'moderators');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Helper: updated_at maintenance
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles — one row per Supabase Auth user. Role is managed ONLY by admins.
-- The app never lets a user promote themselves (see rls.sql).
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  role user_role not null default 'user',
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists profiles_role_idx on public.profiles (role);
drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row when a user signs up in Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Role helpers (used by RLS policies). SECURITY DEFINER so the policies can
-- read profiles.role without recursing into RLS.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.is_moderator_or_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('moderator', 'admin')
  );
$$;

create or replace function public.my_role()
returns user_role
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- admin_audit_log — append-only. Every admin action in the Flutter admin
-- panel writes one row here. Rows are never updated or deleted by the app.
-- ---------------------------------------------------------------------------
create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles (id) on delete restrict,
  action text not null,
  target_table text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists admin_audit_log_admin_idx
  on public.admin_audit_log (admin_id, created_at desc);
create index if not exists admin_audit_log_target_idx
  on public.admin_audit_log (target_table, target_id);

-- ---------------------------------------------------------------------------
-- azkar — Hisn al-Muslim style entries. `source` is NOT NULL by design.
-- ---------------------------------------------------------------------------
create table if not exists public.azkar (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  title text not null,
  text text not null,
  source text not null,
  repetitions integer not null default 1 check (repetitions >= 1),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  review_status review_status not null default 'pending',
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists azkar_category_idx on public.azkar (category, sort_order);
drop trigger if exists azkar_set_updated_at on public.azkar;
create trigger azkar_set_updated_at
  before update on public.azkar
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- hadith — verbatim texts only. `source` is NOT NULL by design.
-- `book_total` / `included_count` make subsets honest: a book row here is
-- never presented as the complete book unless included_count = book_total.
-- ---------------------------------------------------------------------------
create table if not exists public.hadith (
  id uuid primary key default gen_random_uuid(),
  book text not null,            -- e.g. 'bukhari', 'muslim', 'nawawi', 'riyad'
  book_title text not null,      -- e.g. 'صحيح البخاري'
  number integer not null,
  text text not null,
  narrator text,
  grade text,
  chapter text not null default '',
  book_total integer,            -- total hadiths in the printed book, if known
  included_count integer,        -- how many of that book this DB contains
  source text not null,          -- e.g. 'صحيح البخاري (1)' / 'sunnah.com'
  is_active boolean not null default true,
  review_status review_status not null default 'pending',
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (book, number)
);
create index if not exists hadith_book_idx on public.hadith (book, number);
drop trigger if exists hadith_set_updated_at on public.hadith;
create trigger hadith_set_updated_at
  before update on public.hadith
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- reciters — Quran reciters. `identifier` is the AlQuran Cloud edition
-- identifier (e.g. 'ar.alafasy'); NULL means "no verified stream yet" and
-- the app must NOT invent one.
-- ---------------------------------------------------------------------------
create table if not exists public.reciters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  identifier text unique,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists reciters_set_updated_at on public.reciters;
create trigger reciters_set_updated_at
  before update on public.reciters
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- muezzins — Adhan voices. `audio_url` must be a licensed / permitted
-- stream. NULL means "no audio yet" — the app must never play a fake URL.
-- ---------------------------------------------------------------------------
create table if not exists public.muezzins (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  audio_url text,
  prayer text,                   -- e.g. 'fajr', 'all', NULL = any prayer
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists muezzins_set_updated_at on public.muezzins;
create trigger muezzins_set_updated_at
  before update on public.muezzins
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- events — Islamic occasions. Hijri month/day are the stable key; Gregorian
-- dates are ESTIMATES until the official local sighting announcement.
-- The app must display that disclaimer (see `description` wording).
-- ---------------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  hijri_month integer not null check (hijri_month between 1 and 12),
  hijri_day integer not null check (hijri_day between 1 and 30),
  hijri_date text,               -- e.g. '1 رمضان 1448هـ'
  gregorian_date date,           -- estimate only
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists events_set_updated_at on public.events;
create trigger events_set_updated_at
  before update on public.events
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- cities — calculation cities. latitude/longitude drive prayer times.
-- ---------------------------------------------------------------------------
create table if not exists public.cities (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  country text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  timezone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name_en, country)
);
create index if not exists cities_country_idx on public.cities (country, name_en);
drop trigger if exists cities_set_updated_at on public.cities;
create trigger cities_set_updated_at
  before update on public.cities
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- notifications — public announcements drafted/scheduled by admins.
-- Sending itself is done by the admin panel only after an explicit
-- confirmation step; `sent_at` is set by the sending job, never by hand.
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title_ar text not null,
  title_en text,
  body_ar text not null,
  body_en text,
  target_audience notification_audience not null default 'all',
  scheduled_at timestamptz,
  sent_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists notifications_scheduled_idx
  on public.notifications (scheduled_at) where sent_at is null;
drop trigger if exists notifications_set_updated_at on public.notifications;
create trigger notifications_set_updated_at
  before update on public.notifications
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- reports — user reports (wrong mosque data, wrong content, ...).
-- Users insert their own reports; only moderators/admins change status.
-- ---------------------------------------------------------------------------
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  type text not null,            -- e.g. 'mosque_data', 'content', 'other'
  target_id text,
  details text not null,
  status report_status not null default 'open',
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists reports_status_idx on public.reports (status, created_at desc);
drop trigger if exists reports_set_updated_at on public.reports;
create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- translations — app strings. `key` + `lang` are unique; the app falls back
-- to Arabic when a key is missing for a language.
-- ---------------------------------------------------------------------------
create table if not exists public.translations (
  id uuid primary key default gen_random_uuid(),
  key text not null,
  lang text not null check (lang in ('ar', 'en')),
  value text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (key, lang)
);
drop trigger if exists translations_set_updated_at on public.translations;
create trigger translations_set_updated_at
  before update on public.translations
  for each row execute function public.set_updated_at();
