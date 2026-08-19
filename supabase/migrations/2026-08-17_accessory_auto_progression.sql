-- Auto progression for accessory exercises.
--
-- Skill-tree steps have always climbed a ladder of their own. Accessories did
-- not: their sets × reps came straight from the catalog and their weight from
-- whatever was last logged, so nothing ever moved on its own.
--
-- With auto progression on, a reps × weight accessory climbs reps until it
-- tops its rep window, then takes a weight step and starts the window again,
-- storing where it got to in the target columns this table already has.
--
-- Null is the default and means on: every reps × weight accessory progresses
-- until the user says otherwise, and the flag is only written when they do.
-- It has no meaning for anything else — a movement measured in reps alone, a
-- hold, or a skill-tree step, which the tree manages.

alter table public.user_exercise_progress
  add column if not exists auto_progression boolean;

comment on column public.user_exercise_progress.auto_progression is
  'Whether Forma manages this accessory''s reps and weight. Null = on, the default for reps x weight accessories; false = the user turned it off. Meaningless for skill-tree steps and for anything not measured in reps x weight.';
