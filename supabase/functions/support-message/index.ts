// Contact support: record a message from the app and email it to the team
// inbox, with the sender's account email as the reply address — so a reply
// written in the inbox goes straight back to the user, and the thread lives
// in ordinary email from then on.
//
// The app calls this with the signed-in user's JWT (supabase_flutter's
// functions.invoke adds it). The gateway verifies the token; the user id
// and email are read from it here, never trusted from the body.
//
// Secrets (supabase secrets set ...):
//   RESEND_API_KEY   from resend.com (shared with revenuecat-webhook)
//   EMAIL_FROM       e.g. "Forma <hello@your-verified-domain>" (shared)
//   SUPPORT_INBOX    where messages land, e.g. "support@tryforma.co" — a
//                    Gmail address works as-is
//   SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are
//   injected by Supabase.
//
// Deploy with JWT verification on (the default):
//   supabase functions deploy support-message

import { createClient } from "npm:@supabase/supabase-js@2";

type Body = {
  message?: unknown;
  app_version?: unknown;
  platform?: unknown;
  os_version?: unknown;
};

const MAX_MESSAGE_LENGTH = 5000;

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const text = (value: unknown, max = 200): string | null =>
  typeof value === "string" && value.trim() ? value.trim().slice(0, max) : null;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  const authorization = req.headers.get("Authorization");
  if (!authorization) return json(401, { error: "Unauthorized" });

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authorization } } },
  );
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) return json(401, { error: "Unauthorized" });

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "Bad request" });
  }
  const message = text(body.message, MAX_MESSAGE_LENGTH);
  if (!message) return json(400, { error: "message is required" });

  const diagnostics = {
    app_version: text(body.app_version),
    platform: text(body.platform),
    os_version: text(body.os_version),
  };

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // The row first: even if the email fails to go out, the message is not
  // lost, and the retry from the app replaces it.
  const { data: row, error: insertError } = await admin
    .from("feedback")
    .insert({ user_id: user.id, kind: "support", note: message, ...diagnostics })
    .select("id")
    .single();
  if (insertError || !row) {
    console.error("insert failed", insertError);
    return json(500, { error: "Could not save message" });
  }

  try {
    await sendToInbox({
      id: row.id,
      message,
      userId: user.id,
      email: user.email ?? null,
      ...diagnostics,
    });
  } catch (error) {
    console.error("email failed", error);
    // The app will show "try again" and resend; drop this row so the
    // retry does not leave a duplicate behind.
    await admin.from("feedback").delete().eq("id", row.id);
    return json(502, { error: "Could not deliver message" });
  }

  return json(200, { id: row.id });
});

type Outgoing = {
  id: string;
  message: string;
  userId: string;
  email: string | null;
  app_version: string | null;
  platform: string | null;
  os_version: string | null;
};

async function sendToInbox(m: Outgoing) {
  const inbox = Deno.env.get("SUPPORT_INBOX");
  if (!inbox) throw new Error("SUPPORT_INBOX is not set");

  const firstLine = m.message.split("\n")[0].trim();
  const subject = `Forma support: ${firstLine.length > 60 ? firstLine.slice(0, 57) + "…" : firstLine}`;
  const details = [
    `From: ${m.email ?? "(no email on account)"}`,
    `User id: ${m.userId}`,
    `App: ${m.app_version ?? "unknown"} · ${m.platform ?? "unknown"} · ${m.os_version ?? "unknown"}`,
    `Feedback id: ${m.id}`,
  ];
  const plain = [m.message, "", "—", ...details].join("\n");
  const html = [
    `<div style="font-family:-apple-system,Helvetica,Arial,sans-serif;font-size:15px;line-height:1.5;color:#111">`,
    `<p style="white-space:pre-wrap">${escapeHtml(m.message)}</p>`,
    `<hr style="border:0;border-top:1px solid #ddd;margin:20px 0">`,
    `<p style="font-size:13px;color:#666">${details.map(escapeHtml).join("<br>")}</p>`,
    `</div>`,
  ].join("");

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("EMAIL_FROM"),
      to: [inbox],
      ...(m.email ? { reply_to: m.email } : {}),
      subject,
      text: plain,
      html,
      headers: { "X-Entity-Ref-ID": m.id },
    }),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
