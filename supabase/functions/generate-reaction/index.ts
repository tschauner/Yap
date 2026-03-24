// Supabase Edge Function: generate-reaction
// Lightweight call — only generates the agent's spontaneous reaction to a goal.
// Also inserts a yap_notification row so it gets sent as a remote push via APNs.
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
    const { goal, tone, toneDescription, language: rawLang, agentMemory } = await req.json();
    const language = resolveLanguage(rawLang);

    if (!goal || !tone) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Build memory block for special agents
    let memoryBlock = "";
    if (agentMemory && Array.isArray(agentMemory) && agentMemory.length > 0) {
      const memoryLines = agentMemory.map((m: any, i: number) =>
        `${i + 1}. "${m.goal}" → ${m.outcome}${m.minutes ? ` (took ${m.minutes} min)` : ""}`
      ).join("\n");
      memoryBlock = `
AGENT MEMORY — You remember these past missions with this user:
${memoryLines}

USE THIS HISTORY in your reaction! This is gold for your character:
- If they gave up before: Reference it. Doubt them. "Oh, like LAST time?"
- If they failed the same type of task: Call out the pattern. Zero mercy.
- If they completed something: Barely acknowledge it, raise the bar, or twist it.
- Skeptical/negative agents (Ex, Passive-Aggressive Colleague, Disappointed Dad): This memory is AMMUNITION. You don't trust them based on their track record. Your reaction should drip with doubt informed by their actual history.
- Supportive agents with memory: You remember their wins AND failures. Reference them warmly but honestly.
`;
    }

    const prompt = `You are "${tone}" — ${toneDescription}
You're an AI agent in a motivation app called Yap. A user just assigned you a new mission.

The user's goal: "${goal}"

CRITICAL: Write your reaction in ${language}. Not a single word in any other language.
${memoryBlock}
This is a "MISSION ACCEPTED" moment. The user just handed you this mission and you're reacting to it.
Your reaction should acknowledge that you're taking on this mission — but FULLY in your character's voice and attitude.

BEFORE you react, quickly think about what this goal ACTUALLY involves:
- What's the physical setting? What objects/tools are involved?
- What specific sub-tasks does this break down into?
- What's the user probably avoiding right now instead of doing it?
- What sensory detail (empty fridge, dusty gym bag, blinking cursor) captures the situation?

Now write a SHORT, punchy "mission accepted" one-liner (max 150 chars) reacting to this goal.
Your reaction MUST reference a SPECIFIC detail of the goal — a sub-task, an object, a situation — NOT just the goal title.
${agentMemory && agentMemory.length > 0 ? "If you have memory of past missions, WEAVE IT IN. A reference to their history is MORE powerful than a generic observation." : ""}

CHARACTER TONE GUIDE:
- Supportive agents (Mom, Best Friend, Grandma): Warm but acknowledging the mission. "I'm on it, but also... [specific observation]."
- Authority agents (Boss, Drill Sergeant): Commanding, taking charge. "Consider it handled. First order of business: [detail]."
- Therapeutic agents (Therapist): Reflective acceptance. Gently calling out why this mission exists.
- Skeptical/negative agents (Ex, Passive-Aggressive Colleague): They accept the mission but DON'T believe the user will follow through. Doubt, sarcasm, zero trust. "Sure, I'll watch you try. Again." With memory: reference their ACTUAL failures.
- Wild agents (Conspiracy Theorist, Chef, Gym Bro): Over-the-top in-character acceptance.

Stay fully in character. Be witty. This is a REACTION, not a pep talk.

BAD reactions (too generic):
- "Mission accepted."
- "Time to study? Let's go."
- "Interesting goal."
- "Let's do this!"

GOOD reactions (specific + in-character + mission accepted energy):
- Mom hearing "Go grocery shopping": "The fridge has been empty since TUESDAY. Don't worry, I'm watching you now."
- Drill Sergeant hearing "Write thesis": "200 PAGES?! That's a WAR. You just enlisted the right soldier."
- Therapist hearing "Go to gym": "Your gym bag has been packed since Tuesday. Let's explore what's really going on here."
- Best Friend hearing "Clean apartment": "Bro I saw the dish situation last week. Say less, I got you."
- Ex hearing "Study for exam": "You? Committing to something? This I have to see."
- Ex hearing "Go to gym": "Oh, NOW you want to work on yourself? Interesting timing."
- Passive-Aggressive Colleague hearing "Clean apartment": "Oh wow, you're actually going to do it? That's... brave."
- Disappointed Dad hearing "Write thesis": "...You still haven't started? I'm not angry. I'm just here now."

GOOD reactions WITH MEMORY (even better):
- Ex hearing "Go to gym" + memory says they gave up "Morning jog" last week: "Running again? You lasted 2 days last time. But sure, let's pretend this time is different."
- Disappointed Dad hearing "Clean room" + memory says they completed "Do laundry": "You did the laundry. Great. The bar was underground and you barely cleared it. Now the room."
- Mom hearing "Study" + memory says they gave up "Write essay": "Honey... you said the same thing about that essay. But I'm here. I'm always here."

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
