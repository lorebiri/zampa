# Pellovi — stato dell'app (18 novembre 2026)

Branch `claude/pellovi-unione`: unisce i due blocchi di lavoro finiti, pronto per `main`
(merge **non** fatto, nulla pubblicato).

- `claude/debug-completo`: nome Pellovi, logo C (la P-cane), interfaccia nuova con icone in
  pixel art, compagno tamagotchi, web app installabile (PWA), APK, Web Push, foto sul web,
  controllo dei segreti, pubblicazione su Pages e Releases. Rapporto: `LULU-WEB-REPORT.md`.
- `claude/lulu-previsione-v3` (che contiene la v2): previsione della pipì v2, segnali con
  «Esci adesso», cacca legata ai pasti, piano di uscite, azioni rapide nelle notifiche,
  geofence, esportazione per lo studio, materiali della beta. Rapporti: `ricerca/27`, `ricerca/28`.

**Budget zero.** Pellovi resta gratuita e non costa nulla: solo piano gratuito di Supabase,
GitHub Pages e GitHub Releases. Esclusi: assistente con l'API di Claude, app iOS nativa
(Apple Developer Program), Google Play, Premium, consulenza e deposito del marchio, servizi a
pagamento.

---

## Funzionalità

Per chi non è del mestiere: cosa fa Pellovi oggi.

- **Il tuo cane in un posto solo.** Scheda del cane (età, peso, razza, sesso), cartella
  sanitaria con vaccini, antiparassitari, farmaci e visite, e un PDF da mostrare al veterinario.
- **Quando deve uscire.** Pellovi impara gli orari della pipì e della cacca del tuo cane e ti
  dice quando conviene uscire, con un promemoria qualche minuto prima.
- **Il compagno in pixel art.** Nella pagina Oggi c'è un cagnolino disegnato, personalizzabile
  come il tuo cane, che cambia umore con quello che succede davvero: contento dopo un'uscita
  o un pasto, **impaziente alla porta** quando è ora di uscire o quando hai segnato che ti sta
  chiedendo di uscire, assonnato di notte, preoccupato (e serio) se c'è un avviso di salute.
- **Segnali a un tocco.** Se il cane annusa a terra, gira su sé stesso, va alla porta, guaisce
  o è irrequieto, lo segni con un tocco: compare «Esci adesso» con il compagno alla porta, e
  Pellovi impara quali segnali del tuo cane contano davvero.
- **Avvisi di salute.** Regole riviste da veterinari: se qualcosa nei diari è preoccupante
  (vomito ripetuto, sangue, beve troppo...), Pellovi lo dice chiaramente e suggerisce cosa fare.
- **Pappa e peso.** Porzioni consigliate, pasti, peso nel tempo.
- **Emergenze.** Una pagina con cosa fare subito e chi chiamare.
- **Funziona su Android e su iPhone.** Su Android si installa il file APK; su iPhone (e sul
  computer) si usa dal browser e si aggiunge alla schermata Home. Funziona anche senza rete.
- **Privacy.** Senza account i dati restano sul telefono. Con l'account (gratuito) si
  sincronizzano tra più dispositivi.

### In prova

Funzioni nuove, segnate nell'app con la pillola lilla **IN PROVA**: funzionano, ma vanno
verificate con cani veri nella beta.

| Funzione | Dove | Note |
|---|---|---|
| Nuova previsione della pipì (v2) | Bisogni › Pipì | Unisce tre stime; fiducia detta a parole; il compagno compare impaziente quando è ora di uscire |
| Segnali con «Esci adesso» | Bisogni | Le probabilità di partenza sono ipotesi, poi imparate sul cane |
| Cacca legata ai pasti | Bisogni › Cacca | Regola v3.1 (la v3.0 non aveva superato la verifica, `ricerca/28`) |
| Piano di uscite («quante uscite vuoi fare oggi?») | Bisogni › Pipì | Tiene conto degli orari in cui sei fuori casa |
| Esportazione anonima per lo studio | Bisogni, in fondo | Solo con il consenso «Studio sull'accuratezza» |
| Azioni rapide nelle notifiche («Fatta ✓», «Non ancora») | Android | Non provate su un telefono vero |
| Promemoria Web Push | Web app | Richiede la configurazione di Supabase (sotto) |
| Geofence (uscita da casa) | solo logica | Non è nell'app: manca il pacchetto della posizione |
| Materiali della beta | `ricerca/beta/` | Bozze da rileggere (invito, adesione, consenso, istruzioni) |

---

## Cosa ho fatto nell'unione

- Merge di `claude/lulu-previsione-v3`: nessun conflitto testuale; poi controllo a mano dei punti
  delicati (`potty_screen.dart`, `notifications.dart`, `models.dart`, `store.dart`, test).
  Tutte le funzioni dei due blocchi ci sono.
- **Stile nuovo nelle schede v2/v3** (`lib/ui/potty_v3.dart`): pillola «IN PROVA», margini e
  raggi del design system, compagno in pixel art fermo nelle schede (`PixelDogStill`, niente
  animazione per non consumare batteria).
- **Compagno e previsione insieme** (`lib/ui/avatar.dart`): «impaziente alla porta» scatta
  anche con un segnale segnato da meno di 20 minuti (anche di notte: è il cane a chiedere) e con
  «Esci adesso» della previsione v2. Un allarme serio resta sempre prioritario.
- Avviso «Esci adesso» sul giallo «sole», con il compagno alla porta.
- Testi al femminile per le cagnoline («è andata alla porta», «ascolta lei», «portala fuori»).
- Nome: il file dello studio usa la costante `appFileName` (`pellovi-studio-….json`); i materiali
  della beta e i rapporti dicono «Pellovi» (Lulù resta la mascotte e il cane degli esempi).
  Le chiavi interne di salvataggio (`lulu_…`, `zampa_…`) restano com'erano: cambiarle farebbe
  perdere i dati a chi ha già l'app.
