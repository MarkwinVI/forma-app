alter table public.users
  add column if not exists bodyweight_kg numeric
  check (bodyweight_kg between 20 and 400);
