// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response('Missing Supabase function environment variables', { status: 500 });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: users, error: usersError } = await supabase.from('users').select('uid');
    if (usersError != null) {
      return new Response(JSON.stringify({ error: usersError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let processed = 0;

    for (const row of users ?? []) {
      const uid = row.uid as string;

      const { data: quizRows } = await supabase
        .from('quiz_stats')
        .select('total_attempts, total_correct')
        .eq('uid', uid);

      const { data: mockRows } = await supabase
        .from('mock_tests')
        .select('test_id, passed')
        .eq('uid', uid);

      const totalAttempts = (quizRows ?? []).reduce(
        (sum, item) => sum + (Number(item.total_attempts) || 0),
        0,
      );
      const totalCorrect = (quizRows ?? []).reduce(
        (sum, item) => sum + (Number(item.total_correct) || 0),
        0,
      );
      const mockAttempts = (mockRows ?? []).length;
      const mockPasses = (mockRows ?? []).filter((item) => item.passed === true).length;

      const { error: upsertError } = await supabase.from('user_stats').upsert(
        {
          uid,
          total_quiz_attempts: totalAttempts,
          total_quiz_correct: totalCorrect,
          total_mock_attempts: mockAttempts,
          total_mock_passes: mockPasses,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'uid' },
      );

      if (upsertError == null) {
        processed += 1;
      }
    }

    return new Response(JSON.stringify({ ok: true, processed }), {
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
