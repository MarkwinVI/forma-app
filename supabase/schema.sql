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
-- Tracks each user's status (inactive / active / mastered / skipped) per
-- exercise, plus their current incremental target on the progression ladder.
-- Null targets mean "never advanced": the app falls back to the initial
-- ladder target (3 × 6 reps / 3 × 10s timed). The mastery target is a live
-- global program setting and is intentionally not stored here.
--
-- 'skipped' is a step program setup cleared without training it: the
-- reported one-set maximum started the user further up the tree. It counts
-- as cleared, and logging the mastery target masters it for real.

create table public.user_exercise_progress (
  id                       uuid default gen_random_uuid() primary key,
  user_id                  uuid references auth.users(id) on delete cascade not null,
  exercise_id              text not null,  -- matches Exercise.id in the local catalog
  status                   text not null default 'inactive', -- 'inactive' | 'active' | 'mastered' | 'skipped'
  current_target_sets      int,     -- set count of the current incremental target
  current_target_value     int,     -- per-set reps (or seconds when timed)
  current_target_weight_kg numeric, -- working weight for loaded lifts; null = bodyweight
  updated_at               timestamptz default now() not null,
  unique(user_id, exercise_id)
);

alter table public.user_exercise_progress enable row level security;

create policy "Users manage own progress"
  on public.user_exercise_progress for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Workout Sessions ──────────────────────────────────────────────────────
-- A workout session is the parent record for one saved workout.
-- Child rows in workout_exercise_logs store the exercises and performed sets.

create table public.workout_sessions (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references auth.users(id) on delete cascade not null,
  title        text not null, -- 'Full Body' | 'Push' | 'Pull' | 'Upper' | 'Lower'
  session_type text not null, -- 'full_body' | 'push' | 'pull' | 'upper' | 'lower' | 'rest'
  schedule_source text not null default 'planned', -- 'planned' | 'future_planned' | 'ad_hoc'
  planned_date date,
  planned_step_index int,
  started_at   timestamptz not null,
  finished_at  timestamptz not null,
  created_at   timestamptz default now() not null,
  check (planned_step_index is null or planned_step_index >= 0)
);

create index workout_sessions_user_finished_idx
  on public.workout_sessions (user_id, finished_at desc);

alter table public.workout_sessions enable row level security;

create policy "Users manage own workout sessions"
  on public.workout_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Workout Exercise Logs ─────────────────────────────────────────────────
-- Each row is one exercise performed inside one workout session.
-- sets: [{reps?: int, duration_seconds?: int, weight_kg?: float, notes?: string}]
-- Totals are pre-computed for fast history and progress queries.
-- Progression context (is_progression, track_id, target_*) records what the
-- program prescribed at save time, so progression logic can attribute results
-- to tracks and roll changes back from history.

create table public.workout_exercise_logs (
  id                     uuid default gen_random_uuid() primary key,
  workout_session_id     uuid references public.workout_sessions(id) on delete cascade not null,
  user_id                uuid references auth.users(id) on delete cascade not null,
  exercise_id            text not null,
  order_index            int not null default 0,
  sets                   jsonb not null default '[]',
  total_reps             int not null default 0,
  total_duration_seconds int not null default 0,
  total_volume_kg        float not null default 0,
  is_progression         boolean not null default false,
  track_id               text,     -- e.g. 'vertical_pull'; null for standalone
  target_sets            int,      -- prescribed set count shown to the user
  target_value           int,      -- prescribed per-set reps (or seconds when timed)
  created_at             timestamptz default now() not null,
  check (order_index >= 0)
);

create index workout_exercise_logs_session_idx
  on public.workout_exercise_logs (workout_session_id, order_index asc);

create index workout_exercise_logs_user_exercise_idx
  on public.workout_exercise_logs (user_id, exercise_id, created_at desc);

create index workout_exercise_logs_user_track_idx
  on public.workout_exercise_logs (user_id, track_id, created_at desc)
  where is_progression;

alter table public.workout_exercise_logs enable row level security;

create policy "Users manage own workout exercise logs"
  on public.workout_exercise_logs for all
  using (
    auth.uid() = user_id
    and exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = auth.uid()
    )
  );

-- ── Progression Events ────────────────────────────────────────────────────
-- One row per progression change a saved workout earned: target increases,
-- masteries, newly activated exercises, and personal bests. Powers the
-- "what changed" feed (seen_at), achievements, deletion rollback, and makes
-- progression application idempotent per session.

