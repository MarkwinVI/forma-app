-- Why they came, as many reasons as apply.
--
-- "What drew you to Forma?" is now a multiple choice with a longer list, so
-- the answer is an array. The single-answer column stays: builds that ask
-- the one-pick question still write it. Its answers are carried over where
-- the id still exists ('skill_levels' has no successor).

alter table public.user_onboarding_profiles
  add column motivations text[]; -- any of 'start_calisthenics' | 'track_progress' | 'unstuck' | 'specific_skill' | 'clear_program' | 'stay_consistent' | 'exploring' | 'other'

update public.user_onboarding_profiles
  set motivations = array[motivation]
  where motivation is not null;
