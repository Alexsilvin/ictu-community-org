/// <reference lib="deno.ns" />
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

// NOTE: This function is intentionally self-contained so it can be deployed
// from the Supabase Dashboard editor (which bundles only the function folder).
const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ICTU_DOMAIN = '@ictuniversity.edu.cm';

function normalizeEmail(email: string): string {
  return (email ?? '').trim().toLowerCase();
}

function assertIctuEmail(email: string): void {
  const normalized = normalizeEmail(email);
  if (!normalized.endsWith(ICTU_DOMAIN)) {
    throw new Error(`Email must end with ${ICTU_DOMAIN}`);
  }
}

function assertStrongPassword(password: string): void {
  if (typeof password !== 'string' || password.length < 8) {
    throw new Error('Password must be at least 8 characters');
  }
}

type LoginBody = {
  email: string;
  password: string;
};

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return jsonResponse(500, {
        error:
          'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in function secrets',
      });
    }

    const body = (await req.json()) as LoginBody;

    const email = normalizeEmail(body.email ?? '');
    const password = body.password ?? '';

    if (!email || !password) {
      return jsonResponse(400, { error: 'email and password are required' });
    }

    assertIctuEmail(email);
    // Same password constraints as registration to avoid weird cases
    assertStrongPassword(password);

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: sessionData, error: signInErr } =
      await admin.auth.signInWithPassword({ email, password });

    if (signInErr || !sessionData.session || !sessionData.user) {
      return jsonResponse(401, { error: signInErr?.message ?? 'Unauthorized' });
    }

    const userId = sessionData.user.id;
    const { data: profileData } = await admin
      .from('profiles')
      .select('id, full_name, email, role, faculty, created_at')
      .eq('id', userId)
      .maybeSingle();

    const user = {
      ...sessionData.user,
      profile: profileData ?? null,
    };

    return jsonResponse(200, {
      access_token: sessionData.session.access_token,
      refresh_token: sessionData.session.refresh_token,
      expires_in: sessionData.session.expires_in,
      token_type: sessionData.session.token_type,
      user,
    });
  } catch (e) {
    return jsonResponse(400, { error: (e as Error).message ?? 'Bad request' });
  }
});

