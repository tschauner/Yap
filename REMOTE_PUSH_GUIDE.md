# Yap Remote Push Notifications — Architecture & Implementation Guide

> **Status:** Planned
> **Author:** GitHub Copilot + Philipp
> **Date:** March 15, 2026
> **Estimated effort:** 1–2 days

---

## Overview

Migrate Yap from **local notifications** (`UNTimeIntervalNotificationTrigger`) to **server-driven remote push notifications** via APNs. This unlocks unlimited parallel missions, dynamic escalation, real-time Agent Memory, and re-engagement pushes — like Duolingo.

### Why

| Problem (local) | Solution (remote) |
|---|---|
| iOS limit: 64 pending notifications → max ~2 missions | Unlimited parallel missions |
| All 24 messages pre-scheduled at creation, can't adapt | Dynamic: server decides per-message |
| Agent Memory only used at generation time | Live: reference what happened since last notification |
| Quiet hours changes require re-scheduling | Server checks before sending |
| App-kill/reboot can lose scheduled notifications | Server-driven, always reliable |
| No re-engagement pushes possible | "Your streak is dying" — trivial |
| No A/B testing | Server can test escalation strategies |

### Architecture

```
┌──────────────────────────────────────────────────┐
│  pg_cron (every 1 min)                           │
│  → SELECT net.http_post() to send-notifications  │
└────────────────────────┬─────────────────────────┘
                         │ HTTP trigger
                         ▼
┌──────────────────────────────────────────────────┐
│  Edge Function: send-notifications               │
│  1. Query yap_notifications                      │
│     WHERE scheduled_at <= now()                  │
│     AND status = 'pending'                       │
│  2. JOIN yap_devices for APNs token + quiet hrs  │
│  3. Skip if quiet hours active                   │
│  4. Send via APNs (HTTP/2 + JWT)                 │
│  5. Mark as 'sent' or 'failed'                   │
│  6. Update yap_goals.notifications_sent          │
└──────────────────────────┬───────────────────────┘
                           │ APNs (HTTP/2)
                           ▼
┌──────────────────────────────────────────────────┐
│  Apple Push Notification Service → iOS Device    │
└──────────────────────────────────────────────────┘
```

---

## Database Schema

### New table: `yap_devices`

Stores APNs tokens and device preferences. One row per device.

```sql
CREATE TABLE yap_devices (
    device_id           TEXT PRIMARY KEY,
    apns_token          TEXT,                      -- APNs device token (hex string)
    apns_environment    TEXT DEFAULT 'production', -- 'sandbox' or 'production'
    timezone            TEXT DEFAULT 'UTC',         -- IANA timezone (e.g. 'Europe/Berlin')
    quiet_hours_start   INT DEFAULT 22,            -- Hour (0-23), local time
    quiet_hours_end     INT DEFAULT 8,             -- Hour (0-23), local time
    language            TEXT DEFAULT 'en',          -- ISO language code
    push_enabled        BOOLEAN DEFAULT true,       -- User can disable pushes
    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE yap_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_own" ON yap_devices FOR ALL
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');
```

### New table: `yap_notifications`

Pre-generated notification messages, scheduled for delivery.

```sql
CREATE TABLE yap_notifications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id             UUID NOT NULL REFERENCES yap_goals(id) ON DELETE CASCADE,
    device_id           TEXT NOT NULL,
    agent               TEXT NOT NULL,
    title               TEXT NOT NULL,              -- Notification title (max 40 chars)
    body                TEXT NOT NULL,              -- Notification body (max 120 chars)
    escalation_level    INT NOT NULL DEFAULT 0,     -- 0=gentle, 1=nudge, 2=push, 3=urgent, 4=meltdown
    sequence_index      INT NOT NULL DEFAULT 0,     -- Order within the mission (0-23)
    scheduled_at        TIMESTAMPTZ NOT NULL,       -- When to send
    sent_at             TIMESTAMPTZ,                -- When actually sent (NULL = not yet)
    status              TEXT NOT NULL DEFAULT 'pending', -- pending, sent, failed, cancelled
    apns_id             TEXT,                       -- APNs response ID for tracking
    error               TEXT,                       -- Error message if failed
    created_at          TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notif_pending ON yap_notifications(status, scheduled_at)
    WHERE status = 'pending';
CREATE INDEX idx_notif_goal ON yap_notifications(goal_id);
CREATE INDEX idx_notif_device ON yap_notifications(device_id);

ALTER TABLE yap_notifications ENABLE ROW LEVEL SECURITY;

-- Edge Functions need service_role key to read all pending notifications
-- Client only sees own notifications
CREATE POLICY "device_select_own" ON yap_notifications FOR SELECT
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');
```

### pg_cron job

