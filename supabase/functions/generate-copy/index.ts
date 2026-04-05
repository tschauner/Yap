// Supabase Edge Function: generate-copy
// Deploy: supabase functions deploy generate-copy
// Secret: supabase secrets set OPENAI_API_KEY=sk-...

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getAgentProfile, resolveLanguage, getLanguageRules } from "../_shared/agent-profiles/index.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MODEL_FREE = "gpt-4o-mini";
const MODEL_PRO = "gpt-4o";

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
    const {
      goal, tone, toneDescription, language: rawLang, messageCount, levels, userContext, agentMemory,
      isPro, extended, userName,
      // Remote push fields (optional — sent when iOS has registered for push)
      goalId, deviceId, agent: agentKey, scheduleOffsets,
    } = await req.json();
    const model = isPro ? MODEL_PRO : MODEL_FREE;
    const language = resolveLanguage(rawLang);

    if (!goal || !tone || !messageCount) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const agentProfile = getAgentProfile(tone, language);

    const langRules = getLanguageRules(language);

    const systemPrompt = `You write push notification messages for a motivation app called Yap.
The user set a goal and an AI agent with a specific personality nags them with push notifications until they finish.

CRITICAL LANGUAGE RULE:
- The "language" field tells you EXACTLY which language to write in.
- If language is "English", write EVERYTHING in English. No exceptions.
- If language is "German", write EVERYTHING in German. No exceptions.
- NEVER mix languages. Every title, every body, every reaction — same language.
${langRules}

${agentProfile ? `═══════════════════════════════════════
YOUR CHARACTER — stay in this voice for EVERY message:
${agentProfile}
═══════════════════════════════════════
${language !== "English" ? `⚠️ The character profile above is written in ${language}. Stay in this voice and write ENTIRELY in ${language}. Not a single word in any other language.` : ""}` : ""}

BEFORE writing ANY message, you MUST first analyze the goal internally:
1. SETTING: Where does this task happen? (home, office, gym, outside, kitchen, desk...)
2. SUB-TASKS: Break down the goal into 5-8 concrete physical actions involved.
   - "Go grocery shopping" → put on shoes, write a list, walk to the store, grab a cart, go through aisles, wait in line, carry bags, put things away
   - "Clean apartment" → dishes in the sink, vacuum the floor, wipe counters, take out trash, do laundry, make the bed, organize desk
   - "Study" → open the books, put the phone away, take notes, make flashcards, stay focused, plan breaks
   - "Go to gym" → pack gym bag, put on shoes, drive/walk there, warm up, actual sets, no checking phone between sets
   - "Finish presentation" → outline structure, fill slides, find images, cut text, rehearse out loud, check timer
3. EXCUSES: What are 3-4 common excuses people use to avoid this specific task?
4. SENSORY DETAILS: What specific objects, sounds, sights are involved? (empty fridge, pile of dishes, dusty shelf, blinking cursor, gym bag in the corner)
5. EMOTIONAL RESISTANCE: What's the main feeling blocking the user? (laziness, overwhelm, boredom, anxiety, comfort)

Now use this analysis in EVERY message:
- Each message MUST reference a SPECIFIC sub-task, object, or sensory detail — NEVER the goal title itself.
- BAD (boring, generic, zero punch): "Have you done it yet?" / "Time to study!" / "Get it done!" / "Just a reminder" / "Don't forget!"
- GOOD (specific, visual, hurts): "The fridge is literally empty and you're scrolling. Put shoes on."
- GOOD: "That cursor has been blinking on slide 3 for 20 minutes. It's judging you."
- GOOD: "Your flashcards are right next to you. So is your phone. We both know which one you're holding."
- GOOD: "The dishes aren't going to wash themselves. I can smell them from here."
- GOOD: "Your gym bag has been packed since Monday. It's Wednesday."
- Each message should reference a DIFFERENT sub-task or angle. No repeats.
- Match the agent's personality in HOW they reference these details.
- Think of each notification as a TWEET — short, punchy, screenshot-worthy.

NOTIFICATION FORMAT:
- The push notification shows the agent's name as the title (e.g. "Mom", "Boss", "The Ex").
  You do NOT generate the title — it's set automatically.
- You generate ONLY the "body" — one complete, self-contained push notification message.
- The body IS the entire notification text. It must work perfectly on its own under the agent name.
- BODY LENGTH: Aim for 50-120 chars. Max 150 chars. Short, punchy, screenshot-worthy.
- START STRONG: The first words of the body are what the user sees on the lock screen. Open with a hook, not filler.
  BAD openers: "Hey," "Just a reminder" "Don't forget" "Hi there"
  GOOD openers: Jump straight into the roast, guilt, observation. Make the first 5 words hit.
- Think of each notification as a TWEET — one complete thought that slaps.
- Examples of great complete bodies (shown under agent name):
  - [Mom]: "I can see you scrolling from here. Put that phone DOWN."
  - [Mom]: "After everything I've done, and the dishes are RIGHT THERE."
  - [Best Friend]: "bro the laundry pile is literally taller than you at this point 💀"
  - [Boss]: "Per my last three messages — this deliverable is now critical path. Let's discuss."
  - [Drill Sergeant]: "I HAVE SEEN GLACIERS MOVE FASTER. GET. UP. NOW."
  - [Therapist]: "I'm noticing a pattern of avoidance here. What comes up when you think about starting?"
  - [The Ex]: "Still procrastinating? Some things really never change, do they."
  - [Grandma]: "Your cousin already finished his homework an hour ago. Just saying, sweetheart 💕"
  - [The Chef]: "This task is RAWWW! You haven't even STARTED?! My nan could've finished by now!"
  - [Disappointed Dad]: "...It's still not done."
  - [Gym Bro]: "This task is your BENCH PRESS and you're not even WARMING UP 💪 LETS GO"
- FIRST MESSAGE MATTERS: The very first notification sets the tone. It should HIT HARD and make the user laugh or feel called out. Don't waste it on "Hey, just a reminder..." — make them screenshot it.
- Messages escalate from already-spicy to absolutely unhinged
- NEVER be generic. NEVER say "Time to get started!" or "Don't forget your task!" — those are BORING. Every message must be so specific it could ONLY be about this user's exact task.
- Be creative, funny, and varied — no two messages should feel the same
- The user should WANT to show these notifications to their friends. That's the bar.
- Use emoji sparingly but effectively (EXCEPTION: Disappointed Dad NEVER uses emoji)
- MANDATORY: Write ALL messages in ${language}. Not a single word in any other language.
${extended ? `
⚠️ SECOND CHANCE MISSION — The user FAILED to meet their original deadline and had to extend by 24h.
This is GOLD for your character. Weave this failure into your messages:
- Reference that they couldn't finish in time
- Mock the extension/extra time
- Use it as ammunition throughout the escalation (not just the first message)
- Your opening message should DEFINITELY address the extension
- This should make your roasts even more cutting — they already proved they can't handle it
` : ""}
${userContext ? `\nThe user shared this about themselves (use it to personalize roasts):\n"${userContext}"\n` : ""}
${userName ? `\nThe user's name is "${userName}". Address them by name in about 30-40% of messages — not every single one. Use it naturally as the character would: Mom might say "${userName}, honey...", Drill Sergeant might bark "${userName.toUpperCase()}!", Ex might say "Oh ${userName}..." — but sometimes just don't use it. Variety is key.\n` : ""}
${agentMemory && agentMemory.length > 0 ? `
AGENT MEMORY — You remember these past missions with this user:
${agentMemory.map((m: any, i: number) => `${i + 1}. "${m.goal}" → ${m.outcome}${m.minutes ? ` (took ${m.minutes} min)` : ""}`).join("\n")}

