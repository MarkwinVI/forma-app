-- RevenueCat retries a webhook until it gets a 2xx, and can deliver the same
-- event more than once. The revenuecat-webhook edge function inserts each
-- event id here before acting on it; a duplicate insert means "already
-- handled" and no second email goes out.
--
-- No policies on purpose: only the service role (the edge function) reads or
-- writes this table.

create table public.webhook_events (
  id          text primary key,
  event_type  text not null,
  received_at timestamptz default now() not null
);

alter table public.webhook_events enable row level security;
