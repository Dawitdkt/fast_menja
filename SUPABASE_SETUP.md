# Supabase Setup Guide

This is the primary backend setup guide while Firebase-to-Supabase migration is in progress.

## 1. Create Supabase Project

1. Go to https://supabase.com and create a new project.
2. Save your project URL and anon key from Project Settings > API.

## 2. Configure Environment Variables

Update `.env`:

```env
SUPABASE_URL=your-supabase-project-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

## 3. Apply Database Schema

Run the SQL migration from:

- `supabase/migrations/20260324_initial_schema.sql`

Apply using either Supabase SQL editor or CLI.

## 4. Configure Row Level Security

The migration includes RLS policies for:

1. `users`
2. `lesson_progress`
3. `quiz_stats`
4. `mock_tests`
5. `weak_questions`

Ensure RLS is enabled and policies are present after migration.

## 5. Deploy Edge Functions

Functions added in this repo:

1. `create-user-profile`
2. `validate-premium`
3. `send-daily-reminder`
4. `aggregate-stats`

Deploy with:

```bash
supabase functions deploy create-user-profile
supabase functions deploy validate-premium
supabase functions deploy send-daily-reminder
supabase functions deploy aggregate-stats
```

## 6. Function Secrets

Set required function secrets:

1. `SUPABASE_URL`
2. `SUPABASE_SERVICE_ROLE_KEY`
3. `REVENUECAT_WEBHOOK_SECRET`
4. `SCHEDULER_SECRET`
5. `PUSH_GATEWAY_URL`
6. `PUSH_GATEWAY_SECRET` (optional)

## 7. Configure Scheduled Invocations

Set up your scheduler to call these endpoints with a `POST` request and `x-scheduler-secret` header:

1. `send-daily-reminder` at 09:00 Europe/London daily.
2. `aggregate-stats` daily or hourly based on reporting needs.

## 8. Configure Push Gateway

`send-daily-reminder` sends push payloads to `PUSH_GATEWAY_URL`.

1. Implement a secure gateway that accepts payloads and dispatches to APNs/FCM.
2. Validate `x-push-gateway-secret` if provided.

## 9. App Runtime Verification

1. Start app and confirm no missing env error from `main.dart`.
2. Sign in with email and confirm profile row exists in `public.users`.
3. Complete lesson/quiz actions and confirm writes to related tables.

## Notes

- `lib/core/services/firestore_service.dart` currently contains Supabase logic for compatibility with existing imports and will be renamed in a later cleanup step.
- Legacy Firebase docs still exist for reference during transition but are no longer the primary setup path.
