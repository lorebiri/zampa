import { assertEquals } from "jsr:@std/assert@1";
import { autorizzato, inviaTutti, opzioni, payload, type Promemoria } from "./logica.ts";

const riga = (o: Partial<Promemoria> = {}): Promemoria => ({
  user_id: "u1", id: 1, title: "💊 Dose", body: "Birba: Fenobarbital", urgent: false,
  endpoint: "https://push.example/1", p256dh: "k", auth: "a", ...o,
});

Deno.test("payload e opzioni: allarmi urgenti ad alta priorità", () => {
  const u = riga({ id: 90, urgent: true });
  assertEquals(JSON.parse(payload(u)), { title: "💊 Dose", body: "Birba: Fenobarbital", tag: "lulu-90-u", urgent: true });
  assertEquals(opzioni(u), { TTL: 21600, urgency: "high" });
  assertEquals(opzioni(riga()), { TTL: 3600, urgency: "normal" });
});

Deno.test("inviati, errori e iscrizioni scadute", async () => {
  const righe = [
    riga({ id: 1 }),
    riga({ id: 2, endpoint: "https://push.example/scaduta" }),
    riga({ id: 3, endpoint: "https://push.example/scaduta" }),
    riga({ id: 4, endpoint: "https://push.example/guasta" }),
  ];
  const visti: string[] = [];
  const esito = await inviaTutti(righe, (s, p) => {
    visti.push(s.endpoint + " " + JSON.parse(p).tag);
    if (s.endpoint.endsWith("scaduta")) return Promise.reject({ statusCode: 410 });
    if (s.endpoint.endsWith("guasta")) return Promise.reject({ statusCode: 500 });
    return Promise.resolve();
  }, 2);
  assertEquals(esito, { inviati: 1, errori: 1, scadute: ["https://push.example/scaduta"] });
  assertEquals(visti.length, 4);
});

Deno.test("solo chi conosce il segreto può lanciare l'invio", () => {
  const segreto = "s3greto-lungo-abbastanza";
  const req = (h?: string) => new Request("https://x", { headers: h ? { authorization: h } : {} });
  assertEquals(autorizzato(req(`Bearer ${segreto}`), segreto), true);
  assertEquals(autorizzato(req("Bearer sbagliato-sbagliato-xx"), segreto), false);
  assertEquals(autorizzato(req(), segreto), false);
  assertEquals(autorizzato(req("Bearer corto"), "corto"), false);
  assertEquals(autorizzato(req(`Bearer ${segreto}`), undefined), false);
});
