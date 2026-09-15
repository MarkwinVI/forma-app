// RevenueCat → Resend: email a member who turns off auto-renew during the
// free trial.
//
// RevenueCat posts every subscription event here (register the function URL
// under Integrations → Webhooks). Only one kind is acted on: a voluntary
// CANCELLATION while the period is a TRIAL, in PRODUCTION. Everything else
// is acknowledged with 200 so RevenueCat stops retrying.
//
// Secrets (supabase secrets set ...):
//   REVENUECAT_WEBHOOK_SECRET  the value RevenueCat sends as Authorization
//   RESEND_API_KEY             from resend.com
//   EMAIL_FROM                 e.g. "Forma <hello@your-verified-domain>"
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected by Supabase.
//
// Deploy with --no-verify-jwt: RevenueCat cannot send a Supabase JWT, so the
// shared secret above is the gate instead.

import { createClient } from "npm:@supabase/supabase-js@2";

type RevenueCatEvent = {
  id: string;
  type: string;
  environment: "SANDBOX" | "PRODUCTION";
  period_type?: string;
  cancel_reason?: string;
  app_user_id: string;
  original_app_user_id?: string;
  expiration_at_ms?: number;
  product_id?: string;
  subscriber_attributes?: Record<string, { value: string }>;
};

const ok = (body: string) => new Response(body, { status: 200 });

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret || req.headers.get("authorization") !== secret) {
    return new Response("Unauthorized", { status: 401 });
  }

  let event: RevenueCatEvent;
  try {
    event = (await req.json()).event;
    if (!event?.id || !event.type) throw new Error("missing event");
  } catch {
    return new Response("Bad request", { status: 400 });
  }

  const wanted =
    event.type === "CANCELLATION" &&
    event.period_type === "TRIAL" &&
    event.cancel_reason === "UNSUBSCRIBE" &&
    event.environment === "PRODUCTION";
  if (!wanted) return ok(`ignored ${event.type}`);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // RevenueCat retries on anything but 2xx; the primary key makes a retry a
  // no-op instead of a second email.
  const { error: dedupeError } = await supabase
    .from("webhook_events")
    .insert({ id: event.id, event_type: event.type });
  if (dedupeError) {
    if (dedupeError.code === "23505") return ok("already handled");
    console.error("webhook_events insert failed", dedupeError);
    return new Response("Database error", { status: 500 });
  }

  const email = await lookupEmail(supabase, event);
  if (!email) {
    console.warn("no email for", event.app_user_id);
    return ok("no email on file");
  }

  try {
    await sendTrialCancelledEmail(email, event);
  } catch (error) {
    console.error("resend failed", error);
    // Let RevenueCat retry: clear the dedupe row so the next attempt sends.
    await supabase.from("webhook_events").delete().eq("id", event.id);
    return new Response("Email failed", { status: 502 });
  }

  return ok("sent");
});

async function lookupEmail(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent,
): Promise<string | null> {
  // The app logs into RevenueCat with the Supabase user id, so app_user_id
  // is a public.users primary key. Anonymous ids ($RCAnonymousID:...) won't
  // match and fall through to the subscriber attribute.
  const ids = [event.app_user_id, event.original_app_user_id].filter(
    (id): id is string => !!id && !id.startsWith("$RCAnonymousID"),
  );
  if (ids.length > 0) {
    const { data } = await supabase
      .from("users")
      .select("email")
      .in("id", ids)
      .not("email", "is", null)
      .limit(1)
      .maybeSingle();
    if (data?.email) return data.email as string;
  }
  return event.subscriber_attributes?.["$email"]?.value ?? null;
}

async function sendTrialCancelledEmail(to: string, event: RevenueCatEvent) {
  const endsOn = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "long",
        year: "numeric",
      })
    : null;
  const untilLine = endsOn
    ? `Your trial stays fully unlocked until ${endsOn}, so nothing changes today.`
    : "Your trial stays fully unlocked until it ends, so nothing changes today.";

  const text = [
    "Hi,",
    "",
    "We noticed you turned off auto-renew on your Forma trial.",
    untilLine,
    "",
    "After that, your program, skill tracks and progression history stay saved, but the app locks until you're a member again. Resubscribing picks up exactly where you left off.",
    "",
    "If something didn't work the way you hoped, reply to this email. We read every one.",
    "",
    "— Forma",
  ].join("\n");

  const html = `
    <p>Hi,</p>
    <p>We noticed you turned off auto-renew on your Forma trial.<br>${untilLine}</p>
    <p>After that, your program, skill tracks and progression history stay saved, but the app locks until you're a member again. Resubscribing picks up exactly where you left off.</p>
    <p>If something didn't work the way you hoped, reply to this email. We read every one.</p>
    <p>— Forma</p>
  `;

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("EMAIL_FROM"),
      to: [to],
      subject: "Your Forma trial is still yours until it ends",
      text,
      html,
      headers: { "X-Entity-Ref-ID": event.id },
    }),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
}
