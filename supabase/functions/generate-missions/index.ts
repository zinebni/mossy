// Edge Function: generate-missions
// File: supabase/functions/generate-missions/index.ts

import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { Mission } from '../_shared/types.ts';

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
const REQUEST_TIMEOUT_MS = 25000;

const CURATED_MISSIONS: Mission[] = [
  {
    title: 'Spot a Golden Bloom',
    description: 'Find and photograph a wild blossom with bright yellow petals, such as a buttercup or dandelion.',
    category: 'daily',
    difficulty: 'easy',
    reward_points: 10,
    verification_criteria: {
      type: 'color_match',
      colors: ['yellow', 'gold', 'amber'],
      description: 'Yellow flower petals',
    },
  },
  {
    title: 'Pinnate Foliage Quest',
    description: 'Discover a plant or tree featuring compound, feather-like pinnate leaves (e.g. Ferns, Acacia, or Rowans).',
    category: 'general',
    difficulty: 'medium',
    reward_points: 25,
    verification_criteria: {
      type: 'morphology',
      target_feature: 'leaf_shape',
      keywords: ['pinnate', 'compound', 'fern'],
      description: 'Feathery or pinnate compound foliage',
    },
  },
  {
    title: 'The Mint Family Trail',
    description: 'Find a member of the Lamiaceae family, noted for aromatic square stems and bilabiate flowers.',
    category: 'special',
    difficulty: 'hard',
    reward_points: 40,
    verification_criteria: {
      type: 'family_match',
      family: 'Lamiaceae',
      synonyms: ['Labiatae'],
      description: 'Specimen in the Lamiaceae (mint) family',
    },
  },
];

function cleanJsonText(rawText: string): string {
  let cleaned = rawText.trim();
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.replace(/^```json\s*/, '').replace(/\s*```$/, '');
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```\s*/, '').replace(/\s*```$/, '');
  }
  return cleaned.trim();
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed. Use POST.', 405);
  }

  try {
    // 1. Auth Validation
    let userContext;
    try {
      userContext = await requireAuth(req, true);
    } catch (authErr) {
      return errorResponse((authErr as Error).message, 401, 'UNAUTHORIZED');
    }

    const { adminClient } = userContext;

    // 2. Parse Options
    const body = await req.json().catch(() => ({}));
    const category = body.category || 'all'; // 'daily', 'general', 'special', 'all'
    const difficulty = body.difficulty || 'all'; // 'easy', 'medium', 'hard', 'all'
    const count = Math.min(Math.max(Number(body.count) || 3, 1), 6);
    const persist = Boolean(body.persist ?? true);

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    const isDemoMode = Deno.env.get('DEMO_MODE') === 'true' || !geminiApiKey || geminiApiKey.trim() === '';

    let generatedMissions: Mission[] = [];

    // 3. Fallback or Demo Generation
    if (isDemoMode) {
      console.warn('GEMINI_API_KEY not configured or DEMO_MODE=true. Returning curated missions.');
      generatedMissions = CURATED_MISSIONS.slice(0, count);
    } else {
      // 4. Construct Prompt for Gemini
      const prompt = `You are a nature challenge designer for "Mossy", an outdoor botanical mobile game.
Generate ${count} engaging, realistic outdoor plant observation challenges.
Filter Criteria:
- Category preference: ${category}
- Difficulty preference: ${difficulty}

Rules:
1. Missions must be achievable by exploring local parks, gardens, or nature trails.
2. Provide precise, machine-verifiable verification criteria.
3. Points scale: 'easy' -> 10-15 pts, 'medium' -> 20-30 pts, 'hard' -> 35-50 pts.
4. Categories must be one of: "daily", "general", "special".
5. Difficulties must be one of: "easy", "medium", "hard".

Verification criteria type must be one of:
- "color_match" with "colors" array
- "family_match" with "family" string
- "morphology" with "target_feature" string
- "plant_type" with "growth_forms" array
- "family_diversity" with "required_unique_families" integer
- "herb_medicinal" with "keywords" array

Return ONLY a JSON array with objects matching:
[
  {
    "title": "Short catchy title",
    "description": "Engaging 1-2 sentence description",
    "category": "daily" | "general" | "special",
    "difficulty": "easy" | "medium" | "hard",
    "reward_points": 20,
    "verification_criteria": {
      "type": "color_match",
      "colors": ["pink", "magenta"],
      "description": "Photograph a pink flower"
    }
  }
]`;

      const abortController = new AbortController();
      const timeoutId = setTimeout(() => abortController.abort(), REQUEST_TIMEOUT_MS);

      try {
        const geminiUrl = `${GEMINI_API_URL}?key=${geminiApiKey}`;
        const geminiRes = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.7,
              responseMimeType: 'application/json',
            },
          }),
          signal: abortController.signal,
        });

        clearTimeout(timeoutId);

        if (!geminiRes.ok) {
          throw new Error(`Gemini status ${geminiRes.status}`);
        }

        const data = await geminiRes.json();
        const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
        const cleaned = cleanJsonText(rawText);
        const parsed = JSON.parse(cleaned);

        if (Array.isArray(parsed)) {
          generatedMissions = parsed.map((m) => ({
            title: String(m.title || 'Nature Challenge'),
            description: String(m.description || 'Explore outdoor plants'),
            category: ['daily', 'general', 'special'].includes(m.category) ? m.category : 'general',
            difficulty: ['easy', 'medium', 'hard'].includes(m.difficulty) ? m.difficulty : 'easy',
            reward_points: Number(m.reward_points) || 15,
            verification_criteria: m.verification_criteria || { type: 'general' },
          }));
        }
      } catch (geminiErr) {
        clearTimeout(timeoutId);
        console.error('Failed to generate with Gemini, falling back to curated:', geminiErr);
        generatedMissions = CURATED_MISSIONS.slice(0, count);
      }
    }

    // 5. Persist to missions table if requested
    const savedMissions: Mission[] = [];
    if (persist && generatedMissions.length > 0) {
      for (const m of generatedMissions) {
        const { data, error } = await adminClient
          .from('missions')
          .insert({
            title: m.title,
            description: m.description,
            category: m.category,
            difficulty: m.difficulty,
            reward_points: m.reward_points,
            verification_criteria: m.verification_criteria,
            is_active: true,
          })
          .select()
          .single();

        if (!error && data) {
          savedMissions.push(data as Mission);
        } else {
          savedMissions.push(m);
        }
      }
    }

    return jsonResponse({
      status: 'success',
      count: generatedMissions.length,
      is_demo: isDemoMode,
      missions: savedMissions.length > 0 ? savedMissions : generatedMissions,
    });
  } catch (err) {
    console.error('Unhandled generate-missions error:', err);
    return errorResponse((err as Error).message || 'Internal server error', 500, 'INTERNAL_ERROR');
  }
});
