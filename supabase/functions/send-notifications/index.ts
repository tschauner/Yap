// Supabase Edge Function: send-notifications
// Triggered by pg_cron every minute via pg_net
// Sends pending notifications via APNs HTTP/2
//
// Deploy: supabase functions deploy send-notifications
// Secrets needed:
//   APNS_KEY_ID      — Apple Key ID (10 chars)
//   APNS_TEAM_ID     — Apple Team ID (98QF3H5LV4)
//   APNS_PRIVATE_KEY — Contents of .p8 file
//   SUPABASE_SERVICE_ROLE_KEY — (auto-set by Supabase)

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
const BATCH_SIZE = 100;

// ── APNs JWT Token ──────────────────────────────────────────

let cachedJWT: { token: string; expiresAt: number } | null = null;

async function getAPNsJWT(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Cache JWT for 50 minutes (valid for 60)
  if (cachedJWT && cachedJWT.expiresAt > now) {
    return cachedJWT.token;
  }

  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }))
  );
  const claims = base64url(
    new TextEncoder().encode(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }))
  );
  const signingInput = `${header}.${claims}`;

  // Import .p8 private key
  const pemContents = APNS_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput)
  );

  // Convert DER signature to raw r||s format if needed
  const sigBytes = new Uint8Array(signature);
  let rawSig: Uint8Array;

  if (sigBytes[0] === 0x30) {
    // DER encoded — extract r and s
    const rLen = sigBytes[3];
    const rStart = 4;
    const rEnd = rStart + rLen;
    const sLen = sigBytes[rEnd + 1];
    const sStart = rEnd + 2;

    let r = sigBytes.slice(rStart, rEnd);
    let s = sigBytes.slice(sStart, sStart + sLen);

    // Remove leading zeros and pad to 32 bytes
    if (r.length > 32) r = r.slice(r.length - 32);
    if (s.length > 32) s = s.slice(s.length - 32);

    rawSig = new Uint8Array(64);
    rawSig.set(r, 32 - r.length);
    rawSig.set(s, 64 - s.length);
  } else {
    rawSig = sigBytes;
  }

  const token = `${signingInput}.${base64url(rawSig)}`;
  cachedJWT = { token, expiresAt: now + 3000 }; // 50 min
  return token;
}

// ── APNs Send ───────────────────────────────────────────────

interface APNsResult {
  success: boolean;
  statusCode: number;
  apnsId?: string;
  reason?: string;
}

