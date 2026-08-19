-- Skill tracks: skills as independent progression tracks.
--
-- One row per skill tree the user is running (or has paused). The skill
-- category — not the 8 movement-pattern lanes — is the unit of progression,
-- so several tracks can cover the same movement (e.g. Pushups AND Planche,
-- both horizontal push). Movement patterns remain a classification used for
-- scheduling and weekly balance, not a storage key.
--
-- included = false pauses the track: it leaves future workouts but keeps
-- its active branch here (and its exercise statuses/targets in
-- user_exercise_progress), so resuming continues exactly where it left off.

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
