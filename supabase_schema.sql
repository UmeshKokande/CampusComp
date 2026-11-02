-- Run all of this in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,full_name text not null,student_id text unique,role text not null default 'student' check(role in ('student','faculty','admin')),created_at timestamptz not null default now());
create table if not exists public.competitions(id uuid primary key default gen_random_uuid(),title text not null,description text not null,category text not null,venue text not null,event_date timestamptz not null,registration_deadline timestamptz not null,eligibility text,rules text,capacity integer check(capacity is null or capacity>0),status text not null default 'draft' check(status in ('draft','published','completed')),created_by uuid not null references public.profiles(id),created_at timestamptz not null default now(),check(registration_deadline<=event_date));
create table if not exists public.registrations(id uuid primary key default gen_random_uuid(),competition_id uuid not null references public.competitions(id) on delete cascade,student_id uuid not null references public.profiles(id) on delete cascade,status text not null default 'pending' check(status in ('pending','approved','rejected','completed')),result text,certificate_url text,created_at timestamptz not null default now(),unique(competition_id,student_id));
create index if not exists registrations_student_idx on public.registrations(student_id);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,full_name,student_id,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Student'),nullif(new.raw_user_meta_data->>'student_id',''),'student'); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
-- SECURITY DEFINER helper avoids recursive RLS lookups against profiles.
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in ('faculty','admin')); $$;
alter table public.profiles enable row level security;
alter table public.competitions enable row level security;
alter table public.registrations enable row level security;
drop policy if exists "profile read self or staff" on public.profiles;
create policy "profile read self or staff" on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
-- No client-side profile UPDATE policy: role cannot be self-assigned.
drop policy if exists "published competitions visible" on public.competitions;
create policy "published competitions visible" on public.competitions for select to authenticated using(status='published' or public.is_staff());
drop policy if exists "staff create competitions" on public.competitions;
create policy "staff create competitions" on public.competitions for insert to authenticated with check(created_by=auth.uid() and public.is_staff());
drop policy if exists "staff update competitions" on public.competitions;
create policy "staff update competitions" on public.competitions for update to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists "staff delete competitions" on public.competitions;
create policy "staff delete competitions" on public.competitions for delete to authenticated using(public.is_staff());
drop policy if exists "registration read own or staff" on public.registrations;
create policy "registration read own or staff" on public.registrations for select to authenticated using(student_id=auth.uid() or public.is_staff());
drop policy if exists "student register self" on public.registrations;
create policy "student register self" on public.registrations for insert to authenticated with check(student_id=auth.uid() and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='student') and exists(select 1 from public.competitions c where c.id=competition_id and c.status='published' and c.registration_deadline>=now()));
drop policy if exists "staff update registrations" on public.registrations;
create policy "staff update registrations" on public.registrations for update to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists "student cancel own registration" on public.registrations;
create policy "student cancel own registration" on public.registrations for delete to authenticated using(student_id=auth.uid() and exists(select 1 from public.competitions c where c.id=competition_id and c.event_date>now()));
-- Promote a trusted faculty account only after that person has signed up:
-- update public.profiles p set role='faculty' from auth.users u where p.id=u.id and u.email='faculty@example.com';
