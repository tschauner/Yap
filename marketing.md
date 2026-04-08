================================================================================
YAP - MARKETING COPY
================================================================================

Same rules as the app: punchy, character voices, no corporate fluff.
Agents used: Mom, The Ex, Drill Sergeant, Theorist, Best Friend, Grandma


================================================================================
TWITTER / X
================================================================================

────────────────────────────────────────
ERSTER POST (persönlich, erster Tweet seit ~10 Jahren)
────────────────────────────────────────

Haven't posted here in about 10 years. Felt like this was worth coming back for.

I built a productivity app where 12 AI agents guilt-trip you into finishing tasks. Mom, your ex, a drill sergeant, grandma, a therapist, a conspiracy theorist, and 6 more.

You set a deadline. They nag you. The messages escalate. They never repeat. You can tell them your weaknesses and they use them against you.

It's called Yap. It's on the App Store. 6 agents are free.

[link]


================================================================================
TWITTER BOT - @YapApp
================================================================================

────────────────────────────────────────
KONZEPT
────────────────────────────────────────

Ein Twitter-Bot der:
1. Als @YapApp-Account selber postet (Agent Voice Tweets, automated)
2. Auf Mentions reagiert - User können Missionen direkt via Twitter setzen

Doppelter Nutzen: Marketing-Kanal + tatsächlich nützliches Feature.

────────────────────────────────────────
FEATURE 1 - AUTOMATED CONTENT POSTING
────────────────────────────────────────

Der Bot postet auf Rotation:
- Agent Voice Tweets (aus dem Pool oben, neue nachgenerieren via OpenAI)
- Agent-to-Agent "Dialoge" (kurze 2-Tweet Exchanges)
- Reaktionen auf aktuelle Events ("It's Monday. The Ex has thoughts.")
- Deadline-Countdown Tweets ("It's 3pm on a Sunday. What did you promise yourself this morning?")

Posting-Frequenz: 2-3 Tweets/Tag, Scheduling via Cron.

Beispiel Auto-Tweets:

  "It's 11pm on a Sunday.

  You know what you promised yourself this morning.

  - Mom"

  ---

  "Productive people don't announce it.
  They just do it.

  Unlike some people.

  - The Ex"

  ---

  "Monday is a psyop designed to make you feel like starting fresh is special.
  EVERY DAY IS A DEADLINE.
  MOVE.

  - The Theorist"

────────────────────────────────────────
FEATURE 2 - PUBLIC MENTION COMMANDS
────────────────────────────────────────

User tweeten @YapApp an - Bot reagiert öffentlich und schickt eine DM oder
Push-Notification (wenn User das App hat und linked ist).

BEFEHL-SYNTAX:

  @YapApp [Agent] remind me [Task] on/by/in [Zeit]

BEISPIELE:

  @YapApp Mom remind me to finish my taxes by Friday
  -> Bot antwortet: "Oh, taxes. Of course you left those to the last minute.
     I'll be in touch. - Mom 👀"
  -> App-Notification am Mittwoch, Donnerstag eskalierend bis Freitag

  @YapApp Ex remind me to call back my therapist tomorrow
  -> Bot antwortet: "Interesting that you need to be reminded to do things
     that are good for you. I'll make a note. - The Ex"

  @YapApp Drill remind me to submit the report in 2 hours
  -> Bot antwortet: "TWO HOURS, MAGGOT. I'LL BE WATCHING. - Drill Sergeant"

  @YapApp Theorist remind me to finish my essay by Sunday
  -> Bot antwortet: "They don't want you to finish that essay.
     That's why I'm helping you. - The Theorist"

Agent-Keywords:
  Mom / mom
  Ex / ex
  Drill / drillsergeant / drill sergeant / sergeant
  Grandma / grandma / gran
  Therapist / therapy
  Theorist / conspiracy
  Boss / boss
  BestFriend / bestfriend / bro
  (usw. - matching fuzzy)

Zeitvarianten:
  "by Friday" / "on Monday" / "in 2 hours" / "tomorrow" / "tonight" / "at 5pm"

