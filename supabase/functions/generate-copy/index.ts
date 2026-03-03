// Supabase Edge Function: generate-copy
// Deploy: supabase functions deploy generate-copy
// Secret: supabase secrets set OPENAI_API_KEY=sk-...

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODEL = "gpt-4o-mini";

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { goal, tone, toneDescription, language, messageCount, levels } = await req.json();

    if (!goal || !tone || !messageCount) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const systemPrompt = `You write push notification messages for a reminder app called Yap.
The user set a goal and you need to write escalating reminder notifications.

Rules:
- Each message has a "title" (max 40 chars, catchy) and a "body" (max 120 chars)
- Messages escalate from gentle to absolutely unhinged
- Reference the user's specific goal naturally — don't just paste it in
- Be creative, funny, and varied — no two messages should feel the same
- Match the tone/personality described below
- Use emoji sparingly but effectively
- IMPORTANT: Write ALL messages in ${language}

Respond ONLY with a JSON array, no markdown, no explanation.`;

    const userPrompt = `Goal: "${goal}"
Tone: ${tone} — ${toneDescription}
Language: ${language}

Generate exactly ${messageCount} push notifications that escalate:

${levels}

JSON format: [{"title": "...", "body": "...", "level": 0}, ...]
The "level" field is the escalation level number (0=gentle, 1=nudge, 2=push, 3=urgent, 4=meltdown).`;

    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0.9,
        max_tokens: 2000,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
      }),
    });

    if (!openAIResponse.ok) {
      const errorText = await openAIResponse.text();
      console.error("OpenAI error:", openAIResponse.status, errorText);
      return new Response(JSON.stringify({ error: "OpenAI API error", status: openAIResponse.status }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const data = await openAIResponse.json();
    const content = data.choices?.[0]?.message?.content ?? "";

    // Clean markdown wrappers
    const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Validate JSON
    const messages = JSON.parse(cleaned);

    if (!Array.isArray(messages)) {
      throw new Error("Response is not an array");
    }

    // Enforce limits
    const sanitized = messages.map((m) => ({
      title: String(m.title || "").slice(0, 40),
      body: String(m.body || "").slice(0, 120),
      level: Number(m.level) || 0,
    }));

    return new Response(JSON.stringify({ messages: sanitized }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
