// Paywall follow-up: a day after someone reaches "Your training program is
// ready" without starting the trial, one email asking why.
//
// pg_cron calls this every hour (migrations/2026-10-10_paywall_follow_up.sql).
// A run takes everyone whose onboarding profile was written 24–48 hours ago
// — the row lands on "Build my program", the moment the trial screen
// appears — and emails those who have never had a trial or a subscription.
// The window is also the backlog guard: nobody older than two days is ever
// picked up, so a run after an outage stays quiet rather than sending
// "yesterday you..." a week late.
//
// Before anyone is emailed:
//   - email_sends says they have not had this one already;
//   - webhook_events holds no RevenueCat event for them (a cheap local no);
//   - RevenueCat, asked live, lists no subscription for them, ever — the
//     decider, so a missed webhook can never email a paying member;
//   - their address is not on the excluded list (team and test accounts).
// Anything failing means no email; the next hour tries again while they
// are still in the window.
//
// Secrets (supabase secrets set ...):
//   PAYWALL_FOLLOW_UP_SECRET   what the cron job sends as Authorization;
//                              tool/setup_paywall_follow_up.sh sets both ends
//   REVENUECAT_API_KEY         a secret API key (Project settings → API keys)
//   RESEND_API_KEY             from resend.com (shared)
//   EMAIL_FROM                 e.g. "Forma <hello@your-verified-domain>" (shared)
//   SUPPORT_INBOX              where replies go (shared)
//   FOLLOW_UP_TEMPLATE_ID      optional; id or alias of a published Resend
//                              template, sent with the `name` variable. It
//                              must carry its own subject. When unset, the
//                              inline copy below is sent.
//   FOLLOW_UP_EXCLUDED_EMAILS  optional; comma-separated addresses that are
//                              never emailed
//   FOLLOW_UP_DRY_RUN          optional; "true" reports who would be emailed
//                              and sends nothing. ?dry_run=1 on a call does
//                              the same for that call only.
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected by Supabase.
//
// Deploy with --no-verify-jwt: pg_net sends the shared secret, not a JWT.

import { createClient } from "npm:@supabase/supabase-js@2";

const KIND = "paywall_follow_up";
const WINDOW_START_HOURS = 48;
const WINDOW_END_HOURS = 24;

type Supabase = ReturnType<typeof createClient>;

type Candidate = {
  userId: string;
  completedAt: string;
  email: string;
  firstName: string | null;
};

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  const secret = Deno.env.get("PAYWALL_FOLLOW_UP_SECRET");
  if (!secret || req.headers.get("authorization") !== secret) {
    return json(401, { error: "Unauthorized" });
  }

  const dryRun = Deno.env.get("FOLLOW_UP_DRY_RUN") === "true" ||
    new URL(req.url).searchParams.get("dry_run") === "1";

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = Date.now();
  const from = new Date(now - WINDOW_START_HOURS * 3600_000).toISOString();
  const to = new Date(now - WINDOW_END_HOURS * 3600_000).toISOString();

  const { data: profiles, error: profilesError } = await supabase
    .from("user_onboarding_profiles")
    .select("user_id, completed_at")
    .gte("completed_at", from)
    .lt("completed_at", to)
    .order("completed_at");
  if (profilesError) {
    console.error("profiles query failed", profilesError);
    return json(500, { error: "Database error" });
  }

  const skipped: Record<string, string[]> = {};
  const skip = (reason: string, who: string) => {
    (skipped[reason] ??= []).push(who);
    console.log(`skip ${reason} ${who}`);
  };
  const recipients: string[] = [];
  const failed: string[] = [];

  const ids = (profiles ?? []).map((p) => p.user_id as string);
  if (ids.length > 0) {
    const [users, sends, events] = await Promise.all([
      supabase.from("users").select("id, email, full_name").in("id", ids),
      supabase.from("email_sends").select("user_id").eq("kind", KIND).in("user_id", ids),
      supabase.from("webhook_events").select("app_user_id").in("app_user_id", ids),
    ]);
    const failure = users.error ?? sends.error ?? events.error;
    if (failure) {
      console.error("lookup failed", failure);
      return json(500, { error: "Database error" });
    }
    const userById = new Map((users.data ?? []).map((u) => [u.id as string, u]));
    const alreadySent = new Set((sends.data ?? []).map((s) => s.user_id as string));
    const hasEvent = new Set((events.data ?? []).map((e) => e.app_user_id as string));
    const excluded = excludedEmails();

    for (const profile of profiles ?? []) {
      const userId = profile.user_id as string;
      const user = userById.get(userId);
      const email = (user?.email as string | null)?.trim().toLowerCase();
      if (!email) {
        skip("no_email", userId);
        continue;
      }
      if (excluded.has(email)) {
        skip("excluded", email);
        continue;
      }
      if (alreadySent.has(userId)) {
        skip("already_sent", email);
        continue;
      }
      if (hasEvent.has(userId)) {
        skip("has_webhook_event", email);
        continue;
      }

      let subscribed: boolean;
      try {
        subscribed = await hasEverSubscribed(userId);
      } catch (error) {
        console.error("revenuecat lookup failed", email, error);
        failed.push(email);
        continue;
      }
      if (subscribed) {
        skip("has_subscription", email);
        continue;
      }

      const fullName = (user?.full_name as string | null)?.trim() ?? "";
      const candidate: Candidate = {
        userId,
        completedAt: profile.completed_at as string,
        email,
        firstName: fullName ? fullName.split(/\s+/)[0] : null,
      };

      if (dryRun) {
        console.log(`would send ${email}`);
        recipients.push(email);
        continue;
      }

      // The row is claimed before the send, so two runs overlapping on the
      // hour cannot both email the same person; the loser sees the key
      // collide and moves on.
      const { error: claimError } = await supabase
        .from("email_sends")
        .insert({ user_id: userId, kind: KIND });
      if (claimError) {
        if (claimError.code === "23505") {
          skip("already_sent", email);
        } else {
          console.error("email_sends insert failed", claimError);
          failed.push(email);
        }
        continue;
      }

      try {
        await sendFollowUp(candidate);
      } catch (error) {
        console.error("resend failed", email, error);
        // Give the row back so the next hour tries again.
        await supabase.from("email_sends").delete().eq("user_id", userId).eq("kind", KIND);
        failed.push(email);
        continue;
      }
      console.log(`sent ${email}`);
      recipients.push(email);
    }
  }

  return json(200, {
    dry_run: dryRun,
    window: { from, to },
    in_window: ids.length,
    [dryRun ? "would_send" : "sent"]: recipients,
    skipped,
    failed,
  });
});

