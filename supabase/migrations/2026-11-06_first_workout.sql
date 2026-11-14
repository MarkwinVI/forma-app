-- The day the user booked their first workout for.
--
-- Right after the trial starts, the activation flow asks when the first
-- workout will be. Until that day the Train tab shows the booking instead
-- of a session, and the schedule treats the days before it as rest rather
-- than missed. Null when the user never booked one ("Not now"), or once
-- the booking has served its purpose — the program's own history takes
-- over from the first logged session.

alter table public.user_training_program_state
  add column first_workout_on date;
