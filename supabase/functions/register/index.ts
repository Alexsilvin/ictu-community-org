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

// IMPORTANT: keep roles strict.
// If you allow self-registration, users must not be able to choose privileged roles.
// Add more roles here ONLY if you have a separate, trusted onboarding flow.
const ALLOWED_ROLES = ['student'] as const;
type AllowedRole = (typeof ALLOWED_ROLES)[number];

function assertRole(role: string): asserts role is AllowedRole {
  if (!ALLOWED_ROLES.includes(role as AllowedRole)) {
    throw new Error(`Invalid role. Allowed roles: ${ALLOWED_ROLES.join(', ')}`);
  }
}

function assertFaculty(faculty: string): void {
  if (typeof faculty !== 'string' || faculty.trim().length < 2) {
    throw new Error('Faculty is required');
  }
}

type RegisterBody = {
  email: string;
  password: string;
  username: string;
  role: string;
  faculty: string;
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

    const body = (await req.json()) as RegisterBody;

    const email = normalizeEmail(body.email ?? '');
    const password = body.password ?? '';
    const username = (body.username ?? '').trim();
    const role = (body.role ?? '').trim();
    const faculty = (body.faculty ?? '').trim();

    if (!email || !password || !username || !role || !faculty) {
      return jsonResponse(400, {
        error: 'email, password, username, role and faculty are required',
      });
    }

    assertIctuEmail(email);
    assertStrongPassword(password);
    assertRole(role);
    assertFaculty(faculty);

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // 1) Create auth user
    const { data: created, error: createErr } =
      await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (createErr || !created.user) {
      return jsonResponse(400, {
        error: createErr?.message ?? 'Failed to create user',
      });
    }

    const authUserId = created.user.id;

    // 2) Upsert profile (use auth user id as profile id)
    const { error: profileErr } = await admin.from('profiles').upsert(
      {
        id: authUserId,
        email,
        full_name: username,
        role,
        faculty,
      },
      { onConflict: 'id' },
    );

    if (profileErr) {
      // rollback: delete auth user to avoid orphan account
      await admin.auth.admin.deleteUser(authUserId);
      return jsonResponse(400, {
        error: `Failed to store profile: ${profileErr.message}`,
      });
    }

    // 3) Sign in to return JWT/session
    const { data: sessionData, error: signInErr } =
      await admin.auth.signInWithPassword({ email, password });

    if (signInErr || !sessionData.session || !sessionData.user) {
      return jsonResponse(400, {
        error: signInErr?.message ?? 'Failed to sign in after registration',
      });
    }

    const { data: profileData } = await admin
      .from('profiles')
      .select('id, full_name, email, role, faculty, created_at')
      .eq('id', authUserId)
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

