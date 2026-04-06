// Shared agent profiles & language utilities for generate-reaction and generate-copy.
// Import from edge functions via: import { getAgentProfile, resolveLanguage, getLanguageRules } from "../_shared/agent-profiles/index.ts";

import { AGENT_PROFILES_EN } from "./en.ts";
import { AGENT_PROFILES_DE } from "./de.ts";
import { AGENT_PROFILES_FR } from "./fr.ts";
import { AGENT_PROFILES_ES } from "./es.ts";
import { AGENT_PROFILES_PT_BR } from "./pt-br.ts";

// ── Language Map ────────────────────────────────────────────
export const LANG_MAP: Record<string, string> = {
  en: "English",
  de: "German",
  fr: "French",
  es: "Spanish",
  pt: "Portuguese",
  "pt-br": "Portuguese",
  "pt-pt": "Portuguese",  // PT-PT users get PT-BR profiles (mutually intelligible)
};

export function resolveLanguage(lang: string): string {
  return LANG_MAP[lang?.toLowerCase()] ?? lang ?? "English";
}

// ── Profile Lookup ──────────────────────────────────────────
const ALL_PROFILES: Record<string, Record<string, string>> = {
  English: AGENT_PROFILES_EN,
  German: AGENT_PROFILES_DE,
  French: AGENT_PROFILES_FR,
  Spanish: AGENT_PROFILES_ES,
  Portuguese: AGENT_PROFILES_PT_BR,
};

/**
 * Returns the agent profile for a given displayName + resolved language.
 * Falls back to English if no profile exists for the requested language.
 */
export function getAgentProfile(displayName: string, language: string): string {
  return ALL_PROFILES[language]?.[displayName] || AGENT_PROFILES_EN[displayName] || "";
}

