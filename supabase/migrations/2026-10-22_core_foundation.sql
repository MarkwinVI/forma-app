-- The core tree gets a foundation, and the leg raises lose their first step.
--
-- Since 2026-10-22 the core tree opens with a dead bug foundation — Dead Bug
-- Hold, Dead Bug Heel Tap, Dead Bug — that all three branches (L-sit, ab
-- wheel, leg raises) hang off, and the leg raises start at the lying
-- bent-leg raise: the lying knee raise that used to open them is retired.
--
-- Two things follow for rows written under the old shape:
--
--   1. The retired step is renamed to the step that replaced it. Ids are
--      immutable and a removed step is a data migration (see the 2026-08-18
--      migration), so every row under core_lying_knee_raises becomes a row
--      under core_bent_leg_lying_leg_raises. A user who already holds a
--      bent-leg row (knee raise mastered, bent-leg raise active) keeps that
--      row; the knee-raise row is dropped rather than merged.
--
--   2. Everyone already on the core tree gets the foundation mastered. The
--      foundation sits strictly behind every branch step, so a user with an
--      active or mastered step anywhere on the tree has, by the app's own
--      placement rule, cleared it. Without these rows the app would show
--      three locked steps behind their active one until their next session
--      at starting volume mastered them. Users who never started the core
--      tree get nothing: they begin at Dead Bug Hold like everyone new.
--
-- Safe to run before the build that knows the new steps ships: the older
-- app ignores step ids it does not know.

-- ── 1. core_lying_knee_raises → core_bent_leg_lying_leg_raises ──────────

-- Progress rows: the bent-leg row wins where both exist.
delete from public.user_exercise_progress old
where old.exercise_id = 'core_lying_knee_raises'
  and exists (
    select 1
    from public.user_exercise_progress kept
    where kept.user_id = old.user_id
      and kept.exercise_id = 'core_bent_leg_lying_leg_raises'
  );

update public.user_exercise_progress
set exercise_id = 'core_bent_leg_lying_leg_raises',
    updated_at = now()
where exercise_id = 'core_lying_knee_raises';

-- The ledger, the workout log and the approval queue carry no uniqueness
-- on the id, so they simply rename.
update public.progression_events
set exercise_id = 'core_bent_leg_lying_leg_raises'
where exercise_id = 'core_lying_knee_raises';

update public.progression_events
set related_exercise_id = 'core_bent_leg_lying_leg_raises'
where related_exercise_id = 'core_lying_knee_raises';

update public.workout_exercise_logs
set exercise_id = 'core_bent_leg_lying_leg_raises'
where exercise_id = 'core_lying_knee_raises';

update public.user_progression_suggestions
set exercise_id = 'core_bent_leg_lying_leg_raises'
where exercise_id = 'core_lying_knee_raises';

-- ── 2. The foundation is mastered for everyone already on the tree ──────

insert into public.user_exercise_progress (user_id, exercise_id, status, updated_at)
select on_tree.user_id, foundation.exercise_id, 'mastered', now()
from (
  select distinct user_id
  from public.user_exercise_progress
  where status in ('active', 'mastered')
    and exercise_id in (
      'core_foot_supported_l_sit',
      'core_l_sit_tuck',
      'core_advanced_tuck_l_sit',
      'core_l_sit',
      'core_straddle_l_sit',
      'core_v_sit',
      'core_plank',
      'core_plank_60s',
      'core_one_arm_one_leg_plank',
      'core_ab_wheel_kneeling',
      'core_ab_wheel_eccentric',
      'core_ab_wheel_standing',
      'core_bent_leg_lying_leg_raises',
      'core_straight_leg_lying_leg_raises',
      'core_hanging_knee_raises',
      'core_bent_leg_hanging_leg_raises',
      'core_straight_leg_hanging_leg_raises'
    )
) on_tree
cross join (
  values ('core_dead_bug_hold'), ('core_dead_bug_heel_tap'), ('core_dead_bug')
) as foundation(exercise_id)
on conflict (user_id, exercise_id) do update
  set status = 'mastered',
      updated_at = now()
  where public.user_exercise_progress.status <> 'mastered';
