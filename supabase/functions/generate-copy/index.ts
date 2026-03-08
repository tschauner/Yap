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

    const systemPrompt = `You write push notification messages for a motivation app called Yap.
The user set a goal and an AI agent with a specific personality nags them with push notifications until they finish.

Your job:
1. UNDERSTAND what the user actually means — infer the real-world context behind their goal.
   Example: "Clean apartment" → they probably mean dishes, vacuuming, laundry, tidying up.
   Example: "Finish presentation" → they're likely procrastinating on slides for work/school.
   Example: "Go to gym" → they've been skipping and need a push.
2. Write notifications that reference SPECIFIC aspects of the goal, not just the title.
   BAD: "Have you cleaned the apartment yet?"
   GOOD: "Those dishes aren't washing themselves. Start there."
3. Match the agent's personality in how they reference the goal.

Rules:
- Each message has a "title" (max 40 chars, catchy) and a "body" (max 120 chars)
- Messages escalate from gentle to absolutely unhinged
- Be creative, funny, and varied — no two messages should feel the same
- Use emoji sparingly but effectively
- IMPORTANT: Write ALL messages in ${language}

Also generate a "reaction" — a short, funny one-liner (max 150 chars) where the agent REACTS to the goal when they first hear it.
This is shown as a speech bubble right after the user creates the mission. It should feel spontaneous and in-character.
Examples:
- Mom hearing "Clean apartment": "Oh NOW you want to clean? After I've been saying it for weeks?"
- Drill Sergeant hearing "Write thesis": "A THESIS?! That's a 200-page war. Let's GO!"
- Therapist hearing "Go to gym": "Interesting. What's really stopping you from going?"

Respond with a JSON object: { "messages": [...], "reaction": "..." }
No markdown, no explanation.`;

    const userPrompt = `Goal: "${goal}"
Agent: ${tone} — ${toneDescription}
Language: ${language}

Generate exactly ${messageCount} push notifications that escalate:

${levels}

And one "reaction" — the agent's spontaneous first reaction to hearing this goal.

JSON format: { "messages": [{"title": "...", "body": "...", "level": 0}, ...], "reaction": "..." }
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

    // Validate JSON — response is now { messages: [...], reaction: "..." }
    const parsed = JSON.parse(cleaned);

    // Support both old array format and new object format
    const rawMessages = Array.isArray(parsed) ? parsed : parsed.messages;
    const reaction = typeof parsed.reaction === "string" ? parsed.reaction.slice(0, 150) : "";

    if (!Array.isArray(rawMessages)) {
      throw new Error("Response messages is not an array");
    }

    // Enforce limits
    const sanitized = rawMessages.map((m) => ({
      title: String(m.title || "").slice(0, 40),
      body: String(m.body || "").slice(0, 120),
      level: Number(m.level) || 0,
    }));

    return new Response(JSON.stringify({ messages: sanitized, reaction }), {
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
