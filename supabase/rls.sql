-- ============================================================================
-- Smart Muezzin — Row Level Security (RLS)
-- ============================================================================
-- Run AFTER schema.sql. Every table below has RLS enabled.
--
-- Principles:
--  * Public (anonymous) users may READ active + approved content only.
--  * Only role = 'admin' / 'moderator' (profiles.role) may WRITE content.
--  * A user may read/update ONLY their own profile row, and may never
--    change their own role (that update is blocked by policy + trigger).
--  * admin_audit_log is INSERT-only for admins and READ-only for admins;
--    nobody (not even admins) may UPDATE or DELETE audit rows.
--  * Reports: anyone signed in may insert their own report; only
--    moderators/admins may read all reports or change their status.
--  * Worship data (tasbih counts, prayer logs) is NOT stored in Supabase
--    at all in this build — it stays on the device. The "usage stats"
--    the admin panel shows are aggregate counts only (e.g. number of
--    users), never individual worship data.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "profiles: users read own profile" on public.profiles;
create policy "profiles: users read own profile"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

drop policy if exists "profiles: users update own non-role fields" on public.profiles;
create policy "profiles: users update own non-role fields"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Role changes are admin-only. The trigger below is a second line of
-- defence: it rejects any UPDATE that changes `role` unless the caller
-- is an admin (the policy above would otherwise allow a user to edit
-- their own row, so the trigger must enforce the role rule).
create or replace function public.prevent_self_promotion()
returns trigger
language plpgsql
as $$
begin
  if old.role is distinct from new.role and not public.is_admin() then
    raise exception 'Only an admin can change a user role.';
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_prevent_self_promotion on public.profiles;
create trigger profiles_prevent_self_promotion
  before update of role on public.profiles
  for each row execute function public.prevent_self_promotion();

-- Admins may update any profile (role changes) and may read all profiles.
drop policy if exists "profiles: admins manage all profiles" on public.profiles;
create policy "profiles: admins manage all profiles"
  on public.profiles for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- admin_audit_log — insert-only for admins, read-only for admins.
-- ---------------------------------------------------------------------------
alter table public.admin_audit_log enable row level security;

drop policy if exists "audit: admins insert" on public.admin_audit_log;
create policy "audit: admins insert"
  on public.admin_audit_log for insert
  with check (public.is_admin() and admin_id = auth.uid());

drop policy if exists "audit: admins read" on public.admin_audit_log;
create policy "audit: admins read"
  on public.admin_audit_log for select
  using (public.is_admin());

-- No UPDATE / DELETE policy on purpose: audit rows are immutable.

-- ---------------------------------------------------------------------------
-- Content tables: azkar, hadith, reciters, muezzins, events, cities,
-- translations.
-- Public read: is_active = true (and review_status = 'approved' where the
-- column exists). Write: moderators/admins only.
-- ---------------------------------------------------------------------------
alter table public.azkar enable row level security;
alter table public.hadith enable row level security;
alter table public.reciters enable row level security;
alter table public.muezzins enable row level security;
alter table public.events enable row level security;
alter table public.cities enable row level security;
alter table public.translations enable row level security;

drop policy if exists "azkar: public read approved" on public.azkar;
create policy "azkar: public read approved"
  on public.azkar for select
  using (is_active = true and review_status = 'approved');

drop policy if exists "azkar: moderators write" on public.azkar;
create policy "azkar: moderators write"
  on public.azkar for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

drop policy if exists "hadith: public read approved" on public.hadith;
create policy "hadith: public read approved"
  on public.hadith for select
  using (is_active = true and review_status = 'approved');

drop policy if exists "hadith: moderators write" on public.hadith;
create policy "hadith: moderators write"
  on public.hadith for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

-- Reciters / muezzins / events / cities / translations have no review
-- column; public read is gated on is_active only.
drop policy if exists "reciters: public read active" on public.reciters;
create policy "reciters: public read active"
  on public.reciters for select using (is_active = true);
drop policy if exists "reciters: moderators write" on public.reciters;
create policy "reciters: moderators write"
  on public.reciters for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

drop policy if exists "muezzins: public read active" on public.muezzins;
create policy "muezzins: public read active"
  on public.muezzins for select using (is_active = true);
drop policy if exists "muezzins: moderators write" on public.muezzins;
create policy "muezzins: moderators write"
  on public.muezzins for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

drop policy if exists "events: public read active" on public.events;
create policy "events: public read active"
  on public.events for select using (is_active = true);
drop policy if exists "events: moderators write" on public.events;
create policy "events: moderators write"
  on public.events for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

drop policy if exists "cities: public read active" on public.cities;
create policy "cities: public read active"
  on public.cities for select using (is_active = true);
drop policy if exists "cities: moderators write" on public.cities;
create policy "cities: moderators write"
  on public.cities for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

drop policy if exists "translations: public read" on public.translations;
create policy "translations: public read"
  on public.translations for select using (true);
drop policy if exists "translations: moderators write" on public.translations;
create policy "translations: moderators write"
  on public.translations for all
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());

-- ---------------------------------------------------------------------------
-- notifications — drafts/scheduled announcements are admin-only to read
-- and write. (Delivery to end users happens through the admin panel's
-- explicit send step; the public app never reads this table directly.)
-- ---------------------------------------------------------------------------
alter table public.notifications enable row level security;

drop policy if exists "notifications: admins manage" on public.notifications;
create policy "notifications: admins manage"
  on public.notifications for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- reports — signed-in users insert their own reports; moderators/admins
-- read all and update status. Reporters can read their own reports.
-- ---------------------------------------------------------------------------
alter table public.reports enable row level security;

drop policy if exists "reports: users insert own" on public.reports;
create policy "reports: users insert own"
  on public.reports for insert
  with check (auth.uid() is not null and user_id = auth.uid());

drop policy if exists "reports: reporter reads own" on public.reports;
create policy "reports: reporter reads own"
  on public.reports for select
  using (user_id = auth.uid() or public.is_moderator_or_admin());

drop policy if exists "reports: moderators update status" on public.reports;
create policy "reports: moderators update status"
  on public.reports for update
  using (public.is_moderator_or_admin())
  with check (public.is_moderator_or_admin());
