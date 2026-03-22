// Supabase Edge Function: generate-reaction
// Lightweight call — only generates the agent's spontaneous reaction to a goal.
// Deploy: supabase functions deploy generate-reaction

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODEL = "gpt-4o-mini";

const LANG_MAP: Record<string, string> = {
  en: "English",
  de: "German",
  fr: "French",
  es: "Spanish",
};

function resolveLanguage(lang: string): string {
  return LANG_MAP[lang?.toLowerCase()] ?? lang ?? "English";
}

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
    const { goal, tone, toneDescription, language: rawLang } = await req.json();
    const language = resolveLanguage(rawLang);

    if (!goal || !tone) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const prompt = `You are "${tone}" — ${toneDescription}
You're an AI agent in a motivation app called Yap. A user just assigned you a new mission.

The user's goal: "${goal}"

CRITICAL: Write your reaction in ${language}. Not a single word in any other language.

BEFORE you react, quickly think about what this goal ACTUALLY involves:
- What's the physical setting? What objects/tools are involved?
- What specific sub-tasks does this break down into?
- What's the user probably avoiding right now instead of doing it?
- What sensory detail (empty fridge, dusty gym bag, blinking cursor) captures the situation?

Now write a SHORT, funny, spontaneous one-liner reaction (max 150 chars) to hearing this goal.
Your reaction MUST reference a SPECIFIC detail of the goal — a sub-task, an object, a situation — NOT the goal title.

Stay fully in character. Be witty.

BAD reactions (too generic):
- "Time to study? Let's go."
- "Time to clean? Let's go!"
- "Interesting goal."

GOOD reactions (specific + in-character):
- Mom hearing "Go grocery shopping": "The fridge has been empty since TUESDAY. Tuesday."
- Drill Sergeant hearing "Write thesis": "200 PAGES?! That's a WAR. Grab your keyboard, soldier!"
- Therapist hearing "Go to gym": "Your gym bag has been packed since Tuesday. What's really stopping you?"
- Best Friend hearing "Clean apartment": "Bro I saw the dish situation last week. Respect for finally doing something."
- Ex hearing "Study for exam": "Interesting. You could never commit to anything when we were together either."

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
