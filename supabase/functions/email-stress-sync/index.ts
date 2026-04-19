import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const KEYWORDS = ["urgent", "board", "legal", "asap", "deadline", "critical", "review"];

type ContactTag = { email: string; priority: "high" | "low" };

type SenderAggregate = {
  sender_email: string;
  sender_priority: "high" | "low";
  unread_threads: number;
  thread_length_score: number;
  subject_keywords: string[];
  stress_score: number;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("authorization") ?? req.headers.get("Authorization");
    const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!token) return json({ error: "Missing bearer token" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SB_PUBLISHABLE_KEY");
    if (!supabaseUrl || !supabaseAnonKey) return json({ error: "Supabase env vars missing" }, 500);

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authData, error: authError } = await supabase.auth.getUser(token);
    if (authError || !authData.user) return json({ error: "Invalid or expired JWT" }, 401);

    const body = await req.json();
    const provider = body?.provider as "gmail" | "outlook" | undefined;
    const accessToken = body?.access_token as string | undefined;
    const days = Number(body?.days ?? 7);
    if (!provider || !["gmail", "outlook"].includes(provider)) {
      return json({ error: "provider must be gmail|outlook" }, 400);
    }
    if (!accessToken || accessToken.length < 10) {
      return json({ error: "access_token missing" }, 400);
    }

    const { data: tags, error: tagsError } = await supabase
      .from("contact_tags")
      .select("email, priority")
      .eq("user_id", authData.user.id);
    if (tagsError) return json({ error: tagsError.message }, 500);

    const tagMap = new Map<string, "high" | "low">();
    (tags ?? []).forEach((tag: ContactTag) => {
      tagMap.set(tag.email.toLowerCase(), tag.priority);
    });

    if (tagMap.size === 0) {
      await supabase
        .from("email_stress_signals")
        .delete()
        .eq("user_id", authData.user.id)
        .eq("provider", provider);
      return json({ signals: [] });
    }

    const aggregates =
      provider === "gmail"
        ? await collectFromGmail(accessToken, tagMap, days)
        : await collectFromOutlook(accessToken, tagMap, days);

    const now = new Date().toISOString();
    const rows = aggregates.map((signal) => ({
      id: crypto.randomUUID(),
      user_id: authData.user.id,
      provider,
      sender_email: signal.sender_email,
      sender_priority: signal.sender_priority,
      unread_threads: signal.unread_threads,
      thread_length_score: signal.thread_length_score,
      subject_keywords: signal.subject_keywords,
      stress_score: signal.stress_score,
      generated_at: now,
      updated_at: now,
    }));

    const deleteOld = await supabase
      .from("email_stress_signals")
      .delete()
      .eq("user_id", authData.user.id)
      .eq("provider", provider);
    if (deleteOld.error) return json({ error: deleteOld.error.message }, 500);

    if (rows.length > 0) {
      const { error: insertError } = await supabase.from("email_stress_signals").insert(rows);
      if (insertError) return json({ error: insertError.message }, 500);
    }

    return json({ signals: rows });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown sync error";
    return json({ error: message }, 500);
  }
});

async function collectFromGmail(
  accessToken: string,
  tagMap: Map<string, "high" | "low">,
  days: number
): Promise<SenderAggregate[]> {
  const q = encodeURIComponent(`in:inbox is:unread newer_than:${Math.max(1, days)}d`);
  const listUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=200&q=${q}`;
  const listRes = await fetch(listUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!listRes.ok) throw new Error(`Gmail list failed: ${listRes.status}`);

  const listJson = await listRes.json();
  const messages = (listJson.messages ?? []) as Array<{ id: string; threadId: string }>;
  if (messages.length === 0) return [];

  const aggregateMap = new Map<
    string,
    { priority: "high" | "low"; threadSet: Set<string>; depth: number; keywords: Set<string> }
  >();

  for (const message of messages) {
    const detailsRes = await fetch(
      `https://gmail.googleapis.com/gmail/v1/users/me/messages/${message.id}?format=metadata&metadataHeaders=From&metadataHeaders=Subject`,
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );
    if (!detailsRes.ok) continue;
    const details = await detailsRes.json();
    const headers = (details.payload?.headers ?? []) as Array<{ name: string; value: string }>;
    const fromRaw = headerValue(headers, "From");
    const subject = headerValue(headers, "Subject");
    const sender = parseEmail(fromRaw);
    if (!sender) continue;

    const priority = tagMap.get(sender);
    if (!priority) continue;

    const existing = aggregateMap.get(sender) ?? {
      priority,
      threadSet: new Set<string>(),
      depth: 0,
      keywords: new Set<string>(),
    };
    existing.threadSet.add(message.threadId ?? details.threadId ?? message.id);
    existing.depth += 1;
    extractKeywords(subject).forEach((k) => existing.keywords.add(k));
    aggregateMap.set(sender, existing);
  }

  return finalizeAggregates(aggregateMap);
}

