-- Program starting position: skipped steps and loaded working weights.
--
-- Program setup no longer starts everyone at the bottom of every tree. The
-- reported one-set maximum places the starting node, and the steps behind it
-- are recorded with a new status:
--
--   'skipped' — cleared at setup, never trained here. It reads as cleared
--   everywhere 'mastered' does (the path is open past it), but it is not a
--   claim that the user has done the work. Logging the mastery target for a
--   skipped exercise masters it for real.
--
-- The knee-dominant and hinge slots can now be loaded lifts (barbell squat,
-- Romanian deadlift), which need a working weight alongside the sets × reps
-- target. Null means bodyweight, which is every other exercise.

alter table public.user_exercise_progress
  add column if not exists current_target_weight_kg numeric;

comment on column public.user_exercise_progress.current_target_weight_kg is
  'Working weight in kg for loaded lifts (barbell squat, Romanian deadlift). Null = trained at bodyweight.';

comment on column public.user_exercise_progress.status is
  'inactive | active | mastered | skipped. skipped = cleared by program setup without being trained; counts as cleared, masters for real once the mastery target is logged.';
