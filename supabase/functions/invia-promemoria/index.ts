// Edge Function «invia-promemoria»: ogni minuto (pg_cron) preleva i
// promemoria scaduti e li invia con Web Push. Vedi supabase/LEGGIMI.md.
//
// Segreti (supabase secrets set ...): CRON_SECRET, VAPID_PUBLIC_KEY,
// VAPID_PRIVATE_KEY, VAPID_SUBJECT (mailto:indirizzo o https://sito).
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY li fornisce Supabase.
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";
import { autorizzato, inviaTutti, type Promemoria } from "./logica.ts";

Deno.serve(async (req) => {
  if (!autorizzato(req, Deno.env.get("CRON_SECRET"))) {
    return new Response("Non autorizzato", { status: 401 });
  }
  const pub = Deno.env.get("VAPID_PUBLIC_KEY");
  const priv = Deno.env.get("VAPID_PRIVATE_KEY");
  const subject = Deno.env.get("VAPID_SUBJECT");
  if (!pub || !priv || !subject) {
    return new Response("Chiavi VAPID mancanti", { status: 500 });
  }
  webpush.setVapidDetails(subject, pub, priv);

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data, error } = await db.rpc("preleva_promemoria", { p_limite: 500 });
  if (error) {
    console.error("preleva_promemoria", error.message);
    return new Response("Errore del database", { status: 500 });
  }
  const esito = await inviaTutti(
    (data ?? []) as Promemoria[],
    (iscrizione, payload, opzioni) =>
      webpush.sendNotification(iscrizione, payload, opzioni),
  );
  if (esito.scadute.length) {
    const r = await db.rpc("scarta_iscrizioni_push", { p_endpoints: esito.scadute });
    if (r.error) console.error("scarta_iscrizioni_push", r.error.message);
  }
  // Solo numeri: nessun testo dei promemoria nei registri.
  return Response.json(esito);
});