async function collectFromOutlook(
  accessToken: string,
  tagMap: Map<string, "high" | "low">,
  days: number
): Promise<SenderAggregate[]> {
  const since = new Date(Date.now() - Math.max(1, days) * 24 * 60 * 60 * 1000).toISOString();
  const filter = encodeURIComponent(`isRead eq false and receivedDateTime ge ${since}`);
  const select = encodeURIComponent("subject,from,conversationId,isRead,receivedDateTime");
  const url =
    `https://graph.microsoft.com/v1.0/me/mailFolders/Inbox/messages` +
    `?$top=200&$select=${select}&$filter=${filter}`;

  const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!res.ok) throw new Error(`Outlook list failed: ${res.status}`);

  const jsonBody = await res.json();
  const messages = (jsonBody.value ?? []) as Array<{
    subject?: string;
    conversationId?: string;
    from?: { emailAddress?: { address?: string } };
  }>;

  const aggregateMap = new Map<
    string,
    { priority: "high" | "low"; threadSet: Set<string>; depth: number; keywords: Set<string> }
  >();

  for (const message of messages) {
    const sender = (message.from?.emailAddress?.address ?? "").toLowerCase();
    if (!sender) continue;
    const priority = tagMap.get(sender);
    if (!priority) continue;

    const existing = aggregateMap.get(sender) ?? {
      priority,
      threadSet: new Set<string>(),
      depth: 0,
      keywords: new Set<string>(),
    };
    existing.threadSet.add(message.conversationId ?? crypto.randomUUID());
    existing.depth += 1;
    extractKeywords(message.subject ?? "").forEach((k) => existing.keywords.add(k));
    aggregateMap.set(sender, existing);
  }

  return finalizeAggregates(aggregateMap);
}

function finalizeAggregates(
  aggregateMap: Map<
    string,
    { priority: "high" | "low"; threadSet: Set<string>; depth: number; keywords: Set<string> }
  >
): SenderAggregate[] {
  return Array.from(aggregateMap.entries())
    .map(([sender, value]) => {
      const unreadThreads = value.threadSet.size;
      const keywordCount = value.keywords.size;
      const base = unreadThreads * 3 + value.depth * 2 + keywordCount * 4;
      const weight = value.priority === "high" ? 10 : 3;
      const stress = Math.min(100, base + weight);
      return {
        sender_email: sender,
        sender_priority: value.priority,
        unread_threads: unreadThreads,
        thread_length_score: value.depth,
        subject_keywords: Array.from(value.keywords),
        stress_score: stress,
      };
    })
    .sort((a, b) => b.stress_score - a.stress_score);
}

function headerValue(headers: Array<{ name: string; value: string }>, name: string): string {
  const match = headers.find((h) => h.name?.toLowerCase() === name.toLowerCase());
  return match?.value ?? "";
}

function parseEmail(raw: string): string | null {
  if (!raw) return null;
  const bracket = raw.match(/<([^>]+)>/);
  const candidate = (bracket?.[1] ?? raw).trim().toLowerCase();
  if (!candidate.includes("@")) return null;
  return candidate.replace(/^"|"$/g, "");
}

function extractKeywords(subject: string): string[] {
  const lower = subject.toLowerCase();
  return KEYWORDS.filter((keyword) => lower.includes(keyword));
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