```sql
-- Requires pg_cron and pg_net extensions (both available on Supabase Pro)
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Fire every minute
SELECT cron.schedule(
    'send-yap-notifications',
    '* * * * *',
    $$
    SELECT net.http_post(
        url := 'https://dbxpzxtxhcxbsbkcpuak.supabase.co/functions/v1/send-notifications',
        headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
            'Content-Type', 'application/json'
        ),
        body := '{}'::jsonb
    );
    $$
);
```

---

## Edge Function: `send-notifications`

**Trigger:** pg_cron every minute via pg_net HTTP POST
**Auth:** service_role key (bypasses RLS)
**Runtime:** Deno (Supabase Edge Functions)

### Flow

```
1. Query yap_notifications WHERE status = 'pending' AND scheduled_at <= now()
   LIMIT 100 (batch size, process more on next cron tick)
2. JOIN yap_devices ON device_id to get apns_token, timezone, quiet hours
3. For each notification:
   a. Check quiet hours (using device timezone) → skip if quiet, DON'T mark as sent
   b. Check push_enabled → skip if false
   c. Send to APNs via HTTP/2
   d. On success: status = 'sent', sent_at = now()
   e. On 410 Gone (invalid token): mark device push_enabled = false
   f. On other error: status = 'failed', error = message
4. Batch-update yap_goals.notifications_sent for affected goals
```

### APNs Integration (HTTP/2 + JWT)

No FCM needed. Direct APNs via HTTP/2:

```typescript
// APNs JWT auth using .p8 key
// Key stored in Supabase Secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY

const APNS_HOST = "https://api.push.apple.com"; // production
// const APNS_HOST = "https://api.sandbox.push.apple.com"; // sandbox

// JWT token (valid for 1 hour, cache and rotate)
function createAPNsJWT(): string {
    // Header: { alg: "ES256", kid: APNS_KEY_ID }
    // Payload: { iss: APNS_TEAM_ID, iat: now }
    // Sign with APNS_PRIVATE_KEY (.p8)
}

// Send single notification
async function sendAPNs(token: string, payload: object): Promise<boolean> {
    const response = await fetch(`${APNS_HOST}/3/device/${token}`, {
        method: "POST",
        headers: {
            "authorization": `bearer ${createAPNsJWT()}`,
            "apns-topic": "com.phitsch.Yap",
            "apns-push-type": "alert",
            "apns-priority": "10",
            "apns-expiration": "0",
        },
        body: JSON.stringify(payload),
    });
    return response.ok; // 200 = success, 410 = invalid token
}

// APNs payload format
const payload = {
    aps: {
        alert: { title: "You're stalling.", body: "The dishes aren't going to wash themselves." },
        sound: "default",              // or "critical" for urgent+
        badge: 3,                      // escalation level + 1
        "category": "YAP_REMINDER",    // for notification actions (Done ✅, Snooze 🤫)
        "thread-id": goalId,           // group by mission
        "interruption-level": "time-sensitive", // for urgent/meltdown
    },
    goalId: "...",
    level: 3,
};
```

### Secrets needed

```bash
supabase secrets set APNS_KEY_ID=ABC123DEFG
supabase secrets set APNS_TEAM_ID=98QF3H5LV4
supabase secrets set APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGT..."
```

---

## Updated Edge Function: `generate-copy`

Currently returns `{ messages[], reaction }` to the iOS client. Change: **also write messages to `yap_notifications`**.

### New flow

```
1. iOS calls generate-copy with goal, agent, language, schedule, etc. (same as now)
2. GPT-4o-mini generates messages + reaction (same as now)
3. NEW: Write each message as a row in yap_notifications:
   - goal_id, device_id (from x-device-id header)
   - title, body, escalation_level from GPT response
   - scheduled_at = mission.created_at + minuteOffset (from schedule)
   - status = 'pending'
4. Return response to iOS client (same as now, for reaction display)
```

### What changes in the function

```typescript
// After generating messages, insert into yap_notifications
const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const deviceId = req.headers.get("x-device-id");
const notifications = sanitized.map((msg, i) => ({
    goal_id: goalId,        // NEW: iOS must send goalId
    device_id: deviceId,
    agent: tone,
    title: msg.title,
    body: msg.body,
    escalation_level: msg.level,
    sequence_index: i,
    scheduled_at: new Date(missionCreatedAt + scheduleOffsets[i] * 60000).toISOString(),
    status: 'pending',
}));

await supabase.from('yap_notifications').insert(notifications);
```

---

## iOS Changes

### 1. APNs Token Registration

**File: `AppDelegate.swift`**

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    registerNotificationActions()
    application.registerForRemoteNotifications() // NEW
    return true
}