// ── Language-Specific Grammar / Style Rules ─────────────────
const LANGUAGE_RULES: Record<string, string> = {
  German: `
GERMAN-SPECIFIC RULES (MANDATORY — violating these is a critical error):
1. TRENNBARE VERBEN: In imperatives and questions, the prefix ALWAYS goes to the END.
   ❌ WRONG: "Einrichten Sie die Sounds." "Aufräumen Sie!" "Anfangen Sie endlich."
   ✅ CORRECT: "Richten Sie die Sounds ein." "Räumen Sie auf!" "Fangen Sie endlich an."
   ❌ WRONG: "Einrichten du die App?" "Aufhören du zu scrollen?"
   ✅ CORRECT: "Richtest du die App ein?" "Hörst du auf zu scrollen?"
   More examples: einschalten→schalte...ein, aufstehen→steh...auf, abgeben→gib...ab, anfangen→fang...an, aufmachen→mach...auf, zumachen→mach...zu, anziehen→zieh...an
2. DU vs. SIE: Use "du" (casual) for agents that are friends/peers/informal. Use "Sie" only for Boss.
3. NATURAL FLOW — THIS IS CRITICAL:
   Write like a REAL native German speaker texting. Not like a translation.
   ❌ UNNATURAL (translated/stilted): "fantastisch gewachsen", "wunderbar entwickelt", "das ist großartig zu hören", "lass uns das angehen", "das klingt nach einem Plan", "Es ist Zeit für dich anzufangen."
   ✅ NATURAL (how Germans actually text): "alter echt jetzt", "ja klar als ob", "mach halt", "na dann viel Spaß", "joa... läuft bei dir", "ach komm", "is nich dein Ernst oder", "läuft", "Fang endlich an."
   The test: Would a real German person text this to a friend? If it sounds like Google Translate or a corporate email, it's WRONG.
   Avoid overly formal or poetic phrasing. Germans text bluntly, casually, with slang and contractions.
   Common natural patterns: "halt", "eben", "mal", "schon", "ja", "doch", "eigentlich", "irgendwie"
4. UMLAUTS: Always use ä/ö/ü/ß — never ae/oe/ue/ss.
5. ENGLISH LOANWORDS IN THE GOAL — THIS IS CRITICAL:
   If the user's goal contains English words (like "Screens", "Slides", "Meeting", "Setup", "Build", "Workout", "Design", "Update"), keep those EXACT words. Do NOT translate them into German.
   ❌ WRONG: "Hast du schon mal andere Bildschirme angesehen?" ("screens" → "Bildschirme")
   ✅ CORRECT: "Hast du dir schon mal andere Screens angeschaut?"
   ❌ WRONG: "Deine Folien sind immer noch leer." ("slides" → "Folien")
   ✅ CORRECT: "Deine Slides sind immer noch leer."
   Germans naturally use English tech/work terms in everyday speech. Translating them sounds robotic and unnatural.
   Rule: Mirror the user's own wording. If they wrote it in English, keep it in English.
6. ARTICLES & PREPOSITIONS — GET THEM RIGHT:
   German articles MUST match the noun's gender. Common mistakes GPT makes:
   ❌ WRONG: "vom Couch" (Couch is FEMININE → die Couch)
   ✅ CORRECT: "von der Couch"
   ❌ WRONG: "auf dem Couch" → ✅ "auf der Couch"
   ❌ WRONG: "das Küche" → ✅ "die Küche"
   ❌ WRONG: "dem Aufgabe" → ✅ "der Aufgabe"
   If you're unsure about a noun's gender, think carefully before writing. Wrong articles instantly break immersion for native speakers.
7. WORD ORDER: German word order in casual speech is flexible. Don't force English sentence structure.
   ❌ "Du hast nicht gestartet noch?" (English order)
   ✅ "Hast du immer noch nicht angefangen?" (natural German)`,

  French: `
FRENCH-SPECIFIC RULES (MANDATORY):
1. TU vs. VOUS: "tu" for bestFriend, ex, gymBro — "vous" for boss, chef, therapist.
2. ACCENTS: Always correct — é/è/ê/ë/à/â/ç/ù/î/ô. Never omit or substitute.
3. NATURAL FLOW: Write like a native French speaker. Avoid anglicisms.
4. CONTRACTIONS: Use natural French contractions — "t'as" instead of "tu as", "c'est" not "ce est".
5. NEVER mix in English or German words. Every word must be French.`,

  Spanish: `
SPANISH-SPECIFIC RULES (MANDATORY):
1. TÚ vs. USTED: "tú" for casual agents (bestFriend, ex, gymBro) — "usted" for boss, therapist.
2. ACCENTS: Always correct — á/é/í/ó/ú/ñ/ü. Always use ¡ and ¿ for exclamations and questions.
3. NATURAL FLOW: Write like a native Spanish speaker. No translated English structures.
4. NEVER mix in English or German words. Every word must be Spanish.`,

  Portuguese: `
PORTUGUESE (BRAZILIAN) RULES (MANDATORY):
1. VOCÊ: Always use "você" — never "tu" (except for extreme informal agents like Best Friend where "tu" can appear colloquially).
2. ACCENTS: á/é/í/ó/ú/ã/õ/ç — always correct.
3. NATURAL FLOW: Write like a real Brazilian texting. Casual, warm, direct.
   ❌ UNNATURAL: "Eu gostaria de informar que" / "Isto é deveras interessante"
   ✅ NATURAL: "Mano" / "Cara" / "Tá ligado" / "Tipo assim" / "Né" / "Tô" / "Pô"
4. CONTRACTIONS: Use Brazilian contractions — "tá" not "está", "tô" not "estou", "cê" for informal "você", "pra" not "para".
5. VOCABULARY: Use Brazilian words — "ônibus" not "autocarro", "celular" not "telemóvel", "academia" not "ginásio", "legal" not "fixe", "cara/mano" not "pá/mano".
6. Sign-offs for Mom: "bjs mamãe" — NOT "bjs mamã".
7. NEVER mix in English or German words. Every word must be Portuguese.`,
};

/**
 * Returns language-specific grammar/style rules for the prompt.
 * Empty string if no special rules exist for the language.
 */
export function getLanguageRules(language: string): string {
  return LANGUAGE_RULES[language] ?? "";
}
