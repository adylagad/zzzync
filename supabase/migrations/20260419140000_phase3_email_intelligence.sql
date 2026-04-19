create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.contact_tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  priority text not null check (priority in ('high', 'low')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, email)
);

create table if not exists public.email_stress_signals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('gmail', 'outlook')),
  sender_email text not null,
  sender_priority text not null check (sender_priority in ('high', 'low')),
  unread_threads integer not null default 0,
  thread_length_score integer not null default 0,
  subject_keywords jsonb not null default '[]'::jsonb,
  stress_score integer not null default 0,
  generated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider, sender_email)
);

create index if not exists contact_tags_user_idx
  on public.contact_tags(user_id);

create index if not exists email_stress_signals_user_generated_idx
  on public.email_stress_signals(user_id, generated_at desc);

drop trigger if exists set_contact_tags_updated_at on public.contact_tags;
create trigger set_contact_tags_updated_at
before update on public.contact_tags
for each row execute function public.set_updated_at();

drop trigger if exists set_email_stress_signals_updated_at on public.email_stress_signals;
create trigger set_email_stress_signals_updated_at
before update on public.email_stress_signals
for each row execute function public.set_updated_at();

alter table public.contact_tags enable row level security;
alter table public.email_stress_signals enable row level security;

drop policy if exists "contact_tags_select_own" on public.contact_tags;
create policy "contact_tags_select_own"
on public.contact_tags
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "contact_tags_insert_own" on public.contact_tags;
create policy "contact_tags_insert_own"
on public.contact_tags
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "contact_tags_update_own" on public.contact_tags;
create policy "contact_tags_update_own"
on public.contact_tags
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "contact_tags_delete_own" on public.contact_tags;
create policy "contact_tags_delete_own"
on public.contact_tags
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "email_stress_signals_select_own" on public.email_stress_signals;
create policy "email_stress_signals_select_own"
on public.email_stress_signals
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "email_stress_signals_insert_own" on public.email_stress_signals;
create policy "email_stress_signals_insert_own"
on public.email_stress_signals
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "email_stress_signals_update_own" on public.email_stress_signals;
create policy "email_stress_signals_update_own"
on public.email_stress_signals
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "email_stress_signals_delete_own" on public.email_stress_signals;
create policy "email_stress_signals_delete_own"
on public.email_stress_signals
for delete
to authenticated
using (auth.uid() = user_id);
