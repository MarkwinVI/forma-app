-- Why they came.
--
-- Onboarding now opens with one question — "What drew you to Forma?" — and
-- the answer lands on the profile row with the rest. The option id goes to
-- analytics as a trait; the words behind "Other" live only here, the same
-- rule as feedback notes.

alter table public.user_onboarding_profiles
  add column motivation text,       -- 'specific_skill' | 'skill_levels' | 'clear_program' | 'other'
  add column motivation_other text; -- the words behind 'other'; never sent to analytics
