-- Retire the 'skipped' exercise status.
--
-- The node model is now four visible states — locked, unlocked, training,
-- mastered — backed by three stored statuses (inactive | active | mastered):
--
--   * Placement (setup answers, or "tap where you are") marks the steps
--     behind the starting node mastered outright.
--   * A manual jump to a later step leaves the steps in between inactive
--     (locked) until the jumped-to exercise is mastered, which then masters
--     them too.
--
-- Existing 'skipped' rows split along that line: a skip whose shortcut
-- destination was never mastered is an unfinished jump and goes back to
-- inactive; every other skip (setup placement, or a jump whose destination
-- was mastered) counts as mastered. The 'skipped' progression-event rows
-- that identified manual jumps are deleted afterwards — the app no longer
-- reads the kind.

-- Unfinished manual jumps: the skip event's related_exercise_id is the jump
-- destination; if no mastered row exists for it, the debt was never settled.
update public.user_exercise_progress p
set status = 'inactive',
    updated_at = now()
where p.status = 'skipped'
  and exists (
    select 1
    from public.progression_events e
    where e.user_id = p.user_id
      and e.exercise_id = p.exercise_id
      and e.kind = 'skipped'
      and e.related_exercise_id is not null
      and not exists (
        select 1
        from public.user_exercise_progress d
        where d.user_id = p.user_id
          and d.exercise_id = e.related_exercise_id
          and d.status = 'mastered'
      )
  );

-- Everything still skipped was placed or proven: it is mastered now.
update public.user_exercise_progress
set status = 'mastered',
    updated_at = now()
where status = 'skipped';

-- The event kind is dead; the app ignores unknown kinds, but there is no
-- reason to keep rows nothing will ever read.
delete from public.progression_events where kind = 'skipped';

comment on column public.user_exercise_progress.status is
  'inactive | active | mastered. No skipped status: placement masters the steps behind the start, and a manual jump leaves the steps in between inactive until the jumped-to exercise is mastered - which then masters them too.';
