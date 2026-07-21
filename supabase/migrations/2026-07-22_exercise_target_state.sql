-- Per-exercise incremental target state.
--
-- The progression ladder stores each user's current target for an exercise
-- (sets × reps, or sets × seconds when timed). Rows without a target fall
-- back to the initial ladder target in the app (3 × 6 reps / 3 × 10s), so
-- these columns are only written once evaluation advances the target.
--
-- The mastery target is deliberately NOT stored per exercise: it is a live
-- global training-program setting (variation_rules.mastery_target_reps /
-- mastery_target_seconds) applied at evaluation and display time.

alter table public.user_exercise_progress
  add column if not exists current_target_sets int,
  add column if not exists current_target_value int;

comment on column public.user_exercise_progress.current_target_sets is
  'Set count of the user''s current incremental target. Null = never advanced; app uses the initial ladder target.';
comment on column public.user_exercise_progress.current_target_value is
  'Per-set value of the current incremental target: reps, or seconds for timed exercises. Null = initial ladder target.';