create table public.progression_events (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade not null,
  workout_session_id  uuid references public.workout_sessions(id) on delete cascade,
  exercise_id         text not null,
  track_id            text,     -- progression track; null for standalone PBs
  kind                text not null, -- 'target_increase' | 'mastered' | 'activated' | 'personal_best' | 'branch_choice' | 'load_increase'
  value_from          int,      -- per-set value before (reps or seconds); previous best for PBs
  value_to            int,      -- per-set value after; new best for PBs
  target_sets         int,      -- set count the target values apply to
  weight_from         numeric,  -- for 'load_increase': working weight before, in kg
  weight_to           numeric,  -- for 'load_increase': working weight after, in kg
  related_exercise_id text,     -- for 'activated': the mastered exercise that unlocked it
  created_at          timestamptz default now() not null,
  seen_at             timestamptz -- null until the user has seen it in the feed
);

create index progression_events_user_created_idx
  on public.progression_events (user_id, created_at desc);

create index progression_events_session_idx
  on public.progression_events (workout_session_id);

create index progression_events_user_unseen_idx
  on public.progression_events (user_id)
  where seen_at is null;

alter table public.progression_events enable row level security;

create policy "Users manage own progression events"
  on public.progression_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Progression Suggestions ───────────────────────────────────────────────
-- Changes to loaded lifts (barbell squat, Romanian deadlift) waiting on the
-- user. Those lifts have no harder variation to unlock, so they are never
-- mastered and never advanced automatically: reaching the target proposes
-- one more rep per set, or — at the top of the rep range — more weight with
-- the reps back at the bottom. Approving writes the target and weight in
-- user_exercise_progress and records a progression_events row.

create table public.user_progression_suggestions (
  id                 uuid default gen_random_uuid() primary key,
  user_id            uuid references auth.users(id) on delete cascade not null,
  exercise_id        text not null,  -- matches Exercise.id in the local catalog
  workout_session_id uuid references public.workout_sessions(id) on delete cascade,
  kind               text not null,  -- 'rep_increase' | 'load_increase'
  target_sets        int not null,
  from_value         int not null,   -- per-set reps now
  to_value           int not null,   -- per-set reps proposed
  from_weight_kg     numeric,        -- working weight now; null = never set
  to_weight_kg       numeric,        -- working weight proposed
  created_at         timestamptz default now() not null,
  resolved_at        timestamptz,    -- null while the suggestion is open
  resolution         text            -- 'approved' | 'dismissed'
);

-- One open suggestion per exercise: the newest proposal replaces the last.
create unique index user_progression_suggestions_open_idx
  on public.user_progression_suggestions (user_id, exercise_id)
  where resolved_at is null;

create index user_progression_suggestions_user_idx
  on public.user_progression_suggestions (user_id, created_at desc);

alter table public.user_progression_suggestions enable row level security;

create policy "Users manage own progression suggestions"
  on public.user_progression_suggestions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Skill Tracks ──────────────────────────────────────────────────────────
-- Skills as independent progression tracks: one row per skill tree the user
-- runs (or has paused). Several tracks can cover the same movement pattern.
-- included = false pauses the track, retaining its branch here and its
-- exercise statuses/targets in user_exercise_progress.

create table public.user_skill_tracks (
  id                uuid default gen_random_uuid() primary key,
  user_id           uuid references auth.users(id) on delete cascade not null,
  skill_category_id text not null,  -- SkillCategory.id in the local catalog
  branch_id         text not null,  -- active training path within the category
  included          boolean not null default true,
  created_at        timestamptz default now() not null,
  updated_at        timestamptz default now() not null,
  unique(user_id, skill_category_id)
);

create index user_skill_tracks_user_idx
  on public.user_skill_tracks (user_id, updated_at desc);

alter table public.user_skill_tracks enable row level security;

create policy "Users manage own skill tracks"
  on public.user_skill_tracks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

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
  goal_skills       jsonb not null default '[]', -- exercise ids of long-term goal skills
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
  planned_date    date,
  workout_session_id uuid references public.workout_sessions(id) on delete set null,
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

-- ── Onboarding Profiles ───────────────────────────────────────────────────
-- One row per user with the answers from the post-signup onboarding flow.
-- Deleted with the account, so a re-registered user goes through setup again.

create table public.user_onboarding_profiles (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade not null unique,
  archetype           text not null, -- 'generalist' | 'technician' | 'specialist' | 'powerhouse' | 'heavyweight' | 'builder' | 'natural' | 'mover' | 'artist'
  radar_balanced      boolean not null default true,
  radar_angle_deg     double precision, -- radar dot direction; null when balanced
  age                 int not null,
  gender              text, -- 'f' | 'm' | 'na'
  training_frequency  text, -- '0' | '1-2' | '3-4' | '5+' sessions per week
  completed_at        timestamptz default now() not null,
  check (age between 16 and 100)
);

alter table public.user_onboarding_profiles enable row level security;

create policy "Users manage own onboarding profile"
  on public.user_onboarding_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Account Deletion ──────────────────────────────────────────────────────
-- Called from the app's Settings page. Deleting the auth.users row cascades
-- through every public table above, wiping all of the user's data.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'delete_account requires an authenticated user';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
