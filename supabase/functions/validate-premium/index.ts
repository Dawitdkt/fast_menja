// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface PremiumPayload {
  uid: string;
  isPremium: boolean;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? '';
    const providedSecret = req.headers.get('x-revenuecat-signature') ?? '';

    if (!webhookSecret || webhookSecret != providedSecret) {
      return new Response('Unauthorized webhook request', { status: 401 });
    }

    const payload = (await req.json()) as PremiumPayload;
    if (!payload.uid) {
      return new Response('Missing uid', { status: 400 });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { error } = await supabase
      .from('users')
      .update({ is_premium: payload.isPremium })
      .eq('uid', payload.uid);

    if (error != null) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
