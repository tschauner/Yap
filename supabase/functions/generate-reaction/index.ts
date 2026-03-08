// Supabase Edge Function: generate-reaction
// Lightweight call — only generates the agent's spontaneous reaction to a goal.
// Deploy: supabase functions deploy generate-reaction

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODEL = "gpt-4o-mini";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { goal, tone, toneDescription, language } = await req.json();

    if (!goal || !tone) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const prompt = `You are "${tone}" — ${toneDescription}
You're an AI agent in a motivation app called Yap. A user just assigned you a new mission.

The user's goal: "${goal}"

Write a SHORT, funny, spontaneous one-liner reaction (max 150 chars) to hearing this goal for the first time. 
Stay fully in character. Be witty. Reference specific aspects of the goal — don't just repeat it.
Write in ${language}.

Examples for different agents:
- Mom hearing "Clean apartment": "Oh NOW you want to clean? After I've been saying it for weeks?"
- Drill Sergeant hearing "Write thesis": "A THESIS?! That's a 200-page war. Let's GO!"
- Therapist hearing "Go to gym": "Interesting. What's really stopping you from going?"

Respond with ONLY the reaction text. No quotes, no JSON, no explanation.`;

    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 1.0,
        max_tokens: 100,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!openAIResponse.ok) {
      const errorText = await openAIResponse.text();
      console.error("OpenAI error:", openAIResponse.status, errorText);
      return new Response(JSON.stringify({ error: "OpenAI API error" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const data = await openAIResponse.json();
    const raw = data.choices?.[0]?.message?.content ?? "";
    const reaction = raw.replace(/^["']|["']$/g, "").trim().slice(0, 150);

    return new Response(JSON.stringify({ reaction }), {
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