────────────────────────────────────────
FEATURE 3 - PUBLIC ENGAGEMENT REPLIES
────────────────────────────────────────

Bot reagiert auf bestimmte Keywords in öffentlichen Tweets (optional,
konfigurierbar - vorsichtig einsetzen um nicht Spam zu wirken):

Keywords: "procrastinating", "can't start", "supposed to be working",
"so unproductive", "haven't started yet"

Antwort-Beispiele (Agent-Rotation):

  User: "I'm so unproductive today ugh"
  @YapApp: "We noticed. - Mom"

  User: "why can't I just start the thing"
  @YapApp: "What's really stopping you?
             ...
             (we can wait) - Therapist"

  User: "Day 3 of not starting my essay"
  @YapApp: "They designed distraction specifically for essays.
             That's why we exist. - The Theorist"

  -> Jede Antwort endet mit App Store Link oder "set a mission: [link]"

────────────────────────────────────────
FEATURE 4 - LEADERBOARD TWEETS (automated)
────────────────────────────────────────

Wöchentlicher Auto-Tweet mit echten Leaderboard-Daten:

  "Week recap - who got the job done:

  1. Therapist - 90% success rate
  2. Mom - 89%
  3. Drill Sergeant - 84%
  4. The Ex - 50% (still going through it)

  12,847 missions set this week.
  6,204 actually finished.

  The rest... we don't talk about.

  yap.fail/leaderboard"

────────────────────────────────────────
TECHNISCHE ÜBERSICHT (Konzept)
────────────────────────────────────────

  Twitter API v2:
  - Read/Write Access (Basic tier = $100/mo - oder via Elevated Zugang)
  - Webhook oder Polling für Mention-Detection
  - DM-API für optionale private Follow-ups

  Bot-Backend (Supabase Edge Function oder separater Service):
  - mention_commands tabelle: {tweet_id, user_handle, agent, task, due_date, status}
  - Cron-Job checkt alle 15min auf neue Mentions
  - Parsed Task + Deadline aus natürlichem Text via OpenAI (function calling)
  - Wenn User die App hat und Twitter linked: Push direkt in die App
  - Wenn nicht: Bot-Reply als öffentliche Erinnerung am Fälligkeitstag

  Twitter-App-Linking (optional, Phase 2):
  - "Link your Twitter in Yap Settings" -> OAuth Flow
  - Danach: @YapApp Mentions triggern echte App-Missionen + Notifications
  - Ohne Linking: nur Twitter-Bot-Replies (kein Account nötig zum Nutzen)

  Auto-Content:
  - Pool von 50+ vorgefertigten Tweets (aus marketing.md)
  - Täglich 2-3 neue via OpenAI generiert, gefiltert + manuell reviewed
  - Scheduling via Cron, keine doppelten Posts

────────────────────────────────────────
ONBOARDING TWEET (wenn jemand @YapApp zum ersten Mal nutzt)
────────────────────────────────────────

  Hey [user]. 
  
  You tweeted at the right place.

  Here's how this works:
  
  @YapApp [Agent] remind me [task] by [date]

  Available agents: Mom, The Ex, Drill Sergeant, Grandma,
  Therapist, Theorist, Boss, Best Friend.

  Or just download the app for the full experience.
  [App Store link]
  
  - The Agency


================================================================================
SHORT-FORM VIDEO SCRIPTS (TikTok / Reels)
================================================================================

────────────────────────────────────────
Script 1: "The Ex" (15 sec)
────────────────────────────────────────

[text on screen, typing sound]

Notification: "Interesting that you haven't started yet."
Notification: "This is why we didn't work out."
Notification: "I'm not mad. I'm just disappointed."
Notification: "Typical."

[cut to: person opens app, completes task]

Voiceover: "We made a productivity app where your AI ex guilt-trips you into being productive."

Text: "It works. Unfortunately."

Yap. App Store. [link in bio]

---

────────────────────────────────────────
Script 2: "Mom escalation" (20 sec)
────────────────────────────────────────

