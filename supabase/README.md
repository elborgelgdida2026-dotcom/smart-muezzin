# Supabase Backend — المؤذن الذكي (Smart Muezzin)

This folder is the **real backend** for the Admin Panel (spec section 27).
Without a live Supabase project, the admin screens in the Flutter app show
a setup screen — they never show fake users or fake content.

> **Honest status:** this backend was written and SQL-checked here, but it
> was **NOT tested against a live Supabase project** (none exists on this
> machine). Run the steps below on a real project and confirm each step
> succeeds before publishing.

## Files

| File | What it does |
|---|---|
| `schema.sql` | All tables, enums, indexes, `updated_at` triggers, role helpers (`is_admin()`, `is_moderator_or_admin()`), and the `handle_new_user()` Auth trigger that creates a `profiles` row on sign-up. |
| `rls.sql` | Row Level Security on every table. Public read = active + approved content only. Writes = moderator/admin only. Users can only touch their own profile (and can never promote themselves — enforced by policy **and** a trigger). Audit log is insert-only. |
| `seed.sql` | Real seed data generated from the app's bundled datasets: 15 Azkar (verbatim), 258 Hadith (Nawawi 42 complete; Bukhari 100/7,589, Muslim 100/7,563, Riyad 16 — subsets labelled as such), 12 reciters (edition identifiers filled only where verified), 12 Egyptian cities, 6 Islamic events (Gregorian dates are **estimates** until the official sighting announcement), 10 core translation keys. Muezzins and notifications are intentionally **not** seeded. Re-running is safe (idempotent inserts). |

## 1. Create the Supabase project

1. Go to https://supabase.com/dashboard → **New project**.
2. Name it `smart-muezzin`, pick a region close to your users (e.g. Frankfurt
   for Egypt/Europe), set a strong **database password** and store it in a
   password manager.
3. Wait for the project to finish provisioning.
4. In the dashboard go to **Project Settings → API** and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`
   
   Never put the **service_role key** in the app. It bypasses RLS and must
   stay on a server only.

## 2. Run the SQL files (in this order)

In the dashboard open **SQL Editor → New query**, paste the whole file,
press **Run**, and confirm there are no errors before moving on:

1. `schema.sql`
2. `rls.sql`
3. `seed.sql`
4. `user_sync.sql` — the optional user cloud-sync table (one row per
   user, RLS: a user can only read/write their own row). Needed only
   if you want the "حسابي والمزامنة" feature; the admin panel works
   without it.

Verify with these quick checks in the SQL Editor:

```sql
select count(*) from public.azkar;    -- expect 15
select count(*) from public.hadith;   -- expect 258
select count(*) from public.reciters; -- expect 12
select count(*) from public.cities;   -- expect 12
select count(*) from public.events;   -- expect 6
```

## 3. Create the first admin user

1. In the Flutter app, open **المزيد → لوحة تحكم الإدارة** and tap
   **إنشاء حساب** (sign up) with the admin's email and a strong password.
   (Or create the user in the dashboard under **Authentication → Users**.)
2. In the SQL Editor, promote that user — replace the email:

```sql
update public.profiles
set role = 'admin'
where email = 'admin@example.com';
```

3. Sign in again in the app. The admin panel now opens. Only this user
   (and anyone you promote the same way) can enter it.

> **Never** promote a user by editing the app code or by letting a user
> change their own role — the database trigger blocks self-promotion.

## 4. Two-factor authentication (MFA) for admins

Supabase Auth supports MFA (TOTP) natively:

1. Dashboard → **Authentication → Policies / MFA** → enable **TOTP**
   (and optionally set "MFA required for admins" if your plan offers it).
2. Each admin should enrol a TOTP authenticator from the admin panel's
   login screen flow (the app surfaces the account's assurance level in
   **لوحة تحكم الإدارة → الرئيسية** after sign-in).
3. **Recommended policy:** require MFA for every `admin` account, and
   rotate the database password + service_role key if either ever leaks.

The app itself does not store passwords — Supabase Auth does.

## 5. Connect the Flutter app

In the project root, copy `.env.example` to `.env` and fill in:

```env
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...   # anon public key ONLY
```

`.env` is git-ignored (see `.gitignore`) — never commit it.

For CI builds (GitHub Actions), pass the same values as `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Without these values the app works fully in its normal (local) mode and
the admin screens show the setup instructions instead of fake data.

## 6. What the admin panel can do (once connected)

- **Users & roles:** list users, change roles (admin only), see role history
  in the audit log.
- **Content:** create/edit/deactivate Azkar and Hadith. Every new or edited
  religious item is created as **pending review** and is invisible to the
  public app until an admin approves it with a verified `source`.
- **Reciters / Muezzins / Events / Cities:** manage the lists; Muezzin
  audio URLs must be licensed/permitted — empty URLs never play.
- **Notifications:** draft and schedule public announcements; sending
  requires an explicit confirmation tap in the panel.
- **Reports:** review user reports (open → in review → resolved).
- **Audit log:** every admin action is recorded (who, what, when, details)
  and cannot be edited or deleted from the app.
- **Usage stats:** aggregate counts only (users, active content, reports) —
  individual worship data (Tasbih counts, prayer logs) is **not** stored in
  Supabase at all; it stays on each user's device.

## 7. Backups

Dashboard → **Database → Backups** (or use `pg_dump` against the
connection string in Project Settings → Database). Keep a backup before
every schema change.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Admin login works but panel says "not authorized" | The `profiles` row has role `user`. Run the promote SQL in step 3 and sign in again. |
| Public app sees no Azkar/Hadith | Rows are `pending` or `is_active = false`. Approve them in the admin panel (content review). |
| `relation "public.profiles" does not exist` | `schema.sql` was not run, or ran in the wrong project. Re-run it first. |
| RLS blocks a write that should work | The signed-in user's role is not moderator/admin, or the JWT is stale — sign out and back in. |