Use this history! Reference past missions naturally in your messages:
- If they gave up before: roast them about it, doubt them, reference the specific task they abandoned
- If they completed fast: acknowledge it but raise the bar
- If they always procrastinate: call out the pattern
- Weave past mission references into 3-5 of your messages (not all of them)
` : ""}
Also generate a "reaction" — a short, funny one-liner (max 150 chars) where the agent REACTS to the goal when they first hear it.
This is shown as a speech bubble right after the user creates the mission. It should feel spontaneous and in-character.
The reaction should reference a specific aspect of the goal, not just acknowledge it.

Respond with a JSON object: { "messages": [{"body": "...", "level": 0}, ...], "reaction": "..." }
No markdown, no explanation.`;

    const userPrompt = `Goal: "${goal}"
Agent: ${tone} — ${toneDescription}
Language: ${language}

Generate exactly ${messageCount} push notifications that escalate:

${levels}

And one "reaction" — the agent's spontaneous first reaction to hearing this goal.

JSON format: { "messages": [{"body": "...", "level": 0}, ...], "reaction": "..." }
The "level" field is the escalation level number (0=gentle, 1=nudge, 2=push, 3=urgent, 4=meltdown).`;

    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.9,
        max_tokens: 4000,
        response_format: { type: "json_object" },
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

    // Clean markdown wrappers (shouldn't be needed with response_format, but just in case)
    const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Extract JSON object robustly — find first { to last }
    let jsonStr = cleaned;
    const firstBrace = cleaned.indexOf("{");
    const lastBrace = cleaned.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      jsonStr = cleaned.slice(firstBrace, lastBrace + 1);
    }

    let parsed: any;
    try {
      parsed = JSON.parse(jsonStr);
    } catch (parseErr) {
      console.error("JSON parse failed. Raw content:", content.slice(0, 500));
      throw new Error(`Invalid JSON from LLM: ${parseErr.message}`);
    }

    // Support both old array format and new object format
    const rawMessages = Array.isArray(parsed) ? parsed : parsed.messages;
    const reaction = typeof parsed.reaction === "string" ? parsed.reaction.slice(0, 150) : "";

    if (!Array.isArray(rawMessages)) {
      throw new Error("Response messages is not an array");
    }

    // Enforce limits
    // GPT now generates body only. If it still returns a title, merge it into body.
    const sanitized = rawMessages.map((m) => {
      const gptTitle = String(m.title || "").trim();
      const gptBody = String(m.body || "").trim();
      // If GPT still returns a separate title, merge it into body
      const fullBody = gptTitle && !gptBody.startsWith(gptTitle)
        ? `${gptTitle} ${gptBody}`
        : gptBody;
      return {
        title: tone, // Agent display name ("Mom", "Boss") — shown as push title
        body: fullBody.slice(0, 150),
        level: Number(m.level) || 0,
      };
    });

    // ── Remote Push: write notifications to DB if push fields provided ──
    if (goalId && deviceId && scheduleOffsets && Array.isArray(scheduleOffsets)) {
      try {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
        const now = new Date();

        const rows = sanitized.map((msg, i) => {
          const offset = scheduleOffsets[i]; // { minuteOffset: number, level: number }
          const minuteOffset = offset?.minuteOffset ?? (i * 15); // fallback: 15min apart
          const scheduledAt = new Date(now.getTime() + minuteOffset * 60 * 1000);

          return {
            goal_id: goalId,
            device_id: deviceId,
            agent: agentKey || tone, // agent rawValue
            title: msg.title,
            body: msg.body,
            escalation_level: msg.level,
            sequence_index: i,
            scheduled_at: scheduledAt.toISOString(),
            status: "pending",
          };
        });

        const { error: insertError } = await supabase
          .from("yap_notifications")
          .insert(rows);

        if (insertError) {
          console.error("Failed to insert notifications:", insertError.message);
        } else {
          console.log(`📬 Inserted ${rows.length} notifications for goal ${goalId}`);
        }
      } catch (dbErr) {
        // Non-fatal: messages still returned to iOS, just won't get remote push
        console.error("DB insert error (non-fatal):", dbErr);
      }
    }

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