- Budget zero nei documenti: `docs/ASSISTENTE.md` §D2 (assistente escluso, nel codice non c'è
  nulla che lo prepari), `supabase/LEGGIMI.md` (Accedi con Apple escluso), `DOSSIER.md`,
  `LULU-WEB-REPORT.md`, `ricerca/beta/`, note in testa a `ricerca/27`, `28`, `02`, `03`, `08`,
  `13`, `14`, `25`.
- Nuovi test: tre del compagno (`test/tamagotchi_test.dart`) e uno del segnale «Va alla porta»
  con testo al 200% (`test/c2_9_test.dart`).

## Esito di test e build

Eseguiti qui con Flutter 3.47.9 (la versione della CI):

| Controllo | Esito |
|---|---|
| `flutter analyze` | nessun problema |
| `flutter test` | **254 superati**, 22 saltati (i test lenti del banco, tag `banco`, come in CI) |
| `flutter build web` (`tool/build_web.sh`, `BASE_HREF=/zampa/`) | ok; service worker con 32 file per l'uso offline |
| `flutter build apk --release` | ok, `app-release.apk` 72,6 MB (firmato con la chiave di debug: manca la chiave vera, vedi sotto) |
| Playwright sulla web app vera, desktop 1280×900 e iPhone 13, chiaro e scuro | ok: primo avvio, cane di esempio, Bisogni, tocco su «Va alla porta», avviso «Esci adesso» visibile, cacca, piano di uscite, pagina Oggi con il compagno «impaziente alla porta» |

Unico errore in console: il browser blocca lo script di Google Sign-In
(`accounts.google.com/gsi/client`) per la Content Security Policy. Non serve finché Google non è
configurato in Supabase; quando lo si attiva va aggiunto il dominio alla CSP di `web/index.html`.

Screenshot in `docs/design/unione-<desktop|iphone>-<chiaro|scuro>-<oggi|bisogni|segnali|esci-adesso|piano|cacca|compagno>.png`.
Lo script che li rifà: `tool/screens/unione_playwright.js`.

Nota per le prossime sessioni cloud: per la build APK ho aggiunto `dl.google.com` (SDK Android)
alla rete dell'ambiente «zampa».

---

## Passi che restano per pubblicare a costo zero

Tutti gratuiti. Li fa Lorenzo (servono i suoi account).

1. **Merge su `main`** di `claude/pellovi-unione` (dopo averla guardata).
2. **Repository pubblico.** GitHub Pages è gratis solo con il repo pubblico (piano Free). Prima
   segui `docs/PUBBLICARE-IL-REPO.md`: il controllo dei segreti in CI deve essere verde e
   `config/supabase.json` non va mai committato.
3. **Attivare Pages.** Settings › Pages › Source: «GitHub Actions». Il workflow
   `.github/workflows/pages.yml` pubblica a ogni push su `main` su
   `https://lorebiri.github.io/zampa/`.
4. **Chiave di firma Android** (gratis, si fa una volta e non si perde mai):
   ```
   keytool -genkeypair -v -keystore pellovi.jks -alias pellovi \
     -keyalg RSA -keysize 4096 -validity 10000
   base64 -w0 pellovi.jks > pellovi.jks.b64
   ```
   In Settings › Secrets and variables › Actions crea i segreti `ANDROID_KEYSTORE_BASE64`
   (il contenuto di `pellovi.jks.b64`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
   (`pellovi`), `ANDROID_KEY_PASSWORD`. Conserva `pellovi.jks` e le password fuori dal repo
   (per esempio in un gestore di password): senza, gli aggiornamenti dell'APK non si installano
   sopra la versione vecchia.
5. **Prima release.** Un tag `v1.0.0` fa partire `.github/workflows/release.yml`: APK firmato
   su GitHub Releases e web app aggiornata su Pages.
6. **Supabase, piano gratuito** (account e promemoria Web Push; istruzioni in `supabase/LEGGIMI.md`):
   - progetto gratuito, schema e migrazione di sicurezza, accesso con email (codice a 6 cifre);
   - chiavi VAPID: `npx web-push generate-vapid-keys`, poi
     `supabase secrets set VAPID_PUBLIC_KEY=… VAPID_PRIVATE_KEY=… VAPID_SUBJECT=… CRON_SECRET=…`;
   - `supabase functions deploy invia-promemoria --no-verify-jwt`;
   - cron ogni minuto con `pg_cron` e `pg_net` (inclusi nel piano gratuito);
   - nel repo, Settings › Secrets and variables › Actions › **Variables** (sono valori pubblici,
     non segreti): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `VAPID_PUBLIC_KEY` per la build di Pages.
   Attenzione al piano gratuito: il progetto si mette in pausa dopo una settimana senza
   attività (si riattiva dal pannello), e ha limiti di spazio e di funzioni più che sufficienti
   per la beta.
7. **Facoltativo, gratis:** «Continua con Google» (Google Cloud Console, credenziali OAuth senza
   costi) e aggiunta di `accounts.google.com` alla CSP.

**Esclusi: budget zero.** App Store e app iOS nativa (Accedi con Apple, widget iOS, TestFlight),
Google Play (25 $), dominio a pagamento (si usa `lorebiri.github.io`), deposito del marchio e
consulente (la verifica di anteriorità si può fare da soli su TMview), assistente con l'API di
Claude, Premium e qualunque servizio a pagamento.
