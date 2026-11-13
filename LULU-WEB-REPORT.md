# Lulù: web app installabile e APK Android — rapporto

Branch `claude/debug-completo` (nessun push precedente, ma ho tenuto questo nome perché è l'unico
su cui questa sessione è autorizzata a fare push). Niente merge su `main`, niente tag, niente
pubblicazioni.

## ⚠️ Prima di tutto: cosa NON ho potuto eseguire

In questo ambiente **Flutter non si installa**: la rete blocca `storage.googleapis.com` (da dove
Flutter scarica Dart e il motore) e `pub.dev` (pacchetti). Quindi **non ho potuto eseguire
`flutter analyze`, `flutter test`, `flutter build web` né `flutter build apk`.**

Cosa ho fatto al posto loro:

- ho letto il sorgente di **Flutter 3.47.9** (la versione della CI, scaricato da GitHub) per
  verificare le opzioni usate (`--base-href`, `--no-web-resources-cdn`, `--build-name`,
  `flutter_bootstrap.js` personalizzato) e il comportamento del service worker;
- ho letto il sorgente di **share_plus 13.3.1** per il comportamento sul web;
- ho riletto riga per riga tutto il codice Dart cambiato (import, lint, `const`);
- ho provato la parte web con **Playwright** su una build simulata (stessi file di `web/`, con un
  finto `main.dart.js`), servita in una sottocartella `/lulu/`;
- ho controllato la sintassi di `sw.js`, `flutter_bootstrap.js`, dei workflow YAML e degli script.

**Da fare subito:** aprire una PR (o lanciare la CI) così `ci.yml` esegue `flutter analyze`,
`flutter test` e la nuova build web; oppure, in locale, `flutter analyze && flutter test &&
tool/build_web.sh && flutter build apk --release`. Se qualcosa non compila, è con ogni probabilità
in `lib/ui/device_notice.dart`, `lib/store.dart` (tetto foto) o `test/web_pwa_test.dart`.
Per far girare Flutter anche nelle sessioni cloud bisogna consentire nella rete dell'ambiente
`storage.googleapis.com` e `pub.dev`.

## Cosa ho fatto

### 1. Nome: da Zampa a Lulù

- Tutto ciò che vede l'utente: `lib/brand.dart` (da qui il nome arriva in quasi tutte le schermate,
  nel PDF e nei promemoria), testi clinici e traduzioni (`app_it.arb` e file generati),
  `android:label`, nomi su iOS, `web/manifest.json`, `web/index.html`, README, INSTALLA, DOSSIER,
  documenti privacy e clinici, lettera al veterinario. Test e snapshot aggiornati di conseguenza.
- Nomi dei file senza accento, per evitare problemi con email e vecchi sistemi:
  `Lulu_<cane>_<data>.pdf`, `lulu-backup-<data>.json`, `lulu.apk`.
- **Lasciati apposta come «zampa»:** `applicationId`/bundle id `it.zampa.zampa`, nome del
  pacchetto Dart (`package:zampa/…`), chiavi di salvataggio (`zampa_v1`, `zampa_consent_…`) e
  canale notifiche: cambiarle farebbe perdere i dati a chi ha già l'app.
- Lasciati i rapporti storici in `ricerca/` (documentano decisioni passate) e i nomi delle app
  desktop (Windows/macOS/Linux, non più un obiettivo).

**applicationId: conviene cambiarlo?** Sì, ma **solo prima di distribuire l'APK a persone vere**.
Per Android un applicationId diverso è un'app diversa: chi ha installato la vecchia avrebbe due
app, e i dati non passano dall'una all'altra. Oggi, con pochi tester, il costo è minimo; dopo
cresce. Va scelto insieme al marchio definitivo (es. `it.<dominio>.lulu`) e insieme alla chiave di
firma. Il bundle id iOS non serve più (niente App Store). Se decidi, è una modifica di due righe
in `android/app/build.gradle.kts` (`namespace`, `applicationId`) più lo spostamento di
`MainActivity.kt`.

### 2. Web app installabile (PWA)

- `web/manifest.json`: nome e nome breve, descrizione, lingua, `start_url`/`scope` relativi (così
  funziona con qualunque base href), colori del tema, icone normali e **maskable** 192/512.
- `web/index.html`: meta per iPhone (`apple-mobile-web-app-*`, `apple-touch-icon` 180×180),
  `theme-color`, viewport con le aree sicure, schermata «Lulù si sta aprendo…» con tema scuro,
  richiesta di **archiviazione persistente** (riduce il rischio che il browser cancelli i dati).
- **Icone nuove**: prima c'era il logo Flutter predefinito, anche su Android. Ora una zampa in
  pixel art blu/senape (`tool/gen_icons.js` le rigenera). È un segnaposto: l'icona definitiva è
  una scelta di marchio.
