-- Feedback.
--
-- One row per thing a user told us about the app. The first surface is the
-- session rating that closes the post-workout sequence: a thumb up or
-- down, optional reason tags, the exercises a thumbs-down singled out, and
-- an optional note. The table is shaped so the later surfaces (an app
-- rating in stars, a support message) land here too rather than each
-- growing a table of their own — hence the nullable `rating`.
--
-- Every row silently carries the app version, platform and OS version it
-- was sent from, so a complaint can be read against the build that earned
-- it. The free-text note lives only here: analytics gets the tags, never
-- the words.

create table public.feedback (
  id                    uuid default gen_random_uuid() primary key,
  user_id               uuid references auth.users(id) on delete cascade not null,
  kind                  text not null, -- 'session_rating' (later: 'app_rating' | 'support')
  workout_session_id    uuid references public.workout_sessions(id) on delete set null,
  sentiment             text check (sentiment in ('up', 'down')),
  rating                smallint check (rating between 1 and 5),
  tags                  text[] default '{}' not null,   -- reason ids, e.g. 'too_hard'
  flagged_exercise_ids  text[] default '{}' not null,   -- exercises a 'wrong_exercises' tag named
  note                  text,
  app_version           text,
  platform              text,
  os_version            text,
  created_at            timestamptz default now() not null,
  updated_at            timestamptz default now() not null
);

create index feedback_user_created_idx
  on public.feedback (user_id, created_at desc);

create index feedback_session_idx
  on public.feedback (workout_session_id);

alter table public.feedback enable row level security;

create policy "Users manage own feedback"
  on public.feedback for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
