-- Migration: planned schedule metadata for workout history and session events.
-- Existing sessions are treated as planned so current history keeps driving
-- schedule and streak behavior after the app update.

alter table public.workout_sessions
  add column if not exists schedule_source text not null default 'planned',
  add column if not exists planned_date date,
  add column if not exists planned_step_index int;

alter table public.workout_sessions
  add constraint workout_sessions_planned_step_nonnegative
  check (planned_step_index is null or planned_step_index >= 0)
  not valid;

alter table public.workout_sessions
  validate constraint workout_sessions_planned_step_nonnegative;

create index if not exists workout_sessions_user_schedule_source_idx
  on public.workout_sessions (user_id, schedule_source, finished_at desc);

create index if not exists workout_sessions_user_planned_date_idx
  on public.workout_sessions (user_id, planned_date);

alter table public.user_training_session_events
  add column if not exists planned_date date,
  add column if not exists workout_session_id uuid
    references public.workout_sessions(id) on delete set null;

create index if not exists user_training_session_events_planned_date_idx
  on public.user_training_session_events (user_id, planned_date);
