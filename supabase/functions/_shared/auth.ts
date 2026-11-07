// Supabase Edge Functions: Shared Auth Helper & Supabase Client Setup
// File: supabase/functions/_shared/auth.ts

import { createClient, SupabaseClient, User } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

export interface AuthenticatedContext {
  user: User;
  token: string;
  supabaseClient: SupabaseClient;
  adminClient: SupabaseClient;
}

/**
 * Creates an admin/service-role Supabase client.
 */
export function getAdminClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be configured.');
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

/**
 * Creates an authenticated user Supabase client using their Bearer JWT.
 */
export function getUserClient(jwt: string): SupabaseClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');

  if (!supabaseUrl || !anonKey) {
    throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY must be configured.');
  }

  return createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${jwt}`,
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

/**
 * Validates incoming Authorization header and retrieves authenticated user.
 * Supports guest/demo flow if DEMO_MODE is true and auth is not strictly required.
 */
export async function requireAuth(
  req: Request,
  allowGuestFallback = false,
): Promise<AuthenticatedContext> {
  const authHeader = req.headers.get('Authorization');
  const adminClient = getAdminClient();

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    if (allowGuestFallback && Deno.env.get('DEMO_MODE') === 'true') {
      // Mock user for demo mode
      const demoUser: User = {
        id: '00000000-0000-0000-0000-000000000000',
        app_metadata: { provider: 'demo' },
        user_metadata: { username: 'Demo Explorer' },
        aud: 'authenticated',
        created_at: new Date().toISOString(),
      };
      return {
        user: demoUser,
        token: 'demo-token',
        supabaseClient: adminClient,
        adminClient,
      };
    }
    throw new Error('Missing or malformed Authorization header with Bearer token.');
  }

  const token = authHeader.replace('Bearer ', '').trim();
  const supabaseClient = getUserClient(token);

  const { data: { user }, error } = await supabaseClient.auth.getUser(token);

  if (error || !user) {
    throw new Error(`Unauthorized: ${error?.message || 'Invalid or expired token'}`);
  }

  return {
    user,
    token,
    supabaseClient,
    adminClient,
  };
}

/**
 * Validates whether the request comes from a service role or administrative caller.
 */
export function isServiceRoleRequest(req: Request): boolean {
  const authHeader = req.headers.get('Authorization');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!authHeader || !serviceRoleKey) return false;
  const token = authHeader.replace('Bearer ', '').trim();
  return token === serviceRoleKey;
}