[phone lock screen, notifications appearing one by one]

9:00 - "The apartment won't clean itself. But you knew that 3 hours ago."
11:00 - "I told Grandma you'd rather live in filth than lift a finger."
13:00 - "Your cousin just bought a house. You can't even clean yours."
15:00 - "I'm coming over. Unannounced. Right now."

[phone screen: task marked COMPLETE]

"This is a real app with a real mom agent."

"She escalates."

Yap. [link in bio]

---

────────────────────────────────────────
Script 3: "Pick your villain" (10 sec)
────────────────────────────────────────

Text on screen, fast cuts:

"The app lets you choose who mentally destroys you into productivity"

[quick cuts:]
MOM: "I didn't raise a quitter."
THE EX: "Typical."
DRILL SGT: "MOVE IT, MAGGOT."
GRANDMA: "I survived a war."
THEORIST: "They don't want you to succeed."

"12 agents. Pick your damage."

Yap. [link in bio]



================================================================================
APP STORE FEATURING NOMINATION
================================================================================

Submit via App Store Connect > Featuring Nominations.
Apple empfiehlt 3 Wochen vor Release, idealerweise 3 Monate. Wir releasen diese Woche (KW14/April 2026) - Nomination trotzdem sofort einreichen. Featuring kann auch nachträglich vergeben werden, besonders bei neuen Apps die nach Launch Traktion zeigen.


NOMINATION TYPE
New App Launch


TAGLINE (1 sentence)
Yap is the only productivity app that guilt-trips, roasts, and nags you through push notifications - starring 12 AI agents including your mom, your ex, and your drill sergeant.


NÜTZLICHE DETAILS (max 500 Zeichen)

Yap replaces gentle reminders with AI-generated pressure from 12 characters - Mom, The Ex, Drill Sergeant, Grandma and more. Notifications escalate the longer a task stays unfinished. Users share personal weaknesses, and agents weaponize them. The app lives entirely in push notifications - no need to open it. A global leaderboard ranks agents by real completion rates, turning accountability into a spectator sport.


BESCHREIBUNG (max 1000 Zeichen)

The productivity category has two modes: cheerful habit trackers and to-do list apps nobody opens after a week. Yap is neither. 12 AI characters send escalating push notifications the longer a task goes unfinished. Every message is generated fresh by GPT-4o, never repeated. Users share personal weaknesses, and the agents weaponize them. The app comes to you - no need to open it to feel the pressure.

Yap flips accountability: the agents are the protagonists, not the user. A global leaderboard ranks which agent performs best based on real completion rates. When a user fails, the narrative isn't "you gave up" - it's "your agent didn't deliver." This removes shame and replaces it with humor. Users pick agents not just by personality, but because they want their agent to win.

Fully localized in 6 languages with culturally adapted humor. iOS 17+, available worldwide.


WHY NOW

Yap launches targeting the Gen Z and Millennial audience that has grown fatigued with gentle, gamified productivity tools. The timing aligns with a broader cultural shift toward self-aware humor around productivity anxiety - visible in viral content about AI companions, parasocial relationships with fictional characters, and the general exhaustion with "you got this!" energy. Yap is the first app to fully commit to this anti-self-help, character-driven voice.


LOCALIZATION

Fully localized in 6 languages:
- English
- German
- French
- Spanish
- Portuguese (Portugal)
- Portuguese (Brazil)

Localization includes regionally adapted humor and culturally specific character references (e.g. Mama/Maman instead of "Mom", region-specific sign-offs and references).


TARGET AUDIENCE
18-35, iPhone users, productivity category browsers, comedy/entertainment app fans.


AVAILABILITY
Available now, global launch, iOS 17+.


MARKETING ACTIVITIES
- Twitter/X social campaign via @YapAgency bot posting in-character content (Mom, The Ex, Drill Sergeant, Theorist) - automated, 3x daily
- TikTok/Reels content featuring real notification escalations
- Press outreach targeting tech and lifestyle publications