// NEW: Receive APNs token
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    Task {
        await DeviceService.shared.registerToken(token)
    }
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("⚠️ APNs registration failed: \(error.localizedDescription)")
}
```

### 2. New: `DeviceService.swift`

```swift
actor DeviceService {
    static let shared = DeviceService()
    private let api = APIClient()

    func registerToken(_ apnsToken: String) async {
        do {
            try await api.restInsert(
                table: "yap_devices",
                body: .json([
                    "device_id": APIClient.deviceId,
                    "apns_token": apnsToken,
                    "timezone": TimeZone.current.identifier,
                    "language": LanguageResolver.currentBackendLang(),
                    "quiet_hours_start": UserDefaults.standard.integer(forKey: QuietHours.startKey),
                    "quiet_hours_end": UserDefaults.standard.integer(forKey: QuietHours.endKey),
                ]),
                extraHeaders: ["Prefer": "resolution=merge-duplicates"] // upsert
            )
        } catch {
            print("⚠️ Device registration failed: \(error)")
        }
    }

    func syncQuietHours(start: Int, end: Int) async {
        try? await api.restUpdate(
            table: "yap_devices",
            query: "device_id=eq.\(APIClient.deviceId)",
            body: .json(["quiet_hours_start": start, "quiet_hours_end": end])
        )
    }

    func syncTimezone() async {
        try? await api.restUpdate(
            table: "yap_devices",
            query: "device_id=eq.\(APIClient.deviceId)",
            body: .json(["timezone": TimeZone.current.identifier])
        )
    }
}
```

### 3. Refactor `NagService`

**Before:** Schedules local `UNTimeIntervalNotificationTrigger` notifications.
**After:** Becomes a thin permission handler. Scheduling happens server-side.

```swift
actor NagService: NagProviding {
    static let shared = NagService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        if granted == true {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted ?? false
    }

    // Schedule is now handled by generate-copy writing to yap_notifications
    // This method just returns the count for display purposes
    func scheduleEscalation(for mission: Mission, startDelay: Int = 0) -> Int {
        let minutesUntilDeadline = max(0, Int(mission.deadline.timeIntervalSinceNow / 60))
        let schedule = EscalationLevel.buildSchedule(
            profile: mission.agent.escalationProfile,
            startOffsetMinutes: startDelay,
            availableMinutes: minutesUntilDeadline
        )
        return min(schedule.count, 24)
    }

    // Cancel = mark pending notifications as cancelled in DB
    func cancelNotifications(for goalId: UUID) {
        Task {
            try? await APIClient().restUpdate(
                table: "yap_notifications",
                query: "goal_id=eq.\(goalId.uuidString)&status=eq.pending",
                body: .json(["status": "cancelled"])
            )
        }
    }

    func missionCompleted(_ missionId: UUID) {
        cancelNotifications(for: missionId)
        clearBadge()
    }
}
```

### 4. Update `CopyService`

The `generate-copy` edge function now needs `goalId` and `missionCreatedAt` to compute `scheduled_at` timestamps.

```swift
// In requestBody(for:) — add these fields:
body["goalId"] = mission.id.uuidString
body["missionCreatedAt"] = ISO8601DateFormatter().string(from: mission.createdAt)
body["scheduleOffsets"] = schedule.prefix(count).map { $0.minuteOffset }
```

### 5. Sync Quiet Hours

In Settings view, when user changes quiet hours:

```swift
// After saving to UserDefaults:
Task { await DeviceService.shared.syncQuietHours(start: newStart, end: newEnd) }
```

---

## Mission Lifecycle (Updated)

```
1. User creates mission (title, agent, deadline)
   → iOS: MissionService.createMission() → row in yap_goals (same as now)

2. iOS calls generate-copy edge function
   → GPT generates 24 messages + reaction
   → Edge function writes 24 rows to yap_notifications (NEW)
   → Edge function returns reaction to iOS (same as now)

3. pg_cron (every minute) → send-notifications edge function
   → Query pending notifications where scheduled_at <= now()
   → Check quiet hours per device timezone
   → Send via APNs HTTP/2
   → Mark as sent

4. User taps "Done ✅" in notification
   → AppDelegate handles action → MissionService.completeMission()
   → NagService.cancelNotifications() → marks remaining as 'cancelled' in DB

5. Mission expires (deadline passed, all notifications sent)
   → Last meltdown notification delivered
   → No auto-give-up (user decides)
