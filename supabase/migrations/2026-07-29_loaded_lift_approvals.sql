-- Loaded lifts ask before they move.
--
-- A barbell squat or Romanian deadlift has no harder variation to unlock, so
-- the progression ladder cannot carry it: left on the ladder it climbed to
-- the mastery target, mastered itself, and then sat frozen on the same bar
-- forever. Loaded lifts are now never mastered and never advanced
-- automatically. Reaching the target produces a suggestion — one more rep
-- per set, or, at the top of the rep range, more weight and the reps back at
-- the bottom — which waits here until the user approves it on the Train tab.
--
-- Only approval writes anything: the target and working weight move in
-- user_exercise_progress, and a progression_events row records what happened
-- with no workout_session_id, because the user made the call, not a session.

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

-- One open suggestion per exercise: a lift that hits its target twice before
-- the user gets to it asks once, for the newer thing.
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

-- The ledger gains the two weights, for the 'load_increase' event an
-- approved load suggestion writes.
alter table public.progression_events
  add column if not exists weight_from numeric,
  add column if not exists weight_to numeric;

comment on column public.progression_events.weight_from is
  'Working weight before a load_increase, in kg. Null for every other kind.';
comment on column public.progression_events.weight_to is
  'Working weight after a load_increase, in kg. Null for every other kind.';
comment on column public.progression_events.kind is
  'target_increase | mastered | activated | personal_best | branch_choice | load_increase';