async function sendAPNs(
  token: string,
  payload: object,
  environment: string = "production"
): Promise<APNsResult> {
  const host = environment === "sandbox" ? APNS_SANDBOX_HOST : APNS_HOST;
  const jwt = await getAPNsJWT();

  try {
    const response = await fetch(`${host}/3/device/${token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
      },
      body: JSON.stringify(payload),
    });

    const apnsId = response.headers.get("apns-id") ?? undefined;

    if (response.ok) {
      return { success: true, statusCode: 200, apnsId };
    }

    const errorBody = await response.json().catch(() => ({}));
    return {
      success: false,
      statusCode: response.status,
      apnsId,
      reason: errorBody.reason ?? `HTTP ${response.status}`,
    };
  } catch (err) {
    return { success: false, statusCode: 0, reason: err.message };
  }
}

// ── Escalation Sound + Priority ─────────────────────────────

function apnsPayload(
  title: string,
  body: string,
  level: number,
  goalId: string,
  badge: number,
  agent: string
): object {
  const isCritical = level >= 2; // push, urgent, meltdown
  const isTimeSensitive = level >= 3; // urgent, meltdown

  return {
    aps: {
      alert: { title, body },
      sound: isCritical ? "default" : "default",
      badge,
      "mutable-content": 1, // Triggers Notification Service Extension for avatar
      category: "YAP_REMINDER",
      "thread-id": goalId,
      ...(isTimeSensitive && { "interruption-level": "time-sensitive" }),
    },
    goalId,
    level,
    agent, // Agent rawValue — used by extension to pick avatar + display name
  };
}

// ── Main Handler ────────────────────────────────────────────

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

  const startTime = Date.now();

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch pending notifications that are due — only for active goals
    //    (prevents sending after mission is completed/given up)
    const { data: notifications, error: fetchError } = await supabase
      .from("yap_notifications")
      .select(`
        id, goal_id, device_id, agent, title, body,
        escalation_level, sequence_index, scheduled_at,
        yap_goals!inner ( status, deadline, notifications_sent )
      `)
      .eq("status", "pending")
      .eq("yap_goals.status", "active")
      .lte("scheduled_at", new Date().toISOString())
      .order("scheduled_at", { ascending: true })
      .limit(BATCH_SIZE);

    if (fetchError) {
      console.error("Fetch error:", fetchError);
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!notifications || notifications.length === 0) {
      return new Response(JSON.stringify({ sent: 0, skipped: 0, failed: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1b. Mark expired active missions as given_up
    const { data: expiredGoals } = await supabase
      .from("yap_goals")
      .update({
        status: "given_up",
        given_up_at: new Date().toISOString(),
      })
      .eq("status", "active")
      .lt("deadline", new Date().toISOString())
      .select("id");

    if (expiredGoals && expiredGoals.length > 0) {
      const expiredIds = expiredGoals.map((g: { id: string }) => g.id);
      console.log(`⏰ Expired ${expiredIds.length} missions: ${expiredIds.join(", ")}`);

      // Cancel their pending notifications
      await supabase
        .from("yap_notifications")
        .update({ status: "cancelled", error: "mission_expired" })
        .in("goal_id", expiredIds)
        .eq("status", "pending");
    }

    // 2. Get unique device IDs and fetch their tokens + settings
    const deviceIds = [...new Set(notifications.map((n) => n.device_id))];
    const { data: devices, error: deviceError } = await supabase
      .from("yap_devices")
      .select("device_id, apns_token, push_enabled")
      .in("device_id", deviceIds);

    if (deviceError) {
      console.error("Device fetch error:", deviceError);
      return new Response(JSON.stringify({ error: deviceError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const deviceMap = new Map(devices?.map((d) => [d.device_id, d]) ?? []);

    // 3. Process each notification
    let sent = 0;
    let skipped = 0;
    let failed = 0;
    const updates: { id: string; status: string; sent_at?: string; apns_id?: string; error?: string }[] = [];
    const disabledDevices: string[] = [];
    const goalSentCounts = new Map<string, number>();

    for (const notif of notifications) {
      const device = deviceMap.get(notif.device_id);

      // No device registered or no token
      if (!device || !device.apns_token) {
        updates.push({ id: notif.id, status: "failed", error: "no_device_token" });
        failed++;
        continue;
      }

      // Push disabled
      if (!device.push_enabled) {
        updates.push({ id: notif.id, status: "cancelled", error: "push_disabled" });
        skipped++;
        continue;
      }

      // Build and send
      // Badge shows total messages sent for this mission (including this one)
      const currentBadge = (notif.yap_goals?.notifications_sent ?? 0) + 1;
      const payload = apnsPayload(
        notif.title,
        notif.body,
        notif.escalation_level,
        notif.goal_id,
        currentBadge,
        notif.agent
      );

      const result = await sendAPNs(device.apns_token, payload, APNS_ENVIRONMENT);

      if (result.success) {
        updates.push({
          id: notif.id,
          status: "sent",
          sent_at: new Date().toISOString(),
          apns_id: result.apnsId,
        });
        sent++;

        // Track sent count per goal
        goalSentCounts.set(notif.goal_id, (goalSentCounts.get(notif.goal_id) ?? 0) + 1);
      } else if (result.statusCode === 410 || result.reason === "Unregistered") {
        // Token expired/invalid — disable device
        updates.push({ id: notif.id, status: "failed", error: "token_invalid" });
        disabledDevices.push(notif.device_id);
        failed++;
      } else {
        updates.push({
          id: notif.id,
          status: "failed",
          error: result.reason ?? `status_${result.statusCode}`,
        });
        failed++;
      }
    }

    // 4. Batch update notification statuses
    for (const update of updates) {
      await supabase
        .from("yap_notifications")
        .update({
          status: update.status,
          ...(update.sent_at && { sent_at: update.sent_at }),
          ...(update.apns_id && { apns_id: update.apns_id }),
          ...(update.error && { error: update.error }),
        })
        .eq("id", update.id);
    }

    // 5. Update notifications_sent on yap_goals
    for (const [goalId, count] of goalSentCounts) {
      await supabase.rpc("increment_notifications_sent", {
        p_goal_id: goalId,
        p_count: count,
      });
    }

    // 6. Disable devices with invalid tokens
    for (const deviceId of disabledDevices) {
      await supabase
        .from("yap_devices")
        .update({ push_enabled: false })
        .eq("device_id", deviceId);
    }

    const elapsed = Date.now() - startTime;
    console.log(`📬 Sent: ${sent}, Skipped: ${skipped}, Failed: ${failed} (${elapsed}ms)`);

    return new Response(
      JSON.stringify({ sent, skipped, failed, elapsed_ms: elapsed }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("send-notifications error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