function excludedEmails(): Set<string> {
  return new Set(
    (Deno.env.get("FOLLOW_UP_EXCLUDED_EMAILS") ?? "")
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean),
  );
}

// The app logs into RevenueCat with the Supabase user id, so the subscriber
// can be fetched by it directly. Every subscription a customer has ever
// had stays listed, expired or not, so an empty list means they never
// started one; entitlements are checked too, in case one was ever granted
// by hand. (A GET on an id RevenueCat has not seen creates the customer and
// answers 201 — harmless, and rare, since the app registers everyone who
// reaches the paywall.)
async function hasEverSubscribed(userId: string): Promise<boolean> {
  const key = Deno.env.get("REVENUECAT_API_KEY");
  if (!key) throw new Error("REVENUECAT_API_KEY is not set");
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    { headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" } },
  );
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
  const { subscriber } = await response.json();
  return Object.keys(subscriber?.subscriptions ?? {}).length > 0 ||
    Object.keys(subscriber?.entitlements ?? {}).length > 0;
}

async function sendFollowUp(c: Candidate) {
  const inbox = Deno.env.get("SUPPORT_INBOX");
  const base = {
    from: Deno.env.get("EMAIL_FROM"),
    to: [c.email],
    ...(inbox ? { reply_to: inbox } : {}),
    headers: { "X-Entity-Ref-ID": `${KIND}-${c.userId}` },
  };
  const templateId = Deno.env.get("FOLLOW_UP_TEMPLATE_ID");
  const payload = templateId
    ? { ...base, template: { id: templateId, variables: { name: c.firstName ?? "there" } } }
    : { ...base, subject: "Can I ask why you didn't start the trial?", ...inlineCopy(c.firstName) };

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
}

// The fallback used when no Resend template is configured.
function inlineCopy(firstName: string | null): { text: string; html: string } {
  const paragraphs = [
    `Hi${firstName ? ` ${firstName}` : ""},`,
    "Yesterday you built your training program in Forma but didn't start the free trial. That's completely fine — I'd just like to know why.",
    "Was it the price, the trial itself, something about the program, or did you want to look around first? Reply with a line or two. I read every one, and if something was unclear or missing I'd like to fix it.",
    "— Forma",
  ];
  return {
    text: paragraphs.join("\n\n"),
    html: `<div style="font-family:-apple-system,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.5;color:#111">${
      paragraphs.map((p) => `<p>${escapeHtml(p)}</p>`).join("")
    }</div>`,
  };
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
