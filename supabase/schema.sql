-- Run this in your Supabase SQL editor (https://supabase.com/dashboard)

-- ── Users ─────────────────────────────────────────────────────────────────

create table public.users (
  id          uuid references auth.users (id) on delete cascade primary key,
  email       text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz default now() not null
);

alter table public.users enable row level security;

create policy "Users can view their own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can upsert their own profile"
  on public.users for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id);

-- ── Exercise Progress ─────────────────────────────────────────────────────
-- Tracks each user's status (inactive / active / mastered) per exercise.

create table public.user_exercise_progress (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  exercise_id text not null,  -- matches Exercise.id in the local catalog
  status      text not null default 'inactive', -- 'inactive' | 'active' | 'mastered'
  updated_at  timestamptz default now() not null,
  unique(user_id, exercise_id)
);

alter table public.user_exercise_progress enable row level security;

create policy "Users manage own progress"
  on public.user_exercise_progress for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Exercise Logs ─────────────────────────────────────────────────────────
-- Each row is one training session for one exercise.
-- sets: [{reps: int, weight_kg: float, notes?: string}]
-- total_reps and total_volume_kg are pre-computed for fast progress queries.

create table public.exercise_logs (
  id              uuid default gen_random_uuid() primary key,
  user_id         uuid references auth.users(id) on delete cascade not null,
  exercise_id     text not null,
  logged_at       timestamptz default now() not null,
  sets            jsonb not null default '[]',
  total_reps      int not null default 0,
  total_volume_kg float not null default 0,
  notes           text
);

alter table public.exercise_logs enable row level security;

create policy "Users manage own logs"
  on public.exercise_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Useful index for progress/regression queries per exercise
create index exercise_logs_user_exercise_idx
  on public.exercise_logs (user_id, exercise_id, logged_at desc);
