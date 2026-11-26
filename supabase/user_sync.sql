-- =====================================================================
-- User cloud sync (OPTIONAL — the app works fully without an account)
-- Smart Muezzin — Supabase
-- =====================================================================
-- Run AFTER supabase/schema.sql and supabase/rls.sql, in the SQL Editor.
-- One row per user: the local backup JSON (settings, favourites,
-- Tasbih totals, worship log, Khatma plan, reading position).
-- The app only uploads when the user turns the sync toggle ON in
-- "حسابي والمزامنة" and is signed in; the app never uploads silently.
--
-- RLS: a user can ONLY read/write their own row. No other user, and
-- no admin, can read another user's sync data through these policies.
-- =====================================================================

create table if not exists public.user_sync (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_sync enable row level security;

drop policy if exists "users manage own sync row" on public.user_sync;
create policy "users manage own sync row"
  on public.user_sync
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
