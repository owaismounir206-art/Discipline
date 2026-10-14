// Ritmo — app di calisthenics libera e gratuita.
// Copyright (C) 2026 Ritmo contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Edge Function di Supabase: dà a chi partecipa a una sfida il "biglietto"
// (token) per entrare nella stanza video LiveKit di quella sfida.
//
// Segreti da impostare (mai nel codice):
//   supabase secrets set LIVEKIT_API_KEY=... LIVEKIT_API_SECRET=...
// SUPABASE_URL e SUPABASE_ANON_KEY sono già disponibili nella funzione.
//
// Deploy: supabase functions deploy livekit-token

import { createClient } from "npm:@supabase/supabase-js@2";
import { AccessToken } from "npm:livekit-server-sdk@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function reply(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const auth = req.headers.get("Authorization");
  if (!auth) return reply({ error: "Accedi per usare il video" }, 401);

  // Il client agisce "come l'utente": le regole RLS gli mostrano solo le
  // sue sfide, quindi se la stanza non è sua la query resta vuota.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) return reply({ error: "Non autorizzato" }, 401);
  const user = userData.user;

  let room: string | undefined;
  try {
    room = (await req.json()).room;
  } catch (_) {
    return reply({ error: "Richiesta non valida" }, 400);
  }
  if (!room || !/^[0-9a-f-]{36}$/.test(room)) {
    return reply({ error: "Stanza non valida" }, 400);
  }

  const { data: row } = await supabase
    .from("challenge_rooms")
    .select("id, players, cancelled")
    .eq("id", room)
    .maybeSingle();
  if (!row || row.cancelled || !(user.id in (row.players ?? {}))) {
    return reply({ error: "Non fai parte di questa sfida" }, 403);
  }

  const apiKey = Deno.env.get("LIVEKIT_API_KEY");
  const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
  if (!apiKey || !apiSecret) return reply({ error: "Video non configurato" }, 503);

  const token = new AccessToken(apiKey, apiSecret, {
    identity: user.id,
    name: (row.players as Record<string, string>)[user.id],
    ttl: "15m", // una sfida dura al massimo 5 minuti
  });
  token.addGrant({
    room: room,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
  });
  return reply({ token: await token.toJwt() });
});
