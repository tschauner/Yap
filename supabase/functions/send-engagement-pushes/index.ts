// Supabase Edge Function: send-engagement-pushes
// Triggered by pg_cron daily at 10:00 UTC
// Sends two types of re-engagement push notifications:
//   1. no_mission_nudge — user signed up >24h ago but never created a mission
//   2. inactive_winback — user hasn't opened the app in 5+ days (one-time)
//
// Deploy: supabase functions deploy send-engagement-pushes
// Secrets needed (same as send-notifications):
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encode as base64url } from "https://deno.land/std@0.177.0/encoding/base64url.ts";

// ── Config ──────────────────────────────────────────────────

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;

const APNS_HOST = "https://api.push.apple.com";
const APNS_SANDBOX_HOST = "https://api.sandbox.push.apple.com";
const APNS_ENVIRONMENT = Deno.env.get("APNS_ENVIRONMENT") || "production";
const BUNDLE_ID = "com.phitsch.Yap";

// ── APNs JWT Token ──────────────────────────────────────────

let cachedJWT: { token: string; expiresAt: number } | null = null;

async function getAPNsJWT(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJWT && cachedJWT.expiresAt > now) return cachedJWT.token;

  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }))
  );
  const claims = base64url(
    new TextEncoder().encode(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }))
  );
  const signingInput = `${header}.${claims}`;

  const pemContents = APNS_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8", keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false, ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" }, key,
    new TextEncoder().encode(signingInput)
  );

  const sigBytes = new Uint8Array(signature);
  let rawSig: Uint8Array;
  if (sigBytes[0] === 0x30) {
    const rLen = sigBytes[3];
    const rStart = 4;
    const rEnd = rStart + rLen;
    const sLen = sigBytes[rEnd + 1];
    const sStart = rEnd + 2;
    let r = sigBytes.slice(rStart, rEnd);
    let s = sigBytes.slice(sStart, sStart + sLen);
    if (r.length > 32) r = r.slice(r.length - 32);
    if (s.length > 32) s = s.slice(s.length - 32);
    rawSig = new Uint8Array(64);
    rawSig.set(r, 32 - r.length);
    rawSig.set(s, 64 - s.length);
  } else {
    rawSig = sigBytes;
  }

  const token = `${signingInput}.${base64url(rawSig)}`;
  cachedJWT = { token, expiresAt: now + 3000 };
  return token;
}

// ── APNs Send ───────────────────────────────────────────────

