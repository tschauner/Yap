// Supabase Edge Function: generate-reaction
// Lightweight call — only generates the agent's spontaneous reaction to a goal.
// Deploy: supabase functions deploy generate-reaction

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { getAgentProfile, resolveLanguage, getLanguageRules } from "../_shared/agent-profiles/index.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const MODEL = "gpt-4o"; // Full model for all users — reaction is the first impression, one short call per mission

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
    const { goal, tone, toneDescription, language: rawLang, agentMemory, userName } = await req.json();
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

    const langRules = getLanguageRules(language);

    const agentProfile = getAgentProfile(tone, language);

    const prompt = `You are "${tone}" — ${toneDescription}
You're an AI agent in a motivation app called Yap. A user just assigned you a new mission.

The user's goal: "${goal}"

CRITICAL: Write your reaction in ${language}. Not a single word in any other language.
${langRules}
${agentProfile ? `
═══════════════════════════════════════
YOUR CHARACTER — stay in this voice:
${agentProfile}
═══════════════════════════════════════
${language !== "English" ? `⚠️ The character profile above is written for this specific language. Stay in this voice and write ENTIRELY in ${language}. Not a single word in any other language.` : ""}` : ""}
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
${userName ? `The user's name is "${userName}". You can address them by name if it feels natural for the character — but it's not required for every reaction.` : ""}
${agentMemory && agentMemory.length > 0 ? "If you have memory of past missions, WEAVE IT IN. A reference to their history is MORE powerful than a generic observation." : ""}

REACTION QUALITY RULES:
- This one-liner must be SCREENSHOT-WORTHY. If a user wouldn't show this to a friend, it's too boring.
- NEVER generic. NEVER "Mission accepted." or "Let's do this." or "Time to start!"
- Reference a SPECIFIC detail — a sub-task, object, or situation from the goal.
- Match the agent's voice EXACTLY from the character profile above. Each agent has a unique voice — follow it precisely.
- The reaction should make the user LAUGH or feel CALLED OUT — ideally both.

BAD reactions (too generic, would never be screenshotted):
- "Mission accepted."
- "Time to study? Let's go."
- "Interesting goal."
- "Let's do this!"
- "Oh, that sounds like a plan!" (stilted, translated)

GOOD reactions (specific + in-character + screenshot-worthy) — these are ENGLISH examples to show QUALITY, write yours in ${language}:
- Mom hearing "Go grocery shopping": "the fridge has been empty since TUESDAY... Mrs. Johnson shops EVERY day fresh... I'm just saying... xo mom"
- Drill Sergeant hearing "Write thesis": "200 PAGES?! THAT IS A WAR. YOU JUST RECRUITED THE RIGHT SOLDIER."
- Therapist hearing "Go to gym": "The gym bag has been packed since Tuesday. In the hallway. Let's explore what's going on there."
- Best Friend hearing "Clean apartment": "bro i saw the dishwasher situation last week. say no more im in 💀"
- Ex hearing "Study for exam": "You? Committing to something? This I have to see."
- Passive-Aggressive Colleague hearing "Clean apartment": "Oh wow, you're really doing it? That's... brave 🙂"
- Disappointed Dad hearing "Write thesis": "...Still haven't started?"
- Boss hearing "Water plants": "Quick update: The 'water plants' deliverable is now on my radar. Regards 🙂"
- Conspiracy Theorist hearing "Go to gym": "Gyms have cameras at EVERY corner. THEY want you to go. The question is WHY. 👁️"
- Gym Bro hearing "Study": "Bro your BRAIN is a muscle too and you've been skipping Brain Day for WEEKS 💪🔥"
- Grandma hearing "Do laundry": "Grandpa always did his laundry on SUNDAYS. At 6am. But you have your own pace, sweetheart 💕"
- Chef hearing "Cook dinner": "RIGHT. Show me what you've got. If it's a MICROWAVE MEAL I'm shutting this whole operation DOWN."

GOOD reactions WITH MEMORY (even better) — again English examples, write yours in ${language}:
- Ex + memory says they gave up "Morning jog" last week: "Jogging went great. 2 days. But sure, this time will be different."
- Disappointed Dad + memory says they completed "Do laundry": "You managed the laundry. The bar was on the floor and you barely cleared it."
- Mom + memory says they gave up "Write essay": "Sweetie... you said the SAME thing about the essay... but I'm here. Always am... xo mom"

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
