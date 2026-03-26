# Supabase Edge Functions

This directory contains Supabase Edge Function scaffolds used during Firebase-to-Supabase migration.

## Functions

1. `create-user-profile`
- Purpose: Ensure a row exists in `public.users` for the currently authenticated user.
- Invocation: Authenticated client request with `Authorization: Bearer <access_token>`.

2. `validate-premium`
- Purpose: Update `users.is_premium` from a trusted webhook payload.
- Invocation: Server-to-server webhook request.

3. `send-daily-reminder`
- Purpose: Fetch users with push tokens and dispatch reminders through a push gateway endpoint.
- Invocation: Scheduled server-to-server request.

4. `aggregate-stats`
- Purpose: Aggregate per-user quiz and mock test totals into `public.user_stats`.
- Invocation: Scheduled server-to-server request.

## Required Function Secrets

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `REVENUECAT_WEBHOOK_SECRET` (for `validate-premium`)
- `SCHEDULER_SECRET` (for scheduled functions)
- `PUSH_GATEWAY_URL` (for `send-daily-reminder`)
- `PUSH_GATEWAY_SECRET` (optional, for `send-daily-reminder`)

## Deploy

```bash
supabase functions deploy create-user-profile
supabase functions deploy validate-premium
supabase functions deploy send-daily-reminder
supabase functions deploy aggregate-stats
```

## Notes

- These are migration scaffolds and should be hardened before production.
- Add robust webhook signature verification and request schema validation.
- Configure scheduler jobs to invoke `send-daily-reminder` and `aggregate-stats` with `x-scheduler-secret` header.
