import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, anthropic-version, anthropic-beta",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("authorization") ?? req.headers.get("Authorization");
    const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!token) {
      return json({ error: "Missing bearer token" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey =
      Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SB_PUBLISHABLE_KEY");
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return json({ error: "Supabase env vars missing" }, 500);
    }
    if (!anthropicApiKey) {
      return json({ error: "ANTHROPIC_API_KEY is not set" }, 500);
    }

    // Explicitly verify JWT from caller.
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) {
      return json({ error: "Invalid or expired JWT" }, 401);
    }

    // Pass-through request shape to Anthropic.
    const body = await req.text();
    const anthropicVersion = req.headers.get("anthropic-version") ?? "2023-06-01";
    const anthropicBeta = req.headers.get("anthropic-beta");

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": anthropicVersion,
        ...(anthropicBeta ? { "anthropic-beta": anthropicBeta } : {}),
      },
      body,
    });

    const responseHeaders = new Headers(corsHeaders);
    responseHeaders.set(
      "Content-Type",
      upstream.headers.get("content-type") ?? "application/json"
    );

    return new Response(await upstream.text(), {
      status: upstream.status,
      headers: responseHeaders,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown proxy error";
    return json({ error: message }, 500);
  }
});

function json(payload: Record<string, string>, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
