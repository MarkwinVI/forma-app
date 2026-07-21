-- Progression context on workout exercise logs.
--
-- Records, per logged exercise, whether it was a skill-tree progression item
-- when the workout was saved, which progression track it belonged to, and the
-- prescribed target the user saw (sets × reps, or sets × seconds when timed).
--
-- This makes workout results attributable to progression tracks so later
-- progression logic (target ladders, rollback on deletion, idempotent
-- application) can be computed from history instead of guessed.

alter table public.workout_exercise_logs
  add column if not exists is_progression boolean not null default false,
  add column if not exists track_id text,
  add column if not exists target_sets int,
  add column if not exists target_value int;

comment on column public.workout_exercise_logs.is_progression is
  'True when this exercise was a skill-tree progression item in the program at save time. Standalone/custom exercises are false and are never auto-progressed.';
comment on column public.workout_exercise_logs.track_id is
  'Progression track the exercise was trained under, e.g. vertical_pull. Null for standalone exercises logged before this column existed.';
comment on column public.workout_exercise_logs.target_sets is
  'Prescribed set count shown to the user for this exercise in this session.';
comment on column public.workout_exercise_logs.target_value is
  'Prescribed per-set target shown to the user: reps, or seconds for timed exercises.';

create index if not exists workout_exercise_logs_user_track_idx
  on public.workout_exercise_logs (user_id, track_id, created_at desc)
  where is_progression;
