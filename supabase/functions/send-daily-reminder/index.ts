// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface ReminderPayload {
  uid: string;
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const schedulerSecret = Deno.env.get('SCHEDULER_SECRET') ?? '';
    const providedSecret = req.headers.get('x-scheduler-secret') ?? '';

    if (!schedulerSecret || schedulerSecret !== providedSecret) {
      return new Response('Unauthorized scheduler request', { status: 401 });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const pushGatewayUrl = Deno.env.get('PUSH_GATEWAY_URL') ?? '';
    const pushGatewaySecret = Deno.env.get('PUSH_GATEWAY_SECRET') ?? '';

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response('Missing Supabase function environment variables', { status: 500 });
    }

    if (!pushGatewayUrl) {
      return new Response('Missing PUSH_GATEWAY_URL', { status: 500 });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('uid, fcm_token')
      .not('fcm_token', 'is', null);

    if (usersError != null) {
      return new Response(JSON.stringify({ error: usersError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const payloads: ReminderPayload[] = (users ?? [])
      .map((row) => ({
        uid: row.uid as string,
        token: row.fcm_token as string,
        title: 'Daily Study Streak',
        body: 'Keep your learning streak going! Take a mock test today.',
        data: { screen: 'mock-test' },
      }))
      .filter((item) => item.token.length > 0);

    let sent = 0;
    let failed = 0;

    for (const payload of payloads) {
      const response = await fetch(pushGatewayUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(pushGatewaySecret ? { 'x-push-gateway-secret': pushGatewaySecret } : {}),
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        sent += 1;
      } else {
        failed += 1;
      }
    }

    return new Response(
      JSON.stringify({ ok: true, total: payloads.length, sent, failed }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