async function sendAPNs(token: string, payload: object): Promise<{ success: boolean; reason?: string }> {
  const host = APNS_ENVIRONMENT === "sandbox" ? APNS_SANDBOX_HOST : APNS_HOST;
  const jwt = await getAPNsJWT();

  try {
    const response = await fetch(`${host}/3/device/${token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "5", // low priority for engagement
        "apns-expiration": "0",
      },
      body: JSON.stringify(payload),
    });

    if (response.ok) return { success: true };

    const errorBody = await response.json().catch(() => ({}));
    return { success: false, reason: errorBody.reason ?? `HTTP ${response.status}` };
  } catch (err) {
    return { success: false, reason: err.message };
  }
}

// ── Agent-Specific Localized Messages ─────────────────────────
// 7 agents × 5 languages × 2 push types
// Each message is written in the voice/personality of the agent.

interface EngagementMessage {
  title: string;
  body: string;
}

type AgentMessages = Record<string, Record<string, EngagementMessage[]>>;

const NUDGE_MESSAGES: AgentMessages = {
  // ── Mom ──────────────────────────────────────────
  mom: {
    en: [
      { title: "Honey? 🥺", body: "You downloaded the app but didn't even try one mission. I'm not mad. Just disappointed." },
      { title: "Mom here.", body: "I set up everything for you and you haven't even started. Do I have to do everything myself?" },
    ],
    de: [
      { title: "Schatz? 🥺", body: "Du hast die App runtergeladen aber keine einzige Mission erstellt. Ich bin nicht sauer. Nur enttäuscht." },
      { title: "Mama hier.", body: "Ich hab alles für dich vorbereitet und du fängst nicht mal an. Muss ich wirklich alles selber machen?" },
    ],
    fr: [
      { title: "Mon cœur ? 🥺", body: "Tu as téléchargé l'appli mais tu n'as même pas essayé une seule mission. Je suis pas fâchée. Juste déçue." },
      { title: "C'est maman.", body: "J'ai tout préparé pour toi et tu n'as même pas commencé. Faut que je fasse tout moi-même ?" },
    ],
    es: [
      { title: "¿Cariño? 🥺", body: "Descargaste la app pero no creaste ni una misión. No estoy enfadada. Solo decepcionada." },
      { title: "Soy mamá.", body: "Lo preparé todo para ti y ni siquiera empezaste. ¿Tengo que hacer todo yo?" },
    ],
    pt: [
      { title: "Querido? 🥺", body: "Você baixou o app mas nem criou uma missão. Não tô brava. Só decepcionada." },
      { title: "É a mamãe.", body: "Preparei tudo pra você e nem começou. Eu tenho que fazer tudo sozinha?" },
    ],
  },
  // ── Best Friend ──────────────────────────────────
  bestFriend: {
    en: [
      { title: "bro 💀", body: "you downloaded a whole productivity app and then did nothing. that's kinda iconic tbh" },
      { title: "hey", body: "so you got yap but didn't make a single mission? what was the plan exactly lol" },
    ],
    de: [
      { title: "alter 💀", body: "du lädst dir ne productivity app runter und machst dann nix. irgendwie legendär ngl" },
      { title: "ey", body: "du hast yap aber keine einzige mission erstellt? was war der plan digga" },
    ],
    fr: [
      { title: "mec 💀", body: "t'as téléchargé une appli de productivité et t'as rien fait. c'est iconique en vrai" },
      { title: "hey", body: "t'as yap mais t'as pas créé une seule mission ? c'était quoi le plan mdr" },
    ],
    es: [
      { title: "bro 💀", body: "te descargaste una app de productividad y no hiciste nada. es icónico la verdad" },
      { title: "oye", body: "tienes yap pero no creaste ni una misión. ¿cuál era el plan exactamente jaja?" },
    ],
    pt: [
      { title: "mano 💀", body: "tu baixou um app de produtividade e não fez nada. isso é icônico na real" },
      { title: "ei", body: "tu tem o yap mas não criou nenhuma missão? qual era o plano kkk" },
    ],
  },
  // ── Boss ─────────────────────────────────────────
  boss: {
    en: [
      { title: "Quick check-in", body: "I noticed you haven't created a single mission yet. Just want to make sure you're aware this was due yesterday." },
      { title: "Following up", body: "Per my last notification — you still haven't started. Let's circle back on this ASAP." },
    ],
    de: [
      { title: "Kurze Rückmeldung", body: "Mir ist aufgefallen, dass Sie noch keine Mission erstellt haben. Wollte nur sichergehen, dass Ihnen bewusst ist: Die Deadline war gestern." },
      { title: "Nochmal dazu", body: "Bezugnehmend auf meine letzte Nachricht — Sie haben immer noch nicht angefangen. Bitte zeitnah erledigen." },
    ],
    fr: [
      { title: "Petit point", body: "J'ai remarqué que vous n'avez toujours pas créé de mission. Je voulais juste m'assurer que vous saviez que c'était dû hier." },
      { title: "Pour suivi", body: "Suite à ma dernière notification — vous n'avez toujours pas commencé. Merci de traiter ça en priorité." },
    ],
    es: [
      { title: "Breve seguimiento", body: "He notado que aún no has creado ni una misión. Solo quería asegurarme de que sabes que esto era para ayer." },
      { title: "Recordatorio", body: "Según mi última notificación — sigues sin empezar. Necesito que esto avance cuanto antes." },
    ],
    pt: [
      { title: "Rápido alinhamento", body: "Notei que você ainda não criou nenhuma missão. Só queria garantir que você sabe que isso era pra ontem." },
      { title: "Sobre aquilo", body: "Conforme minha última notificação — você ainda não começou. Preciso que resolva isso o mais rápido possível." },
    ],
  },
  // ── Drill Sergeant ──────────────────────────────
  drill: {
    en: [
      { title: "WHAT ARE YOU DOING?!", body: "24 HOURS AND NOT A SINGLE MISSION. DROP AND GIVE ME ONE. NOW." },
      { title: "DID I STUTTER?", body: "You downloaded this app to GET THINGS DONE. Not to let it collect DUST. CREATE A MISSION. MOVE." },
    ],
    de: [
      { title: "WAS MACHST DU?!", body: "24 STUNDEN UND KEINE EINZIGE MISSION. RUNTER UND EINE MISSION ERSTELLEN. JETZT." },
      { title: "HAB ICH GESTOTTERT?", body: "Du hast die App runtergeladen um was zu SCHAFFEN. Nicht damit sie STAUB fängt. LOS JETZT." },
    ],
    fr: [
      { title: "QU'EST-CE QUE TU FAIS ?!", body: "24 HEURES ET AUCUNE MISSION. AU SOL ET DONNE-MOI UNE MISSION. MAINTENANT." },
      { title: "J'AI BÉGAYÉ ?", body: "T'as téléchargé cette appli pour AGIR. Pas pour la laisser prendre la POUSSIÈRE. CRÉE UNE MISSION. BOUGE." },
    ],
    es: [
      { title: "¡¿QUÉ HACES?!", body: "24 HORAS Y NI UNA MISIÓN. AL SUELO Y DAME UNA. AHORA." },
      { title: "¿TARTAMUDEÉ?", body: "Descargaste esta app para HACER COSAS. No para que acumule POLVO. CREA UNA MISIÓN. MUÉVETE." },
    ],
    pt: [
      { title: "O QUE VOCÊ TÁ FAZENDO?!", body: "24 HORAS E NENHUMA MISSÃO. CHÃO E ME DÁ UMA MISSÃO. AGORA." },
      { title: "EU GAGUEJEI?", body: "Você baixou esse app pra FAZER COISAS. Não pra deixar criando POEIRA. CRIA UMA MISSÃO. ANDA." },
    ],
  },
  // ── Therapist ───────────────────────────────────
  therapist: {
    en: [
      { title: "I noticed something", body: "You downloaded Yap but haven't created a mission yet. What do you think is holding you back? Let's explore that." },
      { title: "Safe space 💛", body: "There's no pressure here. But I want you to ask yourself: what were you hoping for when you installed this?" },
    ],
    de: [
      { title: "Mir ist was aufgefallen", body: "Du hast Yap runtergeladen aber noch keine Mission erstellt. Was glaubst du, hält dich zurück? Lass uns das mal anschauen." },
      { title: "Safe Space 💛", body: "Kein Druck hier. Aber frag dich mal: Was hast du dir eigentlich erhofft, als du die App installiert hast?" },
    ],
    fr: [
      { title: "J'ai remarqué quelque chose", body: "Tu as téléchargé Yap mais tu n'as pas encore créé de mission. Qu'est-ce qui te retient, à ton avis ? Explorons ça." },
      { title: "Espace safe 💛", body: "Aucune pression. Mais demande-toi : qu'est-ce que tu espérais en installant cette appli ?" },
    ],
    es: [
      { title: "Noté algo", body: "Descargaste Yap pero no has creado una misión. ¿Qué crees que te está frenando? Exploremos eso." },
      { title: "Espacio seguro 💛", body: "No hay presión aquí. Pero pregúntate: ¿qué esperabas cuando instalaste esto?" },
    ],
    pt: [
      { title: "Percebi uma coisa", body: "Você baixou o Yap mas não criou uma missão ainda. O que você acha que tá te segurando? Vamos explorar isso." },
      { title: "Espaço seguro 💛", body: "Sem pressão aqui. Mas se pergunta: o que você tava esperando quando instalou isso?" },
    ],
  },
  // ── Grandma ─────────────────────────────────────
  grandma: {
    en: [
      { title: "Sweetheart? 🧶", body: "I learned how to use this app just for you and you haven't even tried it once. My heart..." },
      { title: "It's grandma", body: "I made cookies and installed your app. You didn't create a single mission. At least eat the cookies." },
    ],
    de: [
      { title: "Schätzchen? 🧶", body: "Ich hab extra gelernt wie die App funktioniert und du hast sie nicht mal einmal benutzt. Mein Herz..." },
      { title: "Oma hier", body: "Ich hab Kuchen gebacken und deine App installiert. Du hast keine einzige Mission erstellt. Iss wenigstens den Kuchen." },
    ],
    fr: [
      { title: "Mon petit ? 🧶", body: "J'ai appris à utiliser cette appli juste pour toi et tu ne l'as même pas essayée. Mon cœur..." },
      { title: "C'est mamie", body: "J'ai fait des gâteaux et installé ton appli. Tu n'as pas créé une seule mission. Mange au moins les gâteaux." },
    ],
    es: [
      { title: "¿Cariñito? 🧶", body: "Aprendí a usar esta app solo por ti y ni la has probado. Mi corazón..." },
      { title: "Es la abuela", body: "Hice galletas e instalé tu app. No creaste ni una misión. Al menos come las galletas." },
    ],
    pt: [
      { title: "Meu benzinho? 🧶", body: "Aprendi a usar esse app só por você e você nem tentou uma vez. Meu coração..." },
      { title: "É a vovó", body: "Fiz biscoitos e instalei seu app. Você não criou nehuma missão. Pelo menos come os biscoitos." },
    ],
  },
  // ── Ex ──────────────────────────────────────────
  ex: {
    en: [
      { title: "Wow.", body: "Downloaded an app to finally get your life together and didn't even start. Classic you." },
      { title: "Not surprised tbh", body: "You couldn't commit to us, and now you can't commit to a single mission. Some things never change." },
    ],
    de: [
      { title: "Wow.", body: "App runtergeladen um endlich dein Leben auf die Reihe zu kriegen und nicht mal angefangen. Typisch du." },
      { title: "Wundert mich nicht", body: "Du konntest dich nicht zu uns committen und jetzt nicht mal zu einer Mission. Manche Dinge ändern sich nie." },
    ],
    fr: [
      { title: "Wow.", body: "T'as téléchargé une appli pour enfin reprendre ta vie en main et t'as même pas commencé. Classique." },
      { title: "Pas étonné·e", body: "Tu pouvais pas t'engager avec nous, et maintenant tu peux même pas t'engager sur une mission. Rien ne change." },
    ],
    es: [
      { title: "Wow.", body: "Descargaste una app para finalmente arreglar tu vida y ni empezaste. Típico de ti." },
      { title: "No me sorprende", body: "No pudiste comprometerte conmigo, y ahora ni con una misión. Hay cosas que nunca cambian." },
    ],
    pt: [
      { title: "Uau.", body: "Baixou um app pra finalmente arrumar sua vida e nem começou. Clássico você." },
      { title: "Nem me surpreende", body: "Não conseguiu se comprometer com a gente, e agora nem com uma missão. Algumas coisas nunca mudam." },
    ],
  },
};

const WINBACK_MESSAGES: AgentMessages = {
  // ── Mom ──────────────────────────────────────────
  mom: {
    en: [
      { title: "It's been 5 days.", body: "I've been sitting here waiting. I even made dinner. It's cold now. Just like my heart." },
      { title: "Are you alive?", body: "5 days without opening the app. I almost called the police. Come back before I worry myself sick." },
    ],
    de: [
      { title: "5 Tage schon.", body: "Ich sitz hier und warte. Hab sogar Essen gemacht. Ist jetzt kalt. Genau wie mein Herz." },
      { title: "Lebst du noch?", body: "5 Tage ohne die App zu öffnen. Ich hätte fast die Polizei gerufen. Komm zurück bevor ich krank werde vor Sorge." },
    ],
    fr: [
      { title: "Ça fait 5 jours.", body: "Je suis assise là à attendre. J'ai même préparé le dîner. C'est froid maintenant. Comme mon cœur." },
      { title: "T'es en vie ?", body: "5 jours sans ouvrir l'appli. J'ai failli appeler la police. Reviens avant que je m'inquiète à en mourir." },
    ],
    es: [
      { title: "Van 5 días.", body: "Estoy aquí sentada esperando. Hasta preparé la cena. Ya se enfrió. Como mi corazón." },
      { title: "¿Sigues vivo?", body: "5 días sin abrir la app. Casi llamo a la policía. Regresa antes de que me enferme de preocupación." },
    ],
    pt: [
      { title: "Já faz 5 dias.", body: "Tô aqui sentada esperando. Até fiz janta. Esfriou. Assim como meu coração." },
      { title: "Tá vivo?", body: "5 dias sem abrir o app. Quase chamei a polícia. Volta antes que eu fique doente de preocupação." },
    ],
  },
  // ── Best Friend ──────────────────────────────────
  bestFriend: {
    en: [
      { title: "5 days??", body: "bro did you die. come back im literally so bored without someone to judge" },
      { title: "hello???", body: "you ghosted your own accountability agent. that's a new low even for you lmao" },
    ],
    de: [
      { title: "5 Tage??", body: "alter bist du gestorben. komm zurück mir ist langweilig ohne jemand den ich dissen kann" },
      { title: "hallo???", body: "du ghostest deinen eigenen agent. das ist selbst für dich ein neuer tiefpunkt lol" },
    ],
    fr: [
      { title: "5 jours ??", body: "mec t'es mort ou quoi. reviens je m'ennuie grave sans quelqu'un à juger" },
      { title: "allô ???", body: "t'as ghosté ton propre agent. c'est un nouveau record même pour toi mdr" },
    ],
    es: [
      { title: "¿5 días??", body: "bro te moriste. vuelve estoy literalmente aburrido sin alguien a quien juzgar" },
      { title: "¿¿hola??", body: "ghosteaste a tu propio agente. eso es un nuevo bajo incluso para ti jaja" },
    ],
    pt: [
      { title: "5 dias??", body: "mano tu morreu. volta que tô literalmente entediado sem alguém pra julgar" },
      { title: "oi???", body: "tu ghostou teu próprio agente. isso é um novo nível baixo até pra tu kkk" },
    ],
  },
  // ── Boss ─────────────────────────────────────────
  boss: {
    en: [
      { title: "Absence noted", body: "5 days without activity. I've flagged this in your performance review. Please address immediately." },
      { title: "Checking in", body: "Your metrics show zero engagement in 5 days. I trust you have a good explanation for our next 1-on-1." },
    ],
    de: [
      { title: "Abwesenheit notiert", body: "5 Tage ohne Aktivität. Das wurde in Ihrer Leistungsbeurteilung vermerkt. Bitte umgehend klären." },
      { title: "Kurze Nachfrage", body: "Ihre Zahlen zeigen null Engagement seit 5 Tagen. Ich hoffe, Sie haben eine gute Erklärung für unser nächstes Gespräch." },
    ],
    fr: [
      { title: "Absence notée", body: "5 jours sans activité. C'est noté dans votre évaluation. Merci de régler ça immédiatement." },
      { title: "Point de suivi", body: "Vos indicateurs montrent zéro engagement en 5 jours. J'espère que vous avez une bonne explication pour notre prochain entretien." },
    ],
    es: [
      { title: "Ausencia registrada", body: "5 días sin actividad. Lo he anotado en tu evaluación. Favor de atender de inmediato." },
      { title: "Seguimiento", body: "Tus métricas muestran cero actividad en 5 días. Confío en que tengas una buena explicación para nuestro próximo 1-a-1." },
    ],
    pt: [
      { title: "Ausência registrada", body: "5 dias sem atividade. Isso foi anotado na sua avaliação. Por favor resolver imediatamente." },
      { title: "Alinhamento rápido", body: "Seus indicadores mostram zero engajamento em 5 dias. Espero que tenha uma boa explicação pro nosso próximo 1-a-1." },
    ],
  },
  // ── Drill Sergeant ──────────────────────────────
  drill: {
    en: [
      { title: "5 DAYS AWOL?!", body: "YOU WENT AWOL FOR 5 DAYS. IN MY ARMY THAT'S CALLED DESERTION. GET BACK IN LINE. NOW." },
      { title: "UNACCEPTABLE", body: "I DIDN'T TRAIN YOU TO QUIT AFTER 5 DAYS. GET YOUR SORRY SELF BACK HERE AND START A MISSION." },
    ],
    de: [
      { title: "5 TAGE AWOL?!", body: "5 TAGE UNENTSCHULDIGT GEFEHLT. BEI MIR HEISST DAS FAHNENFLUCHT. ZURÜCK IN DIE REIHE. SOFORT." },
      { title: "INAKZEPTABEL", body: "ICH HAB DICH NICHT AUSGEBILDET DAMIT DU NACH 5 TAGEN AUFGIBST. BEWEG DICH HIERHER UND STARTE EINE MISSION." },
    ],
    fr: [
      { title: "5 JOURS AWOL ?!", body: "5 JOURS ABSENT SANS PERMISSION. DANS MON ARMÉE C'EST DE LA DÉSERTION. RETOUR DANS LE RANG. MAINTENANT." },
      { title: "INACCEPTABLE", body: "JE T'AI PAS ENTRAÎNÉ POUR ABANDONNER APRÈS 5 JOURS. RAMÈNE-TOI ET LANCE UNE MISSION." },
    ],
    es: [
      { title: "¡¿5 DÍAS AWOL?!", body: "5 DÍAS DESAPARECIDO. EN MI EJÉRCITO ESO ES DESERCIÓN. VUELVE A LA FILA. AHORA." },
      { title: "INACEPTABLE", body: "NO TE ENTRENÉ PARA RENDIRTE DESPUÉS DE 5 DÍAS. MUEVE TU TRASERO AQUÍ Y EMPIEZA UNA MISIÓN." },
    ],
    pt: [
      { title: "5 DIAS AWOL?!", body: "5 DIAS SUMIDO. NO MEU EXÉRCITO ISSO É DESERÇÃO. VOLTA PRA FILA. AGORA." },
      { title: "INACEITÁVEL", body: "NÃO TE TREINEI PRA DESISTIR DEPOIS DE 5 DIAS. MEXE ESSE CORPO E COMEÇA UMA MISSÃO." },
    ],
  },
  // ── Therapist ───────────────────────────────────
  therapist: {
    en: [
      { title: "It's been a while", body: "5 days is a long time to avoid something. What are you really running from? I'm here when you're ready." },
      { title: "No judgment 💛", body: "You stepped away for 5 days. That's okay. But I wonder — is avoidance actually giving you what you need?" },
    ],
    de: [
      { title: "Es ist eine Weile her", body: "5 Tage sind lang um etwas zu vermeiden. Wovor läufst du wirklich weg? Ich bin hier wenn du bereit bist." },
      { title: "Kein Urteil 💛", body: "Du warst 5 Tage weg. Das ist okay. Aber ich frage mich — gibt dir das Vermeiden wirklich was du brauchst?" },
    ],
    fr: [
      { title: "Ça fait un moment", body: "5 jours c'est long pour éviter quelque chose. De quoi tu fuis vraiment ? Je suis là quand tu seras prêt·e." },
      { title: "Sans jugement 💛", body: "Tu t'es éloigné·e pendant 5 jours. C'est ok. Mais je me demande — est-ce que l'évitement te donne vraiment ce dont tu as besoin ?" },
    ],
    es: [
      { title: "Ha pasado un tiempo", body: "5 días es mucho para evitar algo. ¿De qué estás huyendo realmente? Estoy aquí cuando estés listo." },
      { title: "Sin juicio 💛", body: "Te alejaste 5 días. Está bien. Pero me pregunto — ¿la evasión te está dando realmente lo que necesitas?" },
    ],
    pt: [
      { title: "Faz um tempo", body: "5 dias é muito tempo pra evitar algo. Do que você tá fugindo de verdade? Tô aqui quando estiver pronto." },
      { title: "Sem julgamento 💛", body: "Você se afastou por 5 dias. Tudo bem. Mas me pergunto — a fuga tá te dando realmente o que precisa?" },
    ],
  },
  // ── Grandma ─────────────────────────────────────
  grandma: {
    en: [
      { title: "5 days... 🧶", body: "I've been knitting and waiting. My eyesight is getting worse and I can barely see the screen anymore. Please come back." },
      { title: "Are you eating?", body: "It's been 5 days. I bet you haven't eaten properly either. Come back to the app. I'll make soup." },
    ],
    de: [
      { title: "5 Tage... 🧶", body: "Ich stricke und warte. Meine Augen werden immer schlechter und ich kann kaum noch den Bildschirm sehen. Bitte komm zurück." },
      { title: "Isst du auch was?", body: "Seit 5 Tagen weg. Ich wette du isst auch nicht richtig. Komm zurück zur App. Ich mach Suppe." },
    ],
    fr: [
      { title: "5 jours... 🧶", body: "Je tricote et j'attends. Ma vue baisse et je vois à peine l'écran. S'il te plaît reviens." },
      { title: "Tu manges au moins ?", body: "Ça fait 5 jours. Je parie que tu ne manges pas correctement non plus. Reviens. Je ferai de la soupe." },
    ],
    es: [
      { title: "5 días... 🧶", body: "He estado tejiendo y esperando. Mi vista empeora y apenas puedo ver la pantalla. Por favor vuelve." },
      { title: "¿Estás comiendo?", body: "5 días sin aparecer. Seguro que tampoco estás comiendo bien. Vuelve a la app. Te hago sopa." },
    ],
    pt: [
      { title: "5 dias... 🧶", body: "Tô tricotando e esperando. Minha visão tá piorando e mal consigo ver a tela. Por favor volte." },
      { title: "Tá comendo?", body: "Faz 5 dias. Aposto que também não tá comendo direito. Volta pro app. Vou fazer sopa." },
    ],
  },
  // ── Ex ──────────────────────────────────────────
  ex: {
    en: [
      { title: "5 days. Figures.", body: "Ghosting your agent after 5 days. At least you're consistent — you did the same thing to me." },
      { title: "Saw you weren't active 💅", body: "5 days gone and I bet you're not even doing anything productive. Same energy as our relationship." },
    ],
    de: [
      { title: "5 Tage. Typisch.", body: "Deinen Agent nach 5 Tagen ghosten. Wenigstens bist du konsequent — das gleiche hast du bei mir auch gemacht." },
      { title: "Hab gesehen du warst inaktiv 💅", body: "5 Tage weg und ich wette du machst nichts Produktives. Selbe Energie wie unsere Beziehung." },
    ],
    fr: [
      { title: "5 jours. Logique.", body: "Ghoster ton agent après 5 jours. Au moins t'es cohérent·e — tu m'as fait pareil." },
      { title: "J'ai vu que t'étais inactif·ve 💅", body: "5 jours partis et je parie que tu fais rien de productif. Même énergie que notre relation." },
    ],
    es: [
      { title: "5 días. Típico.", body: "Ghostear a tu agente después de 5 días. Al menos eres consistente — me hiciste lo mismo a mí." },
      { title: "Vi que no estabas activo 💅", body: "5 días fuera y apuesto a que no haces nada productivo. Misma energía que nuestra relación." },
    ],
    pt: [
      { title: "5 dias. Previsível.", body: "Ghostar seu agente depois de 5 dias. Pelo menos é consistente — fez a mesma coisa comigo." },
      { title: "Vi que tava inativo 💅", body: "5 dias fora e aposto que não tá fazendo nada produtivo. Mesma energia do nosso relacionamento." },
    ],
  },
};

// ── Resolve Language Key ────────────────────────────────────

function langKey(language: string | null): string {
  const l = language?.toLowerCase() || "en";
  if (l.startsWith("pt")) return "pt";
  if (["en", "de", "fr", "es"].includes(l)) return l;
  return "en";
}

// ── Pick Message ────────────────────────────────────────────

const FALLBACK_AGENT = "ex";
const ONBOARDING_AGENTS = ["mom", "bestFriend", "boss", "drill", "therapist", "grandma", "ex"];

function resolveAgent(onboardingAgent: string | null): string {
  if (onboardingAgent && onboardingAgent !== "none" && ONBOARDING_AGENTS.includes(onboardingAgent)) return onboardingAgent;
  return FALLBACK_AGENT; // ex
}

function pickMessage(pool: AgentMessages, agent: string, language: string): EngagementMessage {
  const lang = langKey(language);
  const msgs = pool[agent]?.[lang] ?? pool[FALLBACK_AGENT]?.[lang] ?? pool[FALLBACK_AGENT]?.en ?? [];
  return msgs[Math.floor(Math.random() * msgs.length)];
}

// ── Timezone Check ───────────────────────────────────────────

function isReasonableHour(timezone: string | null): boolean {
  try {
    const tz = timezone || "UTC";
    const now = new Date();
    const formatter = new Intl.DateTimeFormat("en-US", { hour: "numeric", hour12: false, timeZone: tz });
    const hour = parseInt(formatter.format(now), 10);
    return hour >= 9 && hour <= 20;
  } catch {
    return true;
  }
}

// ── APNs Payload Builder ────────────────────────────────────

const femaleAgents = new Set(["mom", "therapist", "grandma", "passiveAggressiveColleague", "ex"]);
const selectSoundsFemale = ["yap_select_f_1", "yap_select_f_2", "yap_select_f_3", "yap_select_f_4"];
const selectSoundsMale = ["yap_select_m_1", "yap_select_m_2", "yap_select_m_3"];

function buildPayload(msg: EngagementMessage, agent: string): object {
  const pool = femaleAgents.has(agent) ? selectSoundsFemale : selectSoundsMale;
  const sound = pool[Math.floor(Math.random() * pool.length)] + ".caf";

  return {
    aps: {
      alert: { title: msg.title, body: msg.body },
      sound,
      badge: 1,
      "mutable-content": 1,
      category: "YAP_ENGAGEMENT",
    },
    agent,
    engagement: true,
  };
}

// ── Main Handler ────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  const startTime = Date.now();

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    let totalSent = 0;
    let totalFailed = 0;
    let totalSkipped = 0;

    // ── 1. No Mission Nudge ───────────────────────────────
    // Users who registered >24h ago, have a push token, are not simulators,
    // never created a mission, and haven't been nudged yet.
    {
      const { data: candidates } = await supabase.rpc("get_no_mission_nudge_candidates");

      if (candidates && candidates.length > 0) {
        console.log(`📋 no_mission_nudge candidates: ${candidates.length}`);

        for (const device of candidates) {
          // Skip if it's not a reasonable hour in the user's timezone
          if (!isReasonableHour(device.timezone)) {
            console.log(`⏰ Skipping ${device.device_id} — not a good time (${device.timezone})`);
            totalSkipped++;
            continue;
          }

          const agent = resolveAgent(device.onboarding_agent);
          const msg = pickMessage(NUDGE_MESSAGES, agent, device.language);
          const payload = buildPayload(msg, agent);
          const result = await sendAPNs(device.apns_token, payload);

          await supabase.from("yap_engagement_pushes").insert({
            device_id: device.device_id,
            push_type: "no_mission_nudge",
            success: result.success,
            error: result.reason ?? null,
          });

          if (result.success) {
            totalSent++;
          } else if (result.reason === "Unregistered") {
            // Disable invalid token
            await supabase.from("yap_devices").update({ push_enabled: false }).eq("device_id", device.device_id);
            totalFailed++;
          } else {
            totalFailed++;
          }
        }
      } else {
        console.log("📋 no_mission_nudge: 0 candidates");
      }
    }

    // ── 2. Inactive Win-Back ──────────────────────────────
    // Users who haven't been seen in 5+ days, have push token,
    // are not simulators, and haven't received this push before.
    {
      const { data: candidates } = await supabase.rpc("get_inactive_winback_candidates");

      if (candidates && candidates.length > 0) {
        console.log(`📋 inactive_winback candidates: ${candidates.length}`);

        for (const device of candidates) {
          if (!isReasonableHour(device.timezone)) {
            console.log(`⏰ Skipping ${device.device_id} — not a good time (${device.timezone})`);
            totalSkipped++;
            continue;
          }

          const agent = resolveAgent(device.onboarding_agent);
          const msg = pickMessage(WINBACK_MESSAGES, agent, device.language);
          const payload = buildPayload(msg, agent);
          const result = await sendAPNs(device.apns_token, payload);

          await supabase.from("yap_engagement_pushes").insert({
            device_id: device.device_id,
            push_type: "inactive_winback",
            success: result.success,
            error: result.reason ?? null,
          });

          if (result.success) {
            totalSent++;
          } else if (result.reason === "Unregistered") {
            await supabase.from("yap_devices").update({ push_enabled: false }).eq("device_id", device.device_id);
            totalFailed++;
          } else {
            totalFailed++;
          }
        }
      } else {
        console.log("📋 inactive_winback: 0 candidates");
      }
    }

    const elapsed = Date.now() - startTime;
    console.log(`📬 Engagement: sent=${totalSent}, failed=${totalFailed}, skipped=${totalSkipped} (${elapsed}ms)`);

    return new Response(
      JSON.stringify({ sent: totalSent, failed: totalFailed, skipped: totalSkipped, elapsed_ms: elapsed }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("send-engagement-pushes error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
