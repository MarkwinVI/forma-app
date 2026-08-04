-- Migration: onboarding profiles + account deletion.
-- Run this once in the Supabase SQL editor of the existing project
-- (schema.sql is the full canonical schema for fresh projects and
-- already includes these statements).

-- ── Onboarding Profiles ───────────────────────────────────────────────────
-- One row per user with the answers from the post-signup onboarding flow.
-- Deleted with the account, so a re-registered user goes through setup again.

create table public.user_onboarding_profiles (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade not null unique,
  archetype           text not null, -- 'generalist' | 'technician' | 'specialist' | 'powerhouse' | 'heavyweight' | 'builder' | 'natural' | 'mover' | 'artist'
  radar_balanced      boolean not null default true,
  radar_angle_deg     double precision, -- radar dot direction; null when balanced
  age                 int not null,
  gender              text, -- 'f' | 'm' | 'na'
  training_frequency  text, -- '0' | '1-2' | '3-4' | '5+' sessions per week
  completed_at        timestamptz default now() not null,
  check (age between 16 and 100)
);

alter table public.user_onboarding_profiles enable row level security;

create policy "Users manage own onboarding profile"
  on public.user_onboarding_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Account Deletion ──────────────────────────────────────────────────────
-- Called from the app's Settings page. Deleting the auth.users row cascades
-- through every public table, wiping all of the user's data.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'delete_account requires an authenticated user';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
