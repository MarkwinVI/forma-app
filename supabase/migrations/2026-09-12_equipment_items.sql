-- The equipment question's middle answer is no longer a "barbell and
-- dumbbells" preset: it is "Some equipment" with the specific items ticked,
-- stored in program_setup_v1 as
--   equipment       'gym' | 'some' | 'none'
--   equipment_items ['pull_up_bar' | 'rings' | 'parallettes' | 'dip_bars' |
--                    'bands' | 'kettlebell' | 'dumbbells' | 'barbell', ...]
--   has_gym         boolean — derived: a full gym, or a barbell among the items
--
-- Programs that answered "barbell" become "Some equipment" with exactly the
-- two items that preset stood for. has_gym stays true, so nothing about how
-- these programs are planned changes. The app reads a stray 'barbell' the
-- same way, so a row this script misses still displays and saves correctly.

update public.user_training_programs
set variation_rules = jsonb_set(
  jsonb_set(
    variation_rules,
    '{program_setup_v1,equipment}',
    '"some"'::jsonb
  ),
  '{program_setup_v1,equipment_items}',
  '["dumbbells", "barbell"]'::jsonb
)
where variation_rules #>> '{program_setup_v1,equipment}' = 'barbell';

-- The two presets carry an empty list, so every program answers the same
-- shape whichever way it was created.
update public.user_training_programs
set variation_rules = jsonb_set(
  variation_rules,
  '{program_setup_v1,equipment_items}',
  '[]'::jsonb
)
where variation_rules #>> '{program_setup_v1,equipment}' in ('gym', 'none')
  and variation_rules #> '{program_setup_v1,equipment_items}' is null;
