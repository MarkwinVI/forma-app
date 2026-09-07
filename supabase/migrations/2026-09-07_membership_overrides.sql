-- Membership overrides: free access granted from the database.
--
-- Paid membership itself lives with Apple and RevenueCat; the app reads it
-- from the RevenueCat SDK. This table is the one place the server can say
-- "this person is a member regardless" — anyone comped by hand. A row here
-- beats whatever the store says. The table must exist even while empty:
-- the app reads it on every start.
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

-- ── Comping someone by hand ───────────────────────────────────────────────
-- insert into public.user_membership_overrides (user_id, source, note, expires_at)
-- values ('<user uuid>', 'comped', 'why', null)
-- on conflict (user_id) do update
--   set source = excluded.source, note = excluded.note,
--       expires_at = excluded.expires_at;
