# Informativa privacy di Zampa (versione beta)

> **Stato:** bozza rivista dall'esperto privacy (C2-7, 11/11/2026), da far leggere a un
> legale prima della pubblicazione negli store. Le parti tra `[[ ]]` sono da completare.
> Vale per la **beta** (Italia). Va aggiornata prima del lancio in UE e ogni volta che
> l'app comincia a trattare dati nuovi.

Ultimo aggiornamento: `[[data di pubblicazione]]`

## 1. In breve

- Zampa funziona **senza account**: in questo caso tutto resta sul tuo telefono e noi non
  riceviamo nulla.
- L'**account è facoltativo**. Serve per il backup, per usare più telefoni e per
  condividere il cane con la famiglia. I dati vanno su server in **Germania (Francoforte)**.
- L'**avviso caldo** è facoltativo. Se lo attivi, il nome della città viene mandato al
  servizio meteo Open-Meteo.
- Lo **studio sull'accuratezza** e i **rapporti di errore** sono facoltativi e spenti
  finché non dici di sì. Li puoi spegnere quando vuoi.
- Niente pubblicità, niente profilazione, niente vendita di dati, nessun identificativo
  pubblicitario.
- Zampa **non è un dispositivo medico**: non fa diagnosi e non sostituisce il veterinario.

## 2. Chi è il titolare del trattamento

**Lorenzo Birindelli**, persona fisica, sviluppatore di Zampa come progetto personale.

- Indirizzo: `[[via, numero civico, CAP, città]]`
- Email per la privacy: `[[indirizzo email dedicato, per esempio privacy@dominio-di-zampa]]`

Zampa non è un prodotto del CNR né di altri enti. Il titolare non ha nominato un
Responsabile della protezione dei dati (DPO), perché non è obbligatorio per questo
trattamento (art. 37 GDPR).

## 3. Cosa resta solo sul tuo telefono

Senza account, e anche con l'account per le voci elencate qui sotto, restano **solo sul
telefono**:

- le **foto** allegate al diario (sul server va solo un codice che indica che c'è una
  foto, non la foto);
- le **notifiche e i promemoria**: sono calcolati e programmati sul telefono, non
  passano da un nostro server;
- le **previsioni** (pipì, cacca, avvisi di salute): sono calcolate sul telefono;
- il **PDF per il veterinario** e il **backup JSON**: li crei tu e li mandi tu a chi vuoi.

Senza account, sul telefono restano anche tutti gli altri dati: i cani, il diario, la
cartella sanitaria, il peso, le dosi dei farmaci. Se disinstalli l'app senza account,
questi dati si perdono: fai prima un backup (Profilo › Esporta tutti i dati).

L'app **non usa il GPS** e non chiede il permesso di posizione. Chiede solo:
- le **notifiche**, per i promemoria;
- la **fotocamera** e le **foto**, solo quando scegli di allegare una foto.

## 4. Quali dati trattiamo, perché e su quale base

