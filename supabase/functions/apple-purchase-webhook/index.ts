// Supabase Edge Function: Apple App Store Server Notifications V2
// Sends a push notification via brrr on every Yap Pro purchase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const BRRR_URL =
  "https://api.brrr.now/v1/br_usr_da385e5bcff5bc8cdb367c186827576f2d3691ff2e97e44abbd9f4ef4c8f514f";

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const decoded = atob(
      parts[1].replace(/-/g, "+").replace(/_/g, "/")
    );
    return JSON.parse(decoded);
  } catch {
    return null;
  }
}

function formatPrice(amount: number, currency: string): string {
  return new Intl.NumberFormat("de-DE", {
    style: "currency",
    currency: currency || "EUR",
  }).format(amount / 1000);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json();
    const signedPayload = body.signedPayload;

    if (!signedPayload) {
      console.error("No signedPayload");
      return new Response("No signedPayload", { status: 400 });
    }

    const payload = decodeJwtPayload(signedPayload);
    if (!payload) {
      console.error("Failed to decode payload");
      return new Response("Invalid payload", { status: 400 });
    }

    const type = payload.notificationType as string;
    const data = payload.data as Record<string, unknown> | undefined;
    const environment = (data?.environment as string) || "Unknown";
    const isSandbox = environment === "Sandbox";

    let transactionInfo: Record<string, unknown> | null = null;
    if (data?.signedTransactionInfo) {
      transactionInfo = decodeJwtPayload(data.signedTransactionInfo as string);
    }

    const productId = (transactionInfo?.productId as string) || "unknown";
    const price = transactionInfo?.price as number | undefined;
    const currency = transactionInfo?.currency as string | undefined;
    const storefront = (transactionInfo?.storefront as string) || "";

    // Build notification text
    const isPurchase = type === "ONE_TIME_CHARGE";
    const priceStr =
      price !== undefined && currency ? formatPrice(price, currency) : "";
    const flag = storefront.length === 2 ? ` ${storefront}` : storefront ? ` (${storefront})` : "";

    let message: string;

    if (isPurchase && !isSandbox) {
      message = `💰 New Yap Pro!${priceStr ? ` ${priceStr}` : ""}${flag}`;
    } else if (isPurchase && isSandbox) {
      message = `🧪 Sandbox purchase: ${productId}${priceStr ? ` ${priceStr}` : ""}`;
    } else {
      message = `📬 ${type}${isSandbox ? " (Sandbox)" : ""} – ${productId}`;
    }

    console.log("Sending brrr:", message);

    const brrrRes = await fetch(BRRR_URL, {
      method: "POST",
      body: message,
    });

    if (!brrrRes.ok) {
      console.error("brrr failed:", await brrrRes.text());
    }

    // Always 200 so Apple doesn't retry
    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Error:", err);
    return new Response(JSON.stringify({ error: "Processing failed" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }
});
