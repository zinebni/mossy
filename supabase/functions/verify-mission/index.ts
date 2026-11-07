// Edge Function: verify-mission
// File: supabase/functions/verify-mission/index.ts

import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { VerificationCriteria } from '../_shared/types.ts';

interface VerifyMissionRequest {
  mission_id: string;
  user_id?: string;
  discovery_id?: string;
  evidence_notes?: string;
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed. Use POST.', 405);
  }

  try {
    // 1. Authenticate user
    let userContext;
    try {
      userContext = await requireAuth(req, true);
    } catch (authErr) {
      return errorResponse((authErr as Error).message, 401, 'UNAUTHORIZED');
    }

    const { user, adminClient } = userContext;

    // 2. Parse payload
    const body: VerifyMissionRequest = await req.json().catch(() => ({}));
    const missionId = (body.mission_id || '').trim();
    const targetUserId = (body.user_id || user.id).trim();
    const discoveryId = (body.discovery_id || '').trim();

    // Verify authorized user
    if (user.id !== '00000000-0000-0000-0000-000000000000' && user.id !== targetUserId) {
      return errorResponse('You cannot submit verification for another user.', 403, 'FORBIDDEN');
    }

    if (!missionId) {
      return errorResponse('Missing required parameter: mission_id', 400, 'MISSING_PARAM');
    }

    // 3. Fetch Mission details
    const { data: mission, error: missionErr } = await adminClient
      .from('missions')
      .select('*')
      .eq('id', missionId)
      .maybeSingle();

    if (missionErr || !mission) {
      return errorResponse('Mission not found.', 404, 'MISSION_NOT_FOUND');
    }

    // 4. Check for existing completion (Prevent duplicate rewards)
    const { data: existingUserMission } = await adminClient
      .from('user_missions')
      .select('*')
      .eq('user_id', targetUserId)
      .eq('mission_id', missionId)
      .maybeSingle();

    if (existingUserMission && existingUserMission.status === 'completed') {
      return jsonResponse({
        verified: true,
        already_completed: true,
        message: 'Mission was already completed.',
        points_awarded: 0,
        user_mission: existingUserMission,
      });
    }

    // 5. Retrieve Discovery Evidence if provided
    let discovery: Record<string, unknown> | null = null;
    if (discoveryId) {
      const { data: discData, error: discErr } = await adminClient
        .from('discoveries')
        .select('*')
        .eq('id', discoveryId)
        .eq('user_id', targetUserId)
        .maybeSingle();

      if (!discErr && discData) {
        discovery = discData;
      }
    }

    // 6. Verify criteria against evidence
    const criteria = (mission.verification_criteria || {}) as VerificationCriteria;
    let isCriteriaMet = false;
    let verificationReason = '';

    const textToSearch = [
      (discovery?.scientific_name as string) || '',
      (discovery?.common_name as string) || '',
      (discovery?.family as string) || '',
      (discovery?.personal_notes as string) || '',
      body.evidence_notes || '',
      JSON.stringify(discovery?.ai_content || {}),
    ]
      .join(' ')
      .toLowerCase();

    switch (criteria.type) {
      case 'color_match': {
        const targetColors = criteria.colors || ['yellow'];
        const matched = targetColors.some((c) => textToSearch.includes(c.toLowerCase()));
        if (matched) {
          isCriteriaMet = true;
          verificationReason = `Matched color keywords: ${targetColors.join(', ')}`;
        } else {
          verificationReason = `Discovery evidence does not mention the required colors (${targetColors.join(', ')}).`;
        }
        break;
      }

      case 'family_match': {
        const targetFamily = (criteria.family || '').toLowerCase();
        const synonyms = (criteria.synonyms || []).map((s) => s.toLowerCase());
        const discoveryFamily = ((discovery?.family as string) || '').toLowerCase();

        if (
          discoveryFamily.includes(targetFamily) ||
          synonyms.some((s) => discoveryFamily.includes(s)) ||
          textToSearch.includes(targetFamily)
        ) {
          isCriteriaMet = true;
          verificationReason = `Matched plant family: ${criteria.family}`;
        } else {
          verificationReason = `Discovery is from family "${discovery?.family || 'unknown'}", required: "${criteria.family}".`;
        }
        break;
      }

      case 'family_diversity': {
        const requiredCount = criteria.required_unique_families || 3;
        const { data: distinctFamilies } = await adminClient
          .from('discoveries')
          .select('family')
          .eq('user_id', targetUserId)
          .not('family', 'is', null);

        const uniqueFamilies = new Set(
          (distinctFamilies || [])
            .map((d: { family: string | null }) => (d.family || '').trim().toLowerCase())
            .filter((f: string) => f.length > 0),
        );

        if (uniqueFamilies.size >= requiredCount) {
          isCriteriaMet = true;
          verificationReason = `Identified ${uniqueFamilies.size} distinct plant families (required ${requiredCount}).`;
        } else {
          verificationReason = `You currently have ${uniqueFamilies.size}/${requiredCount} distinct families recorded.`;
        }
        break;
      }

      case 'morphology': {
        const keywords = criteria.keywords || ['petal', 'leaf', 'shape', '5'];
        const matched = keywords.some((kw) => textToSearch.includes(kw.toLowerCase()));
        if (matched || (discovery && Number(criteria.required_count) === 5 && textToSearch.includes('5'))) {
          isCriteriaMet = true;
          verificationReason = `Morphological criteria verified: ${criteria.description || 'Observed characteristics matched'}`;
        } else {
          verificationReason = `Could not verify requested morphology in discovery notes or AI content.`;
        }
        break;
      }

      case 'plant_type': {
        const growthForms = criteria.growth_forms || ['tree', 'arbor'];
        const matched = growthForms.some((gf) => textToSearch.includes(gf.toLowerCase()));
        if (matched) {
          isCriteriaMet = true;
          verificationReason = `Verified plant type matching: ${growthForms.join(', ')}`;
        } else {
          verificationReason = `Evidence does not indicate plant type matching ${growthForms.join(', ')}.`;
        }
        break;
      }

      case 'herb_medicinal': {
        const keywords = criteria.keywords || ['herb', 'medicinal', 'culinary', 'aromatic', 'mint'];
        const matched = keywords.some((kw) => textToSearch.includes(kw.toLowerCase()));
        if (matched) {
          isCriteriaMet = true;
          verificationReason = `Verified culinary/medicinal herb characteristic.`;
        } else {
          verificationReason = `Discovery details do not match medicinal or herb criteria.`;
        }
        break;
      }

      default: {
        // General: valid discovery submitted by user
        if (discovery) {
          isCriteriaMet = true;
          verificationReason = `Verified valid discovery: ${discovery.common_name || discovery.scientific_name}`;
        } else {
          verificationReason = 'Valid discovery evidence is required.';
        }
        break;
      }
    }

    if (!isCriteriaMet) {
      return jsonResponse({
        verified: false,
        reason: verificationReason,
        criteria,
      });
    }

    // 7. Transactional Points Awarding via RPC
    const rewardRefId = `mission_${missionId}_${targetUserId}`;
    const { data: awardResult, error: awardErr } = await adminClient.rpc('award_points_to_user', {
      p_user_id: targetUserId,
      p_points: mission.reward_points,
      p_reason: `Completed mission: ${mission.title}`,
      p_reference_id: rewardRefId,
    });

    if (awardErr) {
      console.error('Error awarding points in verify-mission:', awardErr);
      return errorResponse(`Failed to award points: ${awardErr.message}`, 500, 'AWARD_FAILED');
    }

    // 8. Update user_missions record
    const verificationPayload = {
      verified_at: new Date().toISOString(),
      discovery_id: discoveryId || null,
      verification_reason: verificationReason,
      criteria_type: criteria.type,
    };

    const { data: updatedUserMission, error: userMissionErr } = await adminClient
      .from('user_missions')
      .upsert(
        {
          user_id: targetUserId,
          mission_id: missionId,
          status: 'completed',
          verification_result: verificationPayload,
          completed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,mission_id' },
      )
      .select()
      .single();

    return jsonResponse({
      verified: true,
      points_awarded: mission.reward_points,
      verification_reason: verificationReason,
      user_mission: updatedUserMission,
      profile: {
        total_points: awardResult?.total_points,
        explorer_level: awardResult?.explorer_level,
        level_up: awardResult?.level_up,
      },
      new_achievements: awardResult?.new_achievements || [],
    });
  } catch (err) {
    console.error('Unhandled verify-mission error:', err);
    return errorResponse((err as Error).message || 'Internal server error', 500, 'INTERNAL_ERROR');
  }
});
