-- Paywall follow-up.
--
-- A day after someone reaches "Your training program is ready" without
-- starting the trial, the paywall-follow-up edge function emails them once
-- to ask why. It needs two things from the database and a clock.
--
-- 1. webhook_events now records every RevenueCat event, acted on or not,
--    with the user it concerns — so "has this user ever had a trial or a
--    subscription?" has a local answer before RevenueCat itself is asked.
-- 2. email_sends remembers who has had which one-off email, keyed by kind
--    so the next such email lands here too rather than growing a table.
-- 3. pg_cron calls the function every hour through pg_net. The job reads
--    its Authorization header out of Vault at run time;
--    tool/setup_paywall_follow_up.sh stores the same value there and as
--    the function's PAYWALL_FOLLOW_UP_SECRET.
--
-- No policies on either table on purpose: only the service role (the edge
-- functions) reads or writes them.

alter table public.webhook_events
  add column app_user_id text, -- the Supabase user id, as the app logs into RevenueCat with it
  add column environment text; -- 'PRODUCTION' | 'SANDBOX'

create index webhook_events_app_user_idx
  on public.webhook_events (app_user_id);

create table public.email_sends (
  user_id  uuid references auth.users(id) on delete cascade not null,
  kind     text not null, -- 'paywall_follow_up'
  sent_at  timestamptz default now() not null,
  primary key (user_id, kind)
);

alter table public.email_sends enable row level security;

-- ── Hourly job ────────────────────────────────────────────────────────────

create extension if not exists pg_cron;
grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;

create extension if not exists pg_net with schema extensions;

-- Quarter past, every hour. Until the function is deployed and the secret
-- is in Vault the call fails on its own and nothing else happens.
select cron.schedule(
  'paywall-follow-up-hourly',
  '15 * * * *',
  $$
  select net.http_post(
    url := 'https://pcardimuewjcegourlgo.supabase.co/functions/v1/paywall-follow-up',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', (
        select decrypted_secret from vault.decrypted_secrets
        where name = 'paywall_follow_up_secret'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $$
);
