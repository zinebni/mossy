// Edge Function: generate-discovery-content
// File: supabase/functions/generate-discovery-content/index.ts

import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { EducationalContent, SpeciesContentResponse } from '../_shared/types.ts';

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
const REQUEST_TIMEOUT_MS = 25000;

function cleanJsonText(rawText: string): string {
  let cleaned = rawText.trim();
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.replace(/^```json\s*/, '').replace(/\s*```$/, '');
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```\s*/, '').replace(/\s*```$/, '');
  }
  return cleaned.trim();
}

function getDemoContent(scientificName: string, commonName: string | null, family: string | null): EducationalContent {
  return {
    introduction: `Meet ${commonName || scientificName}, a charming specimen from the ${family || 'plant'} family!`,
    description: `A resilient botanical plant recognized for its distinctive foliage and blossoms. It thrives in diverse outdoor environments, playing an essential role in local biodiversity.`,
    fun_facts: [
      `The botanical name "${scientificName}" reflects historical classifications established by early naturalists.`,
      `Its flowers provide important nectar and pollen for visiting bees and native pollinators.`,
      `Many species in this family adjust their petals in response to sunlight and ambient humidity.`,
    ],
    observation_tips: [
      `Inspect the leaf edges and veining patterns to distinguish it from similar varieties.`,
      `Observe whether the flower heads follow the direction of the sun throughout the day.`,
      `Check the underside of the foliage for subtle hairs or textures.`,
    ],
    safety_note: null,
  };
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

    // 2. Parse Request Body
    const body = await req.json().catch(() => ({}));
    const scientificName = (body.scientific_name || '').trim();
    const commonName = (body.common_name || '').trim() || null;
    const family = (body.family || '').trim() || null;
    const language = (body.language || 'en').trim().toLowerCase();

    if (!scientificName) {
      return errorResponse('Missing required parameter: scientific_name', 400, 'MISSING_PARAM');
    }

    // 3. Check species_cache
    const { data: cachedRow, error: cacheErr } = await adminClient
      .from('species_cache')
      .select('scientific_name, common_name, family, educational_content, language')
      .ilike('scientific_name', scientificName)
      .eq('language', language)
      .maybeSingle();

    if (cachedRow && cachedRow.educational_content) {
      const response: SpeciesContentResponse = {
        status: 'success',
        scientific_name: cachedRow.scientific_name,
        common_name: cachedRow.common_name,
        family: cachedRow.family,
        language: cachedRow.language,
        cached: true,
        is_demo: false,
        data: cachedRow.educational_content as EducationalContent,
      };
      return jsonResponse(response);
    }

    // 4. Handle Demo / Offline Mode if GEMINI_API_KEY is missing
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    const isDemoMode = Deno.env.get('DEMO_MODE') === 'true' || !geminiApiKey || geminiApiKey.trim() === '';

    if (isDemoMode) {
      console.warn('GEMINI_API_KEY is not configured or DEMO_MODE=true. Returning structured demo content.');
      const demoData = getDemoContent(scientificName, commonName, family);
      const demoResponse: SpeciesContentResponse = {
        status: 'demo',
        scientific_name: scientificName,
        common_name: commonName,
        family: family,
        language,
        cached: false,
        is_demo: true,
        data: demoData,
      };
      return jsonResponse(demoResponse);
    }

    // 5. Construct Structured Gemini Prompt
    const systemPrompt = `You are an expert botanical educator for "Mossy", an AI-powered nature exploration mobile app.
Your tone is warm, friendly, curious, and informative.
Provide accurate educational content about the plant:
- Scientific Name: "${scientificName}"
- Common Name: "${commonName || 'Unknown'}"
- Family: "${family || 'Unknown'}"
- Preferred Language: "${language}"

Guidelines:
1. Explain in an engaging way suitable for curious nature explorers of all ages.
2. Under "safety_note", mention real botanical cautions (e.g., sap irritations, toxic to pets) if known. If completely harmless, return null. Do NOT encourage eating wild plants or make unsubstantiated medical claims.
3. Return ONLY a valid JSON object matching this exact schema:
{
  "introduction": "1-2 warm welcoming sentences introducing the plant",
  "description": "Clear visual and botanical description",
  "fun_facts": ["fact 1", "fact 2", "fact 3"],
  "observation_tips": ["tip 1", "tip 2", "tip 3"],
  "safety_note": null or "warning message string"
}`;

    // 6. Call Gemini API
    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), REQUEST_TIMEOUT_MS);

    let parsedContent: EducationalContent;

    try {
      const geminiUrl = `${GEMINI_API_URL}?key=${geminiApiKey}`;
      const geminiResponse = await fetch(geminiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: systemPrompt }],
            },
          ],
          generationConfig: {
            temperature: 0.3,
            responseMimeType: 'application/json',
          },
        }),
        signal: abortController.signal,
      });

      clearTimeout(timeoutId);

      if (!geminiResponse.ok) {
        const errorText = await geminiResponse.text();
        console.error(`Gemini API error [${geminiResponse.status}]:`, errorText);
        return errorResponse(
          `Gemini API returned status ${geminiResponse.status}`,
          502,
          'GEMINI_API_ERROR',
        );
      }

      const geminiData = await geminiResponse.json();
      const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!rawText) {
        throw new Error('Empty response received from Gemini API');
      }

      const cleanedJson = cleanJsonText(rawText);
      const rawParsed = JSON.parse(cleanedJson);

      // Validate schema
      parsedContent = {
        introduction: String(rawParsed.introduction || `${commonName || scientificName} is an intriguing plant to explore.`),
        description: String(rawParsed.description || 'A fascinating species found in outdoor botanical habitats.'),
        fun_facts: Array.isArray(rawParsed.fun_facts) ? rawParsed.fun_facts.map(String) : [],
        observation_tips: Array.isArray(rawParsed.observation_tips) ? rawParsed.observation_tips.map(String) : [],
        safety_note: rawParsed.safety_note ? String(rawParsed.safety_note) : null,
      };
    } catch (apiErr) {
      clearTimeout(timeoutId);
      console.error('Error invoking or parsing Gemini:', apiErr);
      // Fallback to structured fallback if Gemini fails
      parsedContent = getDemoContent(scientificName, commonName, family);
    }

    // 7. Cache Result in species_cache
    try {
      await adminClient.from('species_cache').upsert(
        {
          scientific_name: scientificName,
          common_name: commonName,
          family: family,
          educational_content: parsedContent,
          language,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'scientific_name,language' },
      );
    } catch (saveCacheErr) {
      console.warn('Failed to save to species_cache:', saveCacheErr);
    }

    // 8. Return Response
    const response: SpeciesContentResponse = {
      status: 'success',
      scientific_name: scientificName,
      common_name: commonName,
      family,
      language,
      cached: false,
      is_demo: false,
      data: parsedContent,
    };

    return jsonResponse(response);
  } catch (err) {
    console.error('Unhandled generate-discovery-content error:', err);
    return errorResponse((err as Error).message || 'Internal server error', 500, 'INTERNAL_ERROR');
  }
});