```

---

## Costs

| Component | Cost |
|---|---|
| **Supabase Pro** | $25/mo (already paying, shared with FiveThings) |
| **pg_cron + pg_net** | Included in Pro |
| **Edge Function invocations** | 500K/mo free. send-notifications: 1 call/min = 43K/mo. generate-copy: same as now. **$0** |
| **OpenAI** | Same as now (batch generation). ~$0.002/mission. **No change.** |
| **APNs** | **Free** (Apple charges nothing) |
| **Apple Developer Program** | $99/year (already paying) |
| **Total added cost** | **$0/mo** |

### At scale

| Users | Missions/day | Notifications/day | Edge Function calls/mo | Cost delta |
|---|---|---|---|---|
| 100 | 100 | 2,400 | 43K (cron only) | $0 |
| 1,000 | 1,000 | 24,000 | 43K | $0 |
| 10,000 | 10,000 | 240,000 | 43K | $0 |
| 100,000 | 100,000 | 2.4M | 43K | $0 |

The cron-triggered edge function handles ALL notifications in a single invocation (batched query). The function call count stays at ~43K/mo regardless of user count. Only Supabase DB egress/storage increases, which is included in Pro up to 8GB/500MB respectively.

---

## Apple Developer Setup

### 1. Create APNs Auth Key (.p8)

1. Go to [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Create new key → enable "Apple Push Notifications service (APNs)"
3. Download `.p8` file (only downloadable once!)
4. Note the **Key ID** (10 chars, e.g. `ABC123DEFG`)

### 2. Store in Supabase Secrets

```bash
supabase secrets set APNS_KEY_ID=<your-key-id>
supabase secrets set APNS_TEAM_ID=98QF3H5LV4
supabase secrets set APNS_PRIVATE_KEY="$(cat AuthKey_XXXXXXXXXX.p8)"
```

### 3. Enable Push Capability in Xcode

1. Yap target → Signing & Capabilities → + Capability → Push Notifications
2. Ensure `.entitlements` has `aps-environment = production`

---

## Implementation Order

### Phase 1: Server-side (can be deployed before iOS update)
1. ✅ Create migration `005_remote_push.sql` (yap_devices + yap_notifications + pg_cron)
2. ✅ Create edge function `send-notifications` (APNs sender)
3. ✅ Update edge function `generate-copy` (write to yap_notifications)
4. ✅ Generate APNs .p8 key, store in Supabase secrets
5. ✅ Deploy & test with curl

### Phase 2: iOS update
6. ✅ Add Push Notifications capability in Xcode
7. ✅ Create `DeviceService.swift` (token + settings sync)
8. ✅ Update `AppDelegate.swift` (APNs registration)
9. ✅ Refactor `NagService.swift` (remove local scheduling, add server cancel)
10. ✅ Update `CopyService.swift` (send goalId + schedule offsets)
11. ✅ Sync quiet hours and timezone on change
12. ✅ Test end-to-end

### Phase 3: Advanced (future)
13. 🔮 Dynamic re-generation: on meltdown level, generate 1 fresh message with updated memory
14. 🔮 Re-engagement pushes: "You haven't started a mission in 3 days"
15. 🔮 Streak-at-risk pushes: "Complete a mission today or your 7-day streak dies"
16. 🔮 A/B test escalation profiles per agent
17. 🔮 Snooze action: postpone next notification by 30 min (update scheduled_at in DB)

---

## Fallback Strategy

If the server is down or APNs fails, the app still works:

- **Offline missions:** iOS can fall back to local notifications if `yap_devices` registration fails
- **NagCopy templates:** Static templates remain as client-side fallback
- **generate-copy failure:** Already handled — falls back to NagCopy templates locally
- **APNs token expiry:** Edge function catches 410 → sets `push_enabled = false` → iOS re-registers on next launch

---

## Files to Create/Modify

### New files
| File | Purpose |
|---|---|
| `Yap/supabase/migrations/005_remote_push.sql` | yap_devices + yap_notifications tables, indexes, RLS, pg_cron |
| `Yap/supabase/functions/send-notifications/index.ts` | APNs sender edge function |
| `Yap/Yap/Domain/DeviceService.swift` | APNs token registration + settings sync |

### Modified files
| File | Change |
|---|---|
| `Yap/supabase/functions/generate-copy/index.ts` | Write messages to yap_notifications |
| `Yap/Yap/AppDelegate.swift` | Add registerForRemoteNotifications + token handler |
| `Yap/Yap/Domain/NagService.swift` | Remove local scheduling, add server-side cancel |
| `Yap/Yap/Domain/CopyService.swift` | Send goalId + scheduleOffsets to generate-copy |
| `Yap/Yap/Yap.entitlements` | Add aps-environment capability |

### Unchanged files
| File | Why |
|---|---|
| `EscalationLevel.swift` | buildSchedule() still used client-side to compute offsets |
| `Agent.swift` | EscalationProfile stays for schedule computation |
| `MissionService.swift` | CRUD unchanged, notifications_scheduled still tracked |
| `Mission.swift` | Model unchanged |
| `QuietHours.swift` | Still used for local UI; server has its own check |
