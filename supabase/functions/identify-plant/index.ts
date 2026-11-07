// Edge Function: identify-plant
// File: supabase/functions/identify-plant/index.ts

import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { requireAuth } from '../_shared/auth.ts';
import { PlantCandidate, PlantIdentificationResult } from '../_shared/types.ts';

const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
const PLANTNET_API_BASE = 'https://my-api.plantnet.org/v2/identify/all';
const REQUEST_TIMEOUT_MS = 30000; // 30 seconds

// Curated demo candidates for offline / demo mode
const DEMO_CANDIDATES: PlantCandidate[] = [
  {
    scientific_name: 'Bellis perennis L.',
    common_name: 'Common Daisy',
    family: 'Asteraceae',
    score: 0.92,
  },
  {
    scientific_name: 'Leucanthemum vulgare Lam.',
    common_name: 'Oxeye Daisy',
    family: 'Asteraceae',
    score: 0.54,
  },
  {
    scientific_name: 'Erigeron annuus (L.) Pers.',
    common_name: 'Eastern Daisy Fleabane',
    family: 'Asteraceae',
    score: 0.31,
  },
];

Deno.serve(async (req: Request) => {
  // 1. CORS Preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed. Use POST.', 405);
  }

  try {
    // 2. Validate User Authentication
    // Allows demo/guest fallback if configured
    let userContext;
    try {
      userContext = await requireAuth(req, true);
    } catch (authErr) {
      return errorResponse((authErr as Error).message, 401, 'UNAUTHORIZED');
    }

    const apiKey = Deno.env.get('PLANTNET_API_KEY');
    const isDemoMode = Deno.env.get('DEMO_MODE') === 'true' || !apiKey || apiKey.trim() === '';

    // 3. Process Content-Type & Extract Image
    const contentType = req.headers.get('content-type') || '';
    let imageBlob: Blob | null = null;
    let organ = 'auto'; // organ can be flower, leaf, fruit, bark, auto

    if (contentType.includes('multipart/form-data')) {
      const formData = await req.formData();
      const fileEntry = formData.get('image') || formData.get('file') || formData.get('images');
      organ = (formData.get('organ') as string) || (formData.get('organs') as string) || 'auto';

      if (fileEntry && fileEntry instanceof Blob) {
        imageBlob = fileEntry;
      }
    } else if (contentType.includes('application/json')) {
      const body = await req.json();
      organ = body.organ || body.organs || 'auto';

      if (body.image_base64) {
        const base64Data = body.image_base64.replace(/^data:image\/\w+;base64,/, '');
        const binaryStr = atob(base64Data);
        const bytes = new Uint8Array(binaryStr.length);
        for (let i = 0; i < binaryStr.length; i++) {
          bytes[i] = binaryStr.charCodeAt(i);
        }
        const mimeType = body.mime_type || 'image/jpeg';
        imageBlob = new Blob([bytes], { type: mimeType });
      }
    } else if (contentType.startsWith('image/')) {
      const arrayBuffer = await req.arrayBuffer();
      imageBlob = new Blob([arrayBuffer], { type: contentType });
    }

    // 4. Validate Image
    if (!imageBlob) {
      return errorResponse(
        'Missing image file. Provide image as multipart form-data or base64 JSON payload.',
        400,
        'MISSING_IMAGE',
      );
    }

    if (imageBlob.size > MAX_IMAGE_SIZE_BYTES) {
      return errorResponse(
        `Image exceeds maximum limit of 10MB (${(imageBlob.size / (1024 * 1024)).toFixed(2)} MB received).`,
        400,
        'IMAGE_TOO_LARGE',
      );
    }

    // Validate MIME type if known
    if (imageBlob.type && !ALLOWED_MIME_TYPES.includes(imageBlob.type.toLowerCase())) {
      // If type not recognized or generic octet-stream, check prefix or allow standard images
      if (!imageBlob.type.startsWith('image/')) {
        return errorResponse(
          `Unsupported image type: ${imageBlob.type}. Allowed formats: JPEG, PNG, WEBP, HEIC.`,
          400,
          'UNSUPPORTED_MEDIA_TYPE',
        );
      }
    }

    // 5. Handle Demo / Offline Mode if API key is not configured
    if (isDemoMode) {
      console.warn('PLANTNET_API_KEY is not set or DEMO_MODE=true. Returning mock identification.');
      const demoResult: PlantIdentificationResult = {
        status: 'identified',
        is_demo: true,
        candidates: DEMO_CANDIDATES,
      };
      return jsonResponse(demoResult);
    }

    // 6. Prepare Pl@ntNet Request
    const plantNetFormData = new FormData();
    plantNetFormData.append('images', imageBlob, 'specimen.jpg');
    if (organ && organ !== 'auto') {
      plantNetFormData.append('organs', organ);
    }

    const apiUrl = new URL(PLANTNET_API_BASE);
    apiUrl.searchParams.set('api-key', apiKey!);
    apiUrl.searchParams.set('include-related-images', 'false');

    // 7. Execute Request with 30s Timeout
    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(apiUrl.toString(), {
        method: 'POST',
        body: plantNetFormData,
        signal: abortController.signal,
      });

      clearTimeout(timeoutId);

      // Handle Rate Limiting
      if (response.status === 429) {
        return errorResponse(
          'Pl@ntNet rate limit exceeded. Please try again in a few moments.',
          429,
          'RATE_LIMITED',
        );
      }

      // Handle Pl@ntNet Not Found or Low Confidence
      if (response.status === 404) {
        const notFoundResult: PlantIdentificationResult = {
          status: 'uncertain',
          is_demo: false,
          candidates: [],
          error: 'No matching botanical species could be recognized for this photograph.',
        };
        return jsonResponse(notFoundResult, 200);
      }

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`Pl@ntNet API error [${response.status}]:`, errorText);
        return errorResponse(
          `Pl@ntNet API returned status ${response.status}`,
          502,
          'PLANTNET_API_ERROR',
          { status: response.status },
        );
      }

      const rawData = await response.json();

      // 8. Normalize Candidates
      const candidates: PlantCandidate[] = [];
      const results = rawData.results || [];

      for (const item of results.slice(0, 5)) {
        const species = item.species || {};
        const scientificName = species.scientificNameWithoutAuthor
          ? `${species.scientificNameWithoutAuthor}${species.scientificNameAuthorship ? ` ${species.scientificNameAuthorship}` : ''}`
          : species.scientificName || 'Unknown species';

        const commonNames = species.commonNames || [];
        const commonName = commonNames.length > 0 ? commonNames[0] : null;
        const familyName = species.family?.scientificNameWithoutAuthor || species.family?.scientificName || null;
        const score = typeof item.score === 'number' ? Math.round(item.score * 100) / 100 : 0;

        candidates.push({
          scientific_name: scientificName,
          common_name: commonName,
          family: familyName,
          score,
        });
      }

      // Determine Identification Confidence Status
      let status: 'identified' | 'uncertain' | 'failed' = 'identified';
      if (candidates.length === 0) {
        status = 'failed';
      } else if (candidates[0].score < 0.25) {
        status = 'uncertain';
      }

      const normalizedResponse: PlantIdentificationResult = {
        status,
        is_demo: false,
        candidates,
      };

      return jsonResponse(normalizedResponse);
    } catch (fetchErr) {
      clearTimeout(timeoutId);
      if ((fetchErr as Error).name === 'AbortError') {
        return errorResponse(
          'Plant identification request timed out after 30 seconds.',
          504,
          'TIMEOUT',
        );
      }
      throw fetchErr;
    }
  } catch (err) {
    console.error('Unhandled identify-plant exception:', err);
    return errorResponse((err as Error).message || 'Internal server error', 500, 'INTERNAL_ERROR');
  }
});
