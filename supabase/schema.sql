-- Run this in your Supabase SQL editor (https://supabase.com/dashboard)

create table public.users (
  id          uuid references auth.users (id) on delete cascade primary key,
  email       text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz default now() not null
);

-- Row Level Security: each user can only read/write their own row.
alter table public.users enable row level security;

create policy "Users can view their own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can upsert their own profile"
  on public.users for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id);
