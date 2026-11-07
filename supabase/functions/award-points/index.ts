// Edge Function: award-points
// File: supabase/functions/award-points/index.ts

import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { requireAuth, isServiceRoleRequest, getAdminClient } from '../_shared/auth.ts';

interface AwardPointsRequest {
  user_id: string;
  points: number;
  reason: string;
  reference_id?: string;
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed. Use POST.', 405);
  }

  try {
    const adminClient = getAdminClient();
    const isService = isServiceRoleRequest(req);

    let callerUserId: string | null = null;
    if (!isService) {
      try {
        const userContext = await requireAuth(req, false);
        callerUserId = userContext.user.id;
      } catch (authErr) {
        return errorResponse((authErr as Error).message, 401, 'UNAUTHORIZED');
      }
    }

    const body: AwardPointsRequest = await req.json().catch(() => ({}));
    const targetUserId = (body.user_id || callerUserId || '').trim();
    const points = Number(body.points);
    const reason = (body.reason || '').trim();
    const referenceId = (body.reference_id || '').trim();

    if (!targetUserId) {
      return errorResponse('Missing required parameter: user_id', 400, 'MISSING_PARAM');
    }

    if (!points || isNaN(points) || points <= 0) {
      return errorResponse('Parameter points must be a positive integer.', 400, 'INVALID_POINTS');
    }

    if (!reason) {
      return errorResponse('Missing required parameter: reason', 400, 'MISSING_PARAM');
    }

    // Security check: If called by regular authenticated user (not service_role),
    // enforce that users can only award points for verified activities (e.g. valid discoveries).
    if (!isService) {
      if (callerUserId !== targetUserId) {
        return errorResponse('Forbidden: cannot award points to another user.', 403, 'FORBIDDEN');
      }

      // Restrict point awarding from client side: only verified discovery reference allowed, max 15 points
      const isDiscoveryReason = reason.toLowerCase().includes('discovery');
      const isReferenced = referenceId.startsWith('discovery_');

      if (!isDiscoveryReason || !isReferenced || points > 25) {
        return errorResponse(
          'Unauthorized point transaction. Arbitrary points cannot be self-awarded.',
          403,
          'TAMPERING_DETECTED',
        );
      }

      // Verify that the discovery actually exists and belongs to this user
      const rawDiscoveryId = referenceId.replace('discovery_', '');
      const { data: disc, error: discErr } = await adminClient
        .from('discoveries')
        .select('id')
        .eq('id', rawDiscoveryId)
        .eq('user_id', targetUserId)
        .maybeSingle();

      if (discErr || !disc) {
        return errorResponse('Invalid discovery reference for point award.', 400, 'INVALID_REFERENCE');
      }
    }

    // Execute transactional RPC
    const { data: awardResult, error: awardErr } = await adminClient.rpc('award_points_to_user', {
      p_user_id: targetUserId,
      p_points: points,
      p_reason: reason,
      p_reference_id: referenceId || null,
    });

    if (awardErr) {
      console.error('Error invoking award_points_to_user:', awardErr);
      return errorResponse(`Failed to award points: ${awardErr.message}`, 500, 'AWARD_FAILED');
    }

    // Retrieve updated profile
    const { data: profile, error: profErr } = await adminClient
      .from('profiles')
      .select('id, username, avatar_url, total_points, explorer_level, created_at, updated_at')
      .eq('id', targetUserId)
      .single();

    return jsonResponse({
      success: true,
      data: {
        award_result: awardResult,
        profile: profile || null,
        new_achievements: awardResult?.new_achievements || [],
      },
    });
  } catch (err) {
    console.error('Unhandled award-points error:', err);
    return errorResponse((err as Error).message || 'Internal server error', 500, 'INTERNAL_ERROR');
  }
});
