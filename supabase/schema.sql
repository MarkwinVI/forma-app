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

-- ── Training Programs ─────────────────────────────────────────────────────
-- Stores the user's selected program template and configuration.
-- `program_type`, `schedule_variant`, `track_id`, and `branch_id` map to
-- stable IDs defined in the app code for now.

create table public.user_training_programs (
  id                uuid default gen_random_uuid() primary key,
  user_id           uuid references auth.users(id) on delete cascade not null,
  program_type      text not null, -- 'full_body' | 'push_pull' | 'upper_lower'
  schedule_variant  text,          -- local schedule key, e.g. 'push_rest_pull_rest_push_pull_rest'
  frequency_per_week int not null default 3,
  accessories       jsonb not null default '[]', -- user-selected accessory config
  variation_rules   jsonb not null default '{}', -- user-selected rule toggles
  is_active         boolean not null default true,
  created_at        timestamptz default now() not null,
  updated_at        timestamptz default now() not null,
  check (frequency_per_week > 0)
);

create unique index user_training_programs_one_active_per_user_idx
  on public.user_training_programs (user_id)
  where is_active;

create index user_training_programs_user_idx
  on public.user_training_programs (user_id, updated_at desc);

alter table public.user_training_programs enable row level security;

create policy "Users manage own training programs"
  on public.user_training_programs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Progression Branches ──────────────────────────────────────────────────
-- Saves the user's chosen branch for each progression track.
-- The actual branch definitions live locally in the app.

create table public.user_progression_branches (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null,
  track_id    text not null, -- e.g. 'vertical_pull', 'skill_work', 'squat'
  branch_id   text not null, -- e.g. 'weighted_pull_up', 'l_sit'
  updated_at  timestamptz default now() not null,
  unique(user_id, track_id)
);

create index user_progression_branches_user_idx
  on public.user_progression_branches (user_id, updated_at desc);

alter table public.user_progression_branches enable row level security;

create policy "Users manage own progression branches"
  on public.user_progression_branches for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Training Program State ────────────────────────────────────────────────
-- Tracks where the user currently is in the selected split.
-- This is intentionally cursor-based rather than calendar-based, so if a user
-- misses a scheduled day the next recommended action stays the same until they
-- complete or explicitly skip that step.

create table public.user_training_program_state (
  id                 uuid default gen_random_uuid() primary key,
  program_id         uuid references public.user_training_programs(id) on delete cascade not null unique,
  user_id            uuid references auth.users(id) on delete cascade not null,
  next_step_index    int not null default 0,
  next_session_type  text not null, -- 'full_body' | 'push' | 'pull' | 'upper' | 'lower' | 'rest'
  last_session_type  text,
  last_completed_at  timestamptz,
  updated_at         timestamptz default now() not null,
  check (next_step_index >= 0)
);

create index user_training_program_state_user_idx
  on public.user_training_program_state (user_id, updated_at desc);

alter table public.user_training_program_state enable row level security;

create policy "Users manage own training program state"
  on public.user_training_program_state for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Training Session History ──────────────────────────────────────────────
-- Optional audit trail for what happened to each queued step.
-- Helps with analytics, streaks, and future recommendation logic.

create table public.user_training_session_events (
  id              uuid default gen_random_uuid() primary key,
  program_id      uuid references public.user_training_programs(id) on delete cascade not null,
  user_id         uuid references auth.users(id) on delete cascade not null,
  schedule_index  int not null,
  session_type    text not null, -- 'full_body' | 'push' | 'pull' | 'upper' | 'lower' | 'rest'
  action          text not null, -- 'completed' | 'skipped' | 'rest_taken'
  occurred_at     timestamptz default now() not null,
  notes           text,
  check (schedule_index >= 0)
);

create index user_training_session_events_program_idx
  on public.user_training_session_events (program_id, occurred_at desc);

create index user_training_session_events_user_idx
  on public.user_training_session_events (user_id, occurred_at desc);

alter table public.user_training_session_events enable row level security;

create policy "Users manage own training session events"
  on public.user_training_session_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