- **Uso offline (`web/sw.js`)**: scoperta importante — in Flutter 3.47 il service worker generato
  da Flutter **si disinstalla da solo**, quindi finora l'app web non funzionava offline. Ora:
  `web/flutter_bootstrap.js` non lo registra più, e `sw.js` salva tutti i file dell'app alla prima
  apertura (prima la rete per la pagina, poi la copia salvata; per il resto prima la copia).
  A ogni nuova versione la cache cambia nome (impronta del contenuto) e la vecchia si cancella.
- **CanvasKit dal nostro sito** (`--no-web-resources-cdn`): prima il motore grafico veniva
  scaricato da `gstatic.com` (Google) a ogni avvio; ora viene dal nostro hosting, necessario per
  l'offline e meglio per la privacy.
- **Prova con Playwright (iPhone 13 e Pixel 7, chiaro e scuro, sito in `/lulu/`)**: service worker
  attivo e in controllo, manifest letto, 13 file in cache, **ricarica offline riuscita** (anche
  con un percorso `#/…`), pagina di download senza scorrimento orizzontale a 390 px, sezione
  giusta in evidenza per iPhone e per Android, APK scaricabile, nessun errore in console.
  ⚠️ Con il finto `main.dart.js`: l'app Flutter vera nel browser non l'ho potuta aprire.

### 3. Funzioni che sul web non vanno (controllate una per una)

| Funzione | Sul web / iPhone | Cosa succede ora |
|---|---|---|
| Notifiche (`flutter_local_notifications`) | non esistono | Già disattivate in modo sicuro. **Nuovo:** la Home avvisa una volta che promemoria, dosi e allarmi si vedono solo aprendo l'app, e consiglia Android o «Aggiungi alla schermata Home». Prima l'utente web credeva di essere avvisato. |
| Fuso orario (`flutter_timezone`) | non usato | Chiamato solo se le notifiche sono supportate. Nessun crash. |
| Foto (`image_picker`) | funziona (fotocamera/galleria del browser) | **Bug corretto:** le foto erano salvate in base64 nel localStorage (~5 MB in tutto). Riempito quello, **non si sarebbero più salvati nemmeno cani, diari e terapie**. Ora sul web le foto hanno un tetto di ~1,5 MB con messaggio chiaro; su Android nessun limite. |
| Backup (`share_plus`) | iPhone: foglio di condivisione; computer: scarica il file | Verificato nel sorgente: se la condivisione non c'è, scarica il file. Ok. |
| PDF per il veterinario (`printing`) | scarica il PDF | Ok. |
| Accesso con Apple/Google | sul web usa il reindirizzamento OAuth | Funziona se in Supabase si aggiunge l'indirizzo della web app tra i «Redirect URLs». |
| «Apri Impostazioni» delle notifiche | non esiste | Già escluso sul web. |
| Telefono veterinario/emergenze (`tel:`) | su iPhone apre la chiamata | Ok. |
| Emoji nel testo | il motore le scarica da `fonts.gstatic.com` | Offline al primo uso possono mancare; contatto con Google (vedi decisioni). |

Aggiunto anche **Profilo › Installa Lulù sul telefono** (solo nella web app), che apre la pagina di
download.

**Web Push per i promemoria — proposta, NON implementata.** Si può fare, con questi limiti:
su iPhone funziona solo da iOS 16.4 e solo con l'app **aggiunta alla schermata Home**; il
permesso va chiesto dopo un tocco dell'utente. Serve un piccolo server che invii i messaggi all'ora
giusta, perché il browser non sa programmare notifiche locali come fa Android. Proposta:
1. chiavi VAPID; nel `sw.js` gestione di `push` e `notificationclick`;
2. iscrizione salvata in una tabella Supabase (`push_subscriptions`, legata all'account, quindi
   **solo per chi ha l'account**);
3. l'app invia al server l'elenco dei promemoria già calcolati (stessi testi di Android);
4. una Edge Function Supabase lanciata ogni minuto da `pg_cron` invia quelli scaduti
   (libreria `web-push`).
Costo: gratis nel piano Supabase; 2-4 giorni di lavoro. Implicazioni privacy: i promemoria
(nomi dei farmaci, orari) andrebbero sul server → aggiornare informativa, DPIA e registro.
Alternativa più leggera: notifiche solo mentre l'app è aperta. Decidi tu.

### 4. APK

- `android/app/build.gradle.kts`: firma di rilascio letta da `android/key.properties` (mai nel
  repository, già in `.gitignore`); senza, chiave di debug come prima.
- **`.github/workflows/release.yml`** (a ogni tag `v*`, oppure a mano senza Release): analisi,
  test, APK universale + APK solo 64 bit, web app con l'APK dentro, **GitHub Release** con
  `lulu.apk`, `lulu-universale.apk`, `lulu-web.zip`. Versione presa dal tag, `versionCode`
  crescente. Firma dai segreti `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- `android.yml` produce ora `lulu.apk`/`lulu-arm64.apk`; `ci.yml` compila anche la web app.
- `flutter build apk --release` **non verificato qui** (vedi sopra). In CI su `main` il workflow
  Android lo eseguiva già con successo prima di queste modifiche; i cambi lato Android sono il
  nome, le icone e la firma facoltativa.

### 5. Pagina di download

`web/download.html` (anche da Profilo): pulsante **«Scarica per Android (APK)»** con i passaggi
(consentire l'installazione, Play Protect, notifiche), istruzioni **iPhone** con
«Condividi › Aggiungi alla schermata Home», sezione computer. Mette in evidenza la parte del
telefono in uso, tema chiaro e scuro, testo grande, nessuna dipendenza esterna.

### 6. Hosting

La build è indipendente dall'hosting: `BASE_HREF=/sottocartella/ tool/build_web.sh` (o la
variabile di repository `LULU_BASE_HREF` nel workflow), percorsi tutti relativi, rotte con `#`
(nessuna regola di riscrittura necessaria). Basta caricare il contenuto di `build/web` (o di
`lulu-web.zip`). Serve HTTPS. `web/_headers` imposta la cache giusta per `sw.js` e `index.html`
su Cloudflare e Netlify.

**Proposta: Cloudflare Pages.** Gratis con repository privato, banda illimitata, HTTPS e dominio
personalizzato, legge `_headers`, caricamento anche diretto dello zip (senza collegare GitHub).
Unico limite: **file fino a 25 MiB** → per questo sulla pagina va l'APK solo 64 bit (quasi tutti
i telefoni dal 2017); il workflow avvisa se lo supera.
- *Netlify*: va bene uguale, ma il piano gratuito ha limiti di banda/crediti più stretti e
  scaricare l'APK li consuma.
