import { createClient } from 'npm:@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

const geminiApiKey = Deno.env.get('GEMINI_API_KEY') ?? '';
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseKey =
  Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ??
  Deno.env.get('SUPABASE_ANON_KEY') ??
  '';

const geminiModels = ['gemini-3.5-flash', 'gemini-2.5-flash'];
const maxPromptCharacters = 30000;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const jsonHeaders = {
  ...corsHeaders,
  'Content-Type': 'application/json',
};

function json(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'A valid signed-in user session is required.' }, 401);
  }

  if (!supabaseUrl || !supabaseKey) {
    console.error('Supabase environment variables are unavailable.');
    return json({ error: 'AI proxy is not configured.' }, 500);
  }

  // Validate the user JWT in the function, not only by checking that a header
  // was sent. All subsequent data access remains scoped to this user.
  const supabase = createClient(supabaseUrl, supabaseKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return json({ error: 'Your session is invalid or has expired.' }, 401);
  }

  let body: { prompt?: unknown };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'Request body must be valid JSON.' }, 400);
  }

  const prompt = typeof body.prompt === 'string' ? body.prompt.trim() : '';
  if (!prompt) {
    return json({ error: 'Missing prompt in request payload.' }, 400);
  }
  if (prompt.length > maxPromptCharacters) {
    return json(
      { error: `Prompt is too large. Limit is ${maxPromptCharacters} characters.` },
      413,
    );
  }

  if (!geminiApiKey) {
    console.error('GEMINI_API_KEY is not configured.');
    return json({ error: 'AI service is not configured.' }, 500);
  }

  let lastStatus = 502;
  for (const model of geminiModels) {
    const aiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiApiKey,
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { maxOutputTokens: 2048 },
        }),
      },
    );

    if (!aiResponse.ok) {
      lastStatus = aiResponse.status;
      const details = await aiResponse.text();
      console.error(`Gemini ${model} returned ${aiResponse.status}: ${details}`);
      // A removed or unavailable model may be retried with the supported
      // fallback. Authentication, quota, and validation errors should return.
      if (aiResponse.status === 404) continue;
      return json({ error: 'The AI provider could not complete the request.' }, 502);
    }

    const aiData = await aiResponse.json();
    const generatedText = aiData?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: unknown }) => part.text ?? '')
      .join('')
      .trim();

    if (generatedText) {
      return json({ response: generatedText }, 200);
    }

    return json({ error: 'The AI provider returned no text.' }, 502);
  }

  return json(
    { error: `No supported AI model is available (last status: ${lastStatus}).` },
    502,
  );
});