| Quando | Dati | Perché | Base giuridica (GDPR) |
|---|---|---|---|
| **Account** (facoltativo) | email; identificativo dell'account; se accedi con Apple o Google, l'identificativo che ci passano loro | creare l'account, farti accedere, proteggere l'account | contratto: è il servizio che chiedi (art. 6.1.b) |
| **Account** | i dati dei cani che inserisci: nome, razza, nascita, sesso, peso, microchip, allergie, malattie, alimentazione, città per l'avviso caldo, nome e telefono del veterinario, telefono di emergenza; il diario (pipì, cacca, pasti, passeggiate, sintomi con data e ora); cartella sanitaria, vaccini, esami, farmaci e dosi | backup, uso su più telefoni, condivisione con i familiari che inviti | contratto (art. 6.1.b) |
| **Account** | quale familiare ha scritto una voce, inviti creati e usati, tentativi falliti di usare un codice | condivisione e sicurezza (per esempio, il blocco dopo 5 codici sbagliati in un'ora) | contratto e legittimo interesse alla sicurezza (art. 6.1.b e 6.1.f) |
| **Account** | indirizzo IP e dati tecnici della connessione nei registri del server | sicurezza e funzionamento | legittimo interesse alla sicurezza (art. 6.1.f) |
| **Avviso caldo** (facoltativo) | il nome della città che scrivi e le coordinate della città, cioè il centro del comune, non la tua posizione | ricevere le previsioni meteo | contratto: è una funzione che attivi tu (art. 6.1.b) |
| **Studio sull'accuratezza** (facoltativo) | solo numeri calcolati sul telefono, legati a un codice casuale: vedi `docs/CONSENSO-TELEMETRIA.md` | capire se le previsioni funzionano e migliorarle | **consenso** separato (art. 6.1.a) |
| **Rapporti di errore** (facoltativi) | descrizione tecnica dell'errore: punto del codice, versione dell'app, modello e sistema del telefono | correggere i difetti | **consenso** separato (art. 6.1.a) |

**Dati del cane e dati tuoi.** Le informazioni sulla salute del cane non sono "dati
sanitari" ai sensi del GDPR, che riguardano solo le persone. Le trattiamo comunque con
la stessa cura, perché insieme agli orari delle uscite e alla città possono dire qualcosa
delle tue abitudini.

**Dati di altre persone.** Se scrivi nome e telefono del veterinario o un telefono di
emergenza, inserisci dati di un'altra persona: fallo solo se sai che è d'accordo, e
usa i dati solo per contattarla.

Non usiamo i tuoi dati per decisioni automatiche che abbiano effetti giuridici su di te
(art. 22 GDPR). Le previsioni riguardano il cane e sono solo consigli.

## 5. Chi riceve i dati

Non vendiamo e non cediamo i dati a nessuno. Li ricevono solo:

| Chi | Cosa fa | Dove | Ruolo e garanzie |
|---|---|---|---|
| **Supabase, Inc.** | ospita database e accesso dell'account | dati in **UE, Francoforte** (AWS eu-central-1) | **responsabile del trattamento** (art. 28) con accordo sul trattamento dei dati (DPA). Supabase è un'azienda USA: per gli eventuali accessi dagli USA (per esempio l'assistenza tecnica) valgono le **clausole contrattuali standard** della Commissione europea incluse nel DPA |
| Fornitori di Supabase (sub-responsabili) | per esempio l'invio dell'email con il codice di accesso | `[[da completare dall'elenco dei sub-responsabili di Supabase in vigore]]` | vincolati da Supabase con le stesse garanzie |
| `[[Fornitore SMTP, se Lorenzo ne configura uno proprio]]` | invio dell'email con il codice di accesso | `[[UE]]` | responsabile del trattamento |
| **Sentry** (Functional Software, Inc.), solo se dai il consenso ai rapporti di errore | raccoglie i rapporti di errore | dati degli errori in **UE, Francoforte** | responsabile del trattamento, con DPA e clausole contrattuali standard. Vedi `docs/CRASH-STRUMENTO.md` |
| **Open-Meteo** (OpenMeteo GmbH, Svizzera), solo se attivi l'avviso caldo | restituisce le previsioni meteo per la città | Svizzera, che ha una decisione di adeguatezza dell'UE | riceve la città, le coordinate e l'indirizzo IP del telefono; li tratta secondo la sua informativa e cancella i registri dopo 90 giorni |
| **Apple** o **Google**, solo se scegli di accedere con loro | verificano chi sei | secondo le loro regole | titolari autonomi del trattamento: si applicano le loro informative |
| **I familiari che inviti** | vedono e modificano i dati del cane condiviso | dove si trova il loro telefono | li scegli tu: un invito vale una volta e scade dopo 7 giorni |

## 6. Per quanto tempo

| Dati | Conservazione |
|---|---|
| Dati sul telefono | finché non li cancelli o disinstalli l'app |
| Account e dati dei cani | finché tieni l'account. Se lo elimini, la cancellazione dal database è immediata. Le copie di sicurezza del fornitore si sovrascrivono entro `[[N giorni, da verificare sul piano Supabase scelto]]` |
| Voci eliminate | resta solo un segno "eliminata" senza contenuto, che serve agli altri telefoni per sapere che la voce va tolta |
| Inviti e tentativi falliti | inviti: 7 giorni di validità, poi cancellabili; tentativi: circa 1 giorno |
| Registri tecnici del server (IP) | secondo i tempi del fornitore, `[[da verificare: pochi giorni sul piano scelto]]` |
| Studio sull'accuratezza | fino a 12 mesi dopo la fine della beta, poi restano solo tabelle riassuntive anonime. Se ritiri il consenso: cancellazione entro 30 giorni |
| Rapporti di errore | al massimo 90 giorni, poi cancellati dal fornitore |
| Open-Meteo | 90 giorni nei loro registri |

## 7. I tuoi diritti

Hai diritto di:
- **accedere** ai dati e averne una copia: Profilo › Esporta tutti i dati (JSON);
- **portarli** altrove (art. 20): lo stesso file JSON;
- **correggerli**: direttamente nell'app;
- **cancellarli**: Profilo › Account e famiglia › Elimina account. I dati dei cani di cui
  sei proprietario vengono cancellati anche per i familiari. Puoi anche chiederlo per
  email, senza accedere all'app: `[[email privacy]]` oppure `[[pagina web per la cancellazione]]`;
- **limitare** il trattamento o **opporti** a quello basato sul legittimo interesse;
- **ritirare il consenso** allo studio o ai rapporti di errore in qualsiasi momento, da
  Profilo › Privacy, senza conseguenze sul resto dell'app. Il ritiro non rende illecito
  ciò che è stato fatto prima;
- **fare reclamo** al Garante per la protezione dei dati personali
  (www.garanteprivacy.it) o all'autorità del Paese UE in cui vivi.

Per esercitare i diritti scrivi a `[[email privacy]]`. Rispondiamo entro un mese
(art. 12 GDPR).

## 8. Sicurezza

- Connessioni sempre cifrate (HTTPS/TLS); database cifrato sui server del fornitore.
- Ogni cane è visibile solo ai suoi membri: le regole sono applicate dal database
  (Row Level Security), non solo dall'app, e sono state provate con test automatici.
- Inviti monouso con scadenza decisa dal server; blocco dopo 5 codici sbagliati.
- Nell'app c'è solo la chiave pubblica del servizio, nessuna chiave segreta.

**Attenzione:** il backup JSON è un file con tutti i dati dei tuoi cani. L'app non lo
copia negli appunti: sei tu a scegliere dove salvarlo o a chi mandarlo. Conservalo in un
posto sicuro.

## 9. Età minima

Per creare un account o dare il consenso allo studio devi avere almeno **14 anni**
(art. 8 GDPR e art. 2-quinquies del Codice privacy italiano). Sotto i 14 anni serve
l'autorizzazione di un genitore.

## 10. Modifiche

Se cambiamo questa informativa in modo importante, te lo diciamo nell'app prima che le
modifiche valgano. Se un cambiamento richiede un nuovo consenso, te lo chiediamo di nuovo.
