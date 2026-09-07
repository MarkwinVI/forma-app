-- Membership overrides: free access granted from the database.
--
-- Paid membership itself lives with Apple and RevenueCat; the app reads it
-- from the RevenueCat SDK. This table is the one place the server can say
-- "this person is a member regardless": existing users grandfathered in
-- when paid membership launched, and anyone comped by hand. A row here
-- beats whatever the store says.
--
-- Users can read their own row. Nothing in the app writes here — rows are
-- inserted from the SQL editor (or the service role), never by a client.

create table public.user_membership_overrides (
  user_id     uuid references auth.users(id) on delete cascade primary key,
  source      text not null check (source in ('grandfathered', 'comped')),
  note        text,
  expires_at  timestamptz, -- null = forever
  created_at  timestamptz default now() not null
);

comment on table public.user_membership_overrides is
  'Server-granted membership. A live row (expires_at null or in the future) unlocks the app without a store subscription.';

alter table public.user_membership_overrides enable row level security;

create policy "Users read own membership override"
  on public.user_membership_overrides for select
  using (auth.uid() = user_id);

-- ── Grandfathering ────────────────────────────────────────────────────────
-- Everyone who built a program before the paywalled build went live keeps
-- the app free forever. Run this the moment that build is released, and
-- once more a day later for anyone who built a program on the old build in
-- between: it is idempotent (existing rows are left alone).
--
-- Replace the timestamp with the release moment (UTC) before running.

insert into public.user_membership_overrides (user_id, source, note)
select distinct p.user_id, 'grandfathered',
       'Built a program before paid membership launched'
from public.user_training_programs p
where p.created_at < '<PAYWALL_RELEASE_TIMESTAMP_UTC>'
on conflict (user_id) do nothing;

-- ── Comping someone by hand ───────────────────────────────────────────────
-- insert into public.user_membership_overrides (user_id, source, note, expires_at)
-- values ('<user uuid>', 'comped', 'why', null)
-- on conflict (user_id) do update
--   set source = excluded.source, note = excluded.note,
--       expires_at = excluded.expires_at;
