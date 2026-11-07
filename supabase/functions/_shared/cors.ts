// Supabase Edge Functions: Shared CORS Headers & Response Helpers
// File: supabase/functions/_shared/cors.ts

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-application-name',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
};

/**
 * Handles CORS preflight OPTIONS requests.
 * Returns a Response with status 204 if OPTIONS, or null otherwise.
 */
export function handleCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }
  return null;
}

/**
 * Creates a standard JSON response with CORS headers.
 */
export function jsonResponse(
  data: unknown,
  status = 200,
  extraHeaders?: Record<string, string>,
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  });
}

/**
 * Creates a standard error JSON response with CORS headers.
 */
export function errorResponse(
  message: string,
  status = 400,
  code?: string,
  details?: unknown,
): Response {
  return new Response(
    JSON.stringify({
      error: message,
      code: code || `ERR_${status}`,
      details: details || null,
      timestamp: new Date().toISOString(),
    }),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    },
  );
}
