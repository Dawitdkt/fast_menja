-- Fast Menja initial Supabase schema
-- Run this migration in Supabase SQL editor or via supabase migration tooling.

create table if not exists public.users (
  uid text primary key,
  email text,
  display_name text,
  created_at timestamptz not null default now(),
  is_premium boolean not null default false,
  fcm_token text
);

create table if not exists public.lesson_progress (
  uid text not null references public.users(uid) on delete cascade,
  slug text not null,
  completed boolean not null default false,
  bookmarked boolean not null default false,
  completed_at timestamptz,
  primary key (uid, slug)
);

create table if not exists public.quiz_stats (
  uid text not null references public.users(uid) on delete cascade,
  category text not null,
  total_attempts integer not null default 0,
  total_correct integer not null default 0,
  last_attempt_at timestamptz,
  primary key (uid, category)
);

create table if not exists public.mock_tests (
  uid text not null references public.users(uid) on delete cascade,
  test_id text not null,
  score integer not null,
  total_questions integer not null,
  passed_at timestamptz not null,
  duration_seconds integer not null,
  passed boolean not null,
  primary key (uid, test_id)
);

create table if not exists public.weak_questions (
  uid text not null references public.users(uid) on delete cascade,
  question_id text not null,
  incorrect_count integer not null default 0,
  last_seen_at timestamptz not null default now(),
  next_due_at timestamptz not null default now(),
  primary key (uid, question_id)
);

create table if not exists public.user_stats (
  uid text primary key references public.users(uid) on delete cascade,
  total_quiz_attempts integer not null default 0,
  total_quiz_correct integer not null default 0,
  total_mock_attempts integer not null default 0,
  total_mock_passes integer not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists idx_lesson_progress_uid on public.lesson_progress(uid);
create index if not exists idx_quiz_stats_uid on public.quiz_stats(uid);
create index if not exists idx_mock_tests_uid on public.mock_tests(uid);
create index if not exists idx_weak_questions_uid_next_due on public.weak_questions(uid, next_due_at);
create index if not exists idx_user_stats_uid on public.user_stats(uid);

alter table public.users enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.quiz_stats enable row level security;
alter table public.mock_tests enable row level security;
alter table public.weak_questions enable row level security;
alter table public.user_stats enable row level security;

create policy if not exists users_self_select
  on public.users for select
  using (auth.uid()::text = uid);

create policy if not exists users_self_insert
  on public.users for insert
  with check (auth.uid()::text = uid);

create policy if not exists users_self_update
  on public.users for update
  using (auth.uid()::text = uid)
  with check (auth.uid()::text = uid);

create policy if not exists lesson_progress_self_all
  on public.lesson_progress for all
  using (auth.uid()::text = uid)
  with check (auth.uid()::text = uid);

create policy if not exists quiz_stats_self_all
  on public.quiz_stats for all
  using (auth.uid()::text = uid)
  with check (auth.uid()::text = uid);

create policy if not exists mock_tests_self_all
  on public.mock_tests for all
  using (auth.uid()::text = uid)
  with check (auth.uid()::text = uid);

create policy if not exists weak_questions_self_all
  on public.weak_questions for all
  using (auth.uid()::text = uid)
  with check (auth.uid()::text = uid);

create policy if not exists user_stats_self_select
  on public.user_stats for select
  using (auth.uid()::text = uid);
