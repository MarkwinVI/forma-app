-- Progression events ledger.
--
-- One row per progression change a saved workout earned: target increases,
-- masteries, newly activated exercises, and personal bests. The ledger is
-- the single source for three things:
--   1. The "what changed" feed on the Train tab (unseen rows, then marked
--      seen via seen_at).
--   2. Achievements (personal bests) on the Progress tab.
--   3. Rollback when the most recent session of a track is deleted — the
--      events describe exactly what to reverse.
-- It also makes progression application idempotent: a session whose events
-- already exist is never applied again.

create table public.progression_events (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade not null,
  workout_session_id  uuid references public.workout_sessions(id) on delete cascade,
  exercise_id         text not null,
  track_id            text,     -- progression track (TrainingTrack dbValue); null for standalone PBs
  kind                text not null, -- 'target_increase' | 'mastered' | 'activated' | 'personal_best'
  value_from          int,      -- per-set value before (reps or seconds); previous best for PBs
  value_to            int,      -- per-set value after; new best for PBs
  target_sets         int,      -- set count the target values apply to
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