- *GitHub Pages con repo pubblico*: sconsigliato, renderebbe pubblici codice, ricerche,
  documenti legali e il tuo nome nei documenti privacy.
- Nota: con il repo privato **gli allegati delle GitHub Release non sono scaricabili da chi non
  ha accesso**; per questo l'APK pubblico sta sull'hosting della web app.

## Decisioni che spettano a Lorenzo

1. **Marchio «Lulù»**: `ricerca/13-nome-e-marchio.md` lo dava a **rischio alto** (migliaia di
   marchi «lulu», app omonime, l'accento negli store). Conviene una verifica prima di investirci.
2. **applicationId** definitivo (vedi sopra): meglio deciderlo prima di dare l'APK in giro.
3. **Chiave di firma Android**: va creata una volta (`keytool -genkey …`), salvata in un posto
   sicuro e messa nei segreti di GitHub. Senza, ogni APK della CI ha una chiave diversa e **gli
   aggiornamenti non si installano sopra la versione precedente** (bisogna disinstallare e si
   perdono i dati). Se la chiave si perde, stesso problema.
4. **Hosting** (proposta Cloudflare Pages) e dominio.
5. **Web Push** sì/no (proposta sopra).
6. **Icona** definitiva.
7. **Privacy per il web**: l'informativa parla di dati «sul telefono»; sul web sono nel browser.
   Il motore grafico scarica ancora i caratteri di riserva (emoji) da `fonts.gstatic.com`:
   da citare nell'informativa o da eliminare includendo un font emoji nell'app (+ peso).
8. Indirizzo della web app tra i **Redirect URLs** di Supabase (per Apple/Google sul web).

## Problemi trovati e NON corretti

- **Manca il ripristino del backup.** «Esporta i miei dati» crea il file, ma nell'app non c'è
  un'importazione. Sul web, dove il browser può cancellare i dati, è il rischio più serio.
  Lavoro di qualche ora, con test; non l'ho fatto perché fuori dal compito.
- **Sul web tutti i dati stanno nel localStorage** (limite ~5 MB, cancellabile da Safari dopo
  settimane senza uso se l'app non è sulla Home). Il tetto alle foto protegge i dati di oggi;
  la soluzione vera è IndexedDB per le foto. Da pianificare.
- Il salvataggio principale (`_save` in `store.dart`) non segnala all'utente un eventuale errore
  di scrittura: oggi è improbabile grazie al tetto, ma resterebbe silenzioso.
- Il primo «debug completo» richiesto prima è stato sospeso per il cambio di compito.

## Esito di test e build

| Controllo | Prima | Dopo |
|---|---|---|
| `flutter analyze` / `flutter test` / build web / build APK | non eseguibili qui (Flutter non installabile) | non eseguibili qui: **da far girare in CI** |
| Test nuovi | — | `test/web_pwa_test.dart`: nome, manifest, icone, meta iPhone, service worker, pagina di download, avviso notifiche (3 casi), tetto foto (2 casi) |
| Test aggiornati | — | `privacy_test` (nome backup e informativa), `review3_test` e snapshot dei testi clinici (nome) |
| PWA con Playwright (iPhone 13, Pixel 7, chiaro/scuro, in `/lulu/`) | offline assente (SW di Flutter auto-disinstallante) | SW attivo, 13 file in cache, ricarica offline ok, nessun errore |
| `tool/pwa_finalize.py` su build simulata | — | lista offline corretta (esclude APK, skwasm, mappe), versione scritta in download.html |
| Sintassi JS, YAML dei workflow, script bash | — | ok |
