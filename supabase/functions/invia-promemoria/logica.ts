// Logica dell'invio dei promemoria Web Push, separata da Supabase e da
// web-push per poterla provare (logica_test.ts).

/** Una riga restituita da public.preleva_promemoria. */
export interface Promemoria {
  user_id: string;
  id: number;
  title: string;
  body: string;
  urgent: boolean;
  endpoint: string;
  p256dh: string;
  auth: string;
}

export interface Iscrizione {
  endpoint: string;
  keys: { p256dh: string; auth: string };
}

export interface OpzioniInvio {
  TTL: number;
  urgency: "high" | "normal";
  topic?: string;
}

/** Invia una notifica; in caso d'errore lancia un oggetto con statusCode. */
export type Invia = (
  iscrizione: Iscrizione,
  payload: string,
  opzioni: OpzioniInvio,
) => Promise<unknown>;

export interface Esito {
  inviati: number;
  errori: number;
  /** Iscrizioni che il servizio push dice scadute (404/410): da scartare. */
  scadute: string[];
}

/** Contenuto letto da web/sw.js (evento "push"). */
export function payload(p: Promemoria): string {
  return JSON.stringify({
    title: p.title,
    body: p.body,
    tag: `lulu-${p.id}${p.urgent ? "-u" : ""}`,
    urgent: p.urgent,
  });
}

export function opzioni(p: Promemoria): OpzioniInvio {
  return {
    // Un allarme vale ancora per qualche ora; un promemoria qualunque no.
    TTL: p.urgent ? 6 * 3600 : 3600,
    urgency: p.urgent ? "high" : "normal",
  };
}

export async function inviaTutti(
  righe: Promemoria[],
  invia: Invia,
  parallelo = 20,
): Promise<Esito> {
  const esito: Esito = { inviati: 0, errori: 0, scadute: [] };
  for (let i = 0; i < righe.length; i += parallelo) {
    await Promise.all(
      righe.slice(i, i + parallelo).map(async (p) => {
        try {
          await invia(
            { endpoint: p.endpoint, keys: { p256dh: p.p256dh, auth: p.auth } },
            payload(p),
            opzioni(p),
          );
          esito.inviati++;
        } catch (e) {
          const code = (e as { statusCode?: number })?.statusCode;
          if (code === 404 || code === 410) {
            if (!esito.scadute.includes(p.endpoint)) esito.scadute.push(p.endpoint);
          } else {
            esito.errori++;
            console.error("Promemoria non inviato", code ?? e);
          }
        }
      }),
    );
  }
  return esito;
}

/** Solo il cron (pg_cron + pg_net) conosce il segreto CRON_SECRET. */
export function autorizzato(req: Request, segreto: string | undefined): boolean {
  if (!segreto || segreto.length < 16) return false;
  const atteso = `Bearer ${segreto}`;
  const dato = req.headers.get("authorization") ?? "";
  if (dato.length !== atteso.length) return false;
  let diff = 0;
  for (let i = 0; i < atteso.length; i++) {
    diff |= atteso.charCodeAt(i) ^ dato.charCodeAt(i);
  }
  return diff === 0;
}
