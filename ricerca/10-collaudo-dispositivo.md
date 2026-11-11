# 10 — Collaudo su dispositivo (C2-1, parte iOS)

QA su dispositivo, 11/11/2026. Simulatore iPhone 17, iOS 27.2 (UDID 8D8ED71C-…), build di debug da `~/build/zampa`, commit di partenza `e2b7218`.

## Correzione fatta in questo incarico (difetto A1)

**`lib/store.dart`, `planNotifications`, filtro delle terapie (una riga sola, più un commento).** Prima si programmavano le dosi solo per le terapie già iniziate (`isActiveTherapy(now)` richiede `date <= now`). Una terapia inserita con la prima dose nel futuro, per esempio «da stasera alle 20» o «da domani mattina», non riceveva **nessuna** notifica, né la prima dose né le successive. Le notifiche partivano solo se l'utente riapriva l'app dopo l'inizio, e a quel punto la prima dose era già passata.

Ora il filtro include anche le terapie con `date` nel futuro, purché non siano già finite alla data d'inizio:

```dart
(r.isActiveTherapy(now) || (r.date.isAfter(now) && r.isActiveTherapy(r.date)))
```

`nextDose` gestiva già un inizio futuro. Il cambio non tocca `isActiveTherapy`, che resta usata da Home, allarmi e parametri biologici: lì «attiva» deve continuare a voler dire «già iniziata».

**Verifica.** Sul simulatore, prima della correzione: terapia con la prima dose a +8 min, 4 notifiche programmate e **0 dosi**. Dopo la correzione: 11 notifiche programmate, cioè 6 dosi più una conferma, e la prima dose consegnata ad app chiusa (vedi §3). Su `flutter analyze` nessun problema; `flutter test test/` dà 97/97 verdi.

## 1. Come si ripete

Due nuovi test d'integrazione in `integration_test/`:

| File | Cosa fa |
|---|---|
| `device_test.dart` | Accetta l'avvertenza e crea un cane vero (Birba) con i numeri del veterinario. Chiede il permesso delle notifiche e registra una pipì, un antibiotico con la prima dose a +8 min (ogni 12 h) e un vaccino in scadenza fra 5 giorni. Stampa la **tabella degli orari** (`ORARIO|id|quando|priorità|esatta|titolo`) e la confronta con le notifiche in attesa nel sistema. Poi prova il **testo al 200%** su 5 schede ed Emergenze, scorrendo tutto e raccogliendo gli errori di disegno, e il **tema scuro**. Segue la **galleria** (`image_picker`, poi `savePhoto`, poi la rilettura), il **PDF** (`buildPdf`, intestazione `%PDF-`, `Printing.sharePdf`), **`tel:`** e la **mappa**. Alla fine resta in attesa (`>>> FINE PROVE`) per la prova ad app chiusa |
| `persistence_test.dart` | Non cancella nulla. Dopo la chiusura dell'app controlla termini accettati, cane, diario, cartella, foto e notifiche in attesa prima e dopo `load()` |

Procedura (i passi con `>>>` richiedono un'azione fuori da Flutter):

1. `simctl addmedia <udid> foto.jpg`
2. `flutter test integration_test/device_test.dart -d <udid>`. Su `>>> PERMESSO` si fa un touch_path su «Consenti» (201, 546); su `>>> GALLERIA` si tocca una foto nel selettore.
3. Su `>>> FINE PROVE` si ferma il processo `flutter` **per PID** con `kill -9`, poi si esegue `simctl terminate <udid> it.zampa.zampa`. Attenzione: se `flutter test` finisce da solo, **disinstalla l'app** e con lei le notifiche in attesa. Per questo la prova ad app chiusa richiede l'interruzione.
4. All'orario della dose: `simctl spawn <udid> log show --predicate 'process == "SpringBoard" AND eventMessage CONTAINS "it.zampa"'`.
5. `flutter test integration_test/persistence_test.dart -d <udid>`

Avvertenze pratiche:
- `simctl privacy grant photos` **termina l'app** se è in esecuzione: va dato prima di avviare il test.
- Il selettore delle foto (PHPicker) resta su «Loading…» per circa 20-30 s al primo avvio.
- Lo scorrimento dall'alto per aprire il centro notifiche non funziona con le iniezioni di tocchi su iOS 27: la prova della consegna si basa sul log di SpringBoard.

## 2. Matrice delle prove (iOS, simulatore)

✔ fatto e superato · ✘ fatto e fallito · ◐ in parte · — non possibile sul simulatore · ○ non fatto

| Prova (C1-2) | Esito | Note |
|---|---|---|
| a. Primo avvio: avvertenza, cane vero | ✔ | Il cane di esempio era già coperto da `app_test.dart` |
| c. Permesso notifiche iOS | ✔ | Il dialogo compare dopo il primo cane vero; «Consenti» → `checkPermissions` vero. In un'esecuzione il plugin ha risposto `false` mentre SpringBoard registrava «Authorization granted: 1» (vedi C5) |
| c. Dose programmata all'orario esatto, **app chiusa** | ✔ | Dose prevista alle 16:17:00, consegnata alle 16:17:00,104. App terminata alle 16:15:38 (§3) |
| c. Promemoria pipì, scadenze, «nessuna pipì da 24 h» | ◐ | Programmati e presenti fra le notifiche in attesa (11 = 11); consegna non osservata: gli orari sono nelle prossime ore o giorni |
| c. Allarme urgente immediato (`showNow`) | ○ | Non provocato in questa sessione |
| c. Riavvio del dispositivo | ○ | Possibile con `simctl shutdown/boot`, ma il simulatore è condiviso con altri agenti; da fare su telefono vero |
| c. Oltre 64 notifiche (3 cani, 2 terapie) | ○ | Il tetto di 60 è coperto dai test unitari; la prova sul dispositivo resta da fare |
| d. «Chiama il veterinario» (`tel:`) | — | `canLaunchUrl` e `launchUrl` danno `false`: sul simulatore non c'è l'app Telefono. L'app mostra il messaggio di riserva «Chiama il numero …». Da provare su iPhone vero |
| d. Mappa del pronto soccorso | ✔ | `launchUrl` dà `true`: si apre Safari su Google Maps (barra «◀ Zampa» visibile) |
| e. Galleria | ✔ | Foto scelta nel PHPicker, 31 400 byte, salvata e riletta identica, allegata al diario; il permesso non serve («Accesso privato alle foto») |
| e. Fotocamera | — | Il simulatore non ha fotocamera. Da provare su iPhone vero, con il permesso negato e poi concesso |
| f. PDF: generazione | ✔ | 1 pagina A4, 5,9 kB, testo leggibile con `pdftotext`: cartella, grafici 14 giorni, terapia, bisogni, storico. Difetti B2, C3 e C4 |
| f. PDF: condivisione | ◐ | `Printing.sharePdf` risponde `true`, ma il foglio di condivisione non compare nella schermata presa subito dopo. Va guardato a vista su un iPhone, con invio via Mail e WhatsApp |
| g. Persistenza: chiusura e riapertura | ✔ | Dopo `terminate` e riapertura restano termini, Birba, 2 voci di diario, 2 di cartella, la foto e 11 notifiche in attesa |
| g. Aggiornamento sopra la versione precedente | ✔ | App vera (`flutter build ios --simulator`) installata sopra quella di test: dati intatti e notifiche riprogrammate all'avvio |
| g. Esportazione e importazione del backup JSON | ○ | Non provata sul dispositivo |
| h. Tema scuro | ✔ | Il test conferma `Brightness.dark` senza errori. Con `simctl ui appearance dark` l'app vera è scura dopo la riapertura |
| h. Testo al 200% | ◐ | Oggi, Salute, Profilo ed Emergenze senza errori. **Bisogni** e **Nutrizione** vanno in overflow (C1, C2). Con il massimo di sistema (AX-XXXL, circa 310%) la Home resta usabile, ma l'iniziale dell'avatar è tagliata (C6) |
| h. Schermo piccolo (iPhone SE), rotazione | ○ | Non provati |
| i. Prestazioni a freddo | ○ | Non misurate (build di debug, non rappresentativa) |
| l. Account | ○ | Supabase reale non ancora creato |

## 3. Tabella degli orari delle notifiche

Esecuzione delle 16:09 (prima dose a +8 min). Le notifiche programmate sono 11 e quelle in attesa nel sistema altrettante.

| id | Titolo | Previsto | Priorità | Tipo | Consegnato |
|---|---|---|---|---|---|
| 1050 | 💊 Antibiotico di prova per Birba | 11/11 **16:17:00** | 1 dose | esatta | **11/11 16:17:00,104**, app chiusa dalle 16:15:38 (log di SpringBoard: «Adding notification … shouldPresentAlert: 1 hasSound: 1», titolo indicizzato «💊 Antibiotico di prova per Birba») |
| 1097 | 💊 Dose confermata per Birba? | 11/11 18:17 | 1 | esatta | non osservato |
| 1051-1055 | 💊 Antibiotico di prova per Birba | 12/11 04:17, 16:17; 13/11 04:17, 16:17; 14/11 04:17 | 1 | esatta | non osservato |
| 1000 | È quasi ora di uscire con Birba 🐾 | 11/11 circa 19:00 | 3 uscita | non esatta | non osservato |
| 1096 | 🔴 Birba: nessuna pipì da 24 ore? | 12/11, 24 h dopo l'ultima pipì | 0 urgente | esatta | non osservato |
| 1001 | 💉 Tra 3 giorni: Richiamo leptospirosi | 13/11 09:00 | 2 | non esatta | non osservato |
| 1002 | 💉 Oggi: Richiamo leptospirosi | 16/11 09:00 | 2 | non esatta | non osservato |

Ritardo misurato su iOS: **0,1 s** (1 caso). La tabella B3 è avviata; per chiuderla servono più consegne sullo stesso iPhone vero, comprese quelle notturne e dopo un riavvio, e le stesse su Android.

## 4. Difetti

Classi: **A** = un avviso di salute o un'emergenza può non funzionare, oppure si perdono dati; **B** = funzione rotta o dato sbagliato; **C** = estetica o testo.

| # | Classe | Difetto | Riprodurre | Stato / proposta |
|---|---|---|---|---|
| A1 | **A** | Una terapia con la prima dose nel futuro non riceve nessuna notifica | Cartella › Farmaco, ogni 12 h, data e ora d'inizio fra un'ora, poi salva: con `pending()` nessuna 💊 | **Corretto** in `lib/store.dart` (in testa al rapporto) e verificato sul simulatore. Proposta per lo sviluppatore: un test unitario in `test/` («terapia futura → dosi pianificate»), perché il QA non tocca `test/` |
| B1 | B | La Home non mostra la terapia futura fra le terapie attive (stesso filtro `isActiveTherapy`) | Come A1, poi Home | Le notifiche ora partono; resta da valutare se la Home debba mostrare «inizia alle …». Decide lo sviluppatore principale |
| B2 | B | Nel PDF per il veterinario compare «Intervallo tipico tra le pipì da sveglio: 255 min (mediana degli ultimi 14 giorni registrati)» con **una sola** pipì registrata: il valore predefinito è presentato come misurato | Cane nuovo con una pipì, poi Esporta PDF | `pdf_export.dart:239`: mostrarlo solo con almeno N intervalli reali, altrimenti «dati insufficienti». Coerente con la regola 11.3 (niente numeri non misurati) |
| C1 | C | Testo al 200%, scheda Bisogni: il grafico «Ultimi 14 giorni» va in overflow di 46 px in basso; i numeri dei giorni sono tagliati | `device_test.dart`, riga «200% Bisogni» | `potty_screen.dart:136`: altezza fissa di 120 px; renderla proporzionale a `textScaler` |
| C2 | C | Testo al 200%, scheda Nutrizione: le tendine «Tipo di dieta» e «Pasti al giorno» vanno in overflow di 17 px a destra | Riga «200% Nutrizione»; `nutrition_screen.dart:249` e `:259` | `isExpanded: true` sui `DropdownButtonFormField` |
| C3 | C | PDF: «nato il …» anche per una femmina | Birba, femmina, poi PDF | `pdf_export.dart:188` |
| C4 | C | PDF in Helvetica senza Atkinson; il trattino lungo del piè di pagina sparisce («Zampa il 11/11/2026   non sostituisce…») | `pdffonts` e `pdftotext` sul PDF | Già pianificato in C2-9 |
| C5 | C | In un'esecuzione su quattro `requestPermissions()` ha risposto `false` anche se il sistema aveva registrato il consenso (log «Authorization granted: 0» e subito dopo «1») | Non riprodotto in modo stabile | Dopo la richiesta, rileggere sempre lo stato con `refreshAllowed()` invece di fidarsi della risposta: l'avviso «Notifiche spente» della Home lo fa già. Da tenere d'occhio |
| C6 | C | Con il testo al massimo di sistema (AX-XXXL) l'iniziale «B» dell'avatar nella testata della Home è tagliata | `simctl ui content_size accessibility-extra-extra-extra-large` | Limitare la scala del testo dentro l'avatar (`MediaQuery.withClampedTextScaling`) |
| C7 | C | La mappa apre Google Maps sul web; su iPhone sarebbe più diretta Apple Mappe (`maps://?q=…`) o l'app Google Maps, se installata | Emergenze › Cerca pronto soccorso | Proposta, non un guasto |

Nessun difetto A resta aperto sul lato iOS provato.

## 5. Cosa resta da provare

**Su un iPhone vero** (serve il telefono di Lorenzo, con installazione tramite Apple ID gratuito):
- `tel:`: «Chiama il mio veterinario» apre il compositore con il numero giusto;
- fotocamera: permesso negato, poi concesso dalle Impostazioni; foto di feci e lesioni;
- foglio di condivisione del PDF, invio via Mail e WhatsApp, leggibilità sul telefono del veterinario;
- consegna ad app chiusa **dopo un riavvio** del telefono, con modalità Full Immersion e Risparmio energetico; notifiche notturne (dose delle 04:17);
- oltre 64 notifiche: 3 cani, 2 terapie ogni 8 h, piano di prevenzione completo; contare quante restano in attesa;
- iPhone SE o schermo piccolo e rotazione; avvio a freddo in release.

**Su Android** (emulatore API 34 in CI e telefono vero):
- permesso `POST_NOTIFICATIONS` (Android 13+) e sveglie esatte (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`);
- consegna ad app chiusa, dopo un riavvio (`RECEIVE_BOOT_COMPLETED`: le notifiche di `flutter_local_notifications` vanno riprogrammate) e in Doze (`adb shell dumpsys deviceidle force-idle`), con l'orario previsto e quello reale nella stessa tabella del §3;
- A1 sul dispositivo: terapia futura, poi notifiche delle dosi;
- `tel:` e mappa con la visibilità dei pacchetti di Android 11+ (`<queries>` nel manifest);
- fotocamera e galleria (Photo Picker di Android 13+), con permessi negati e poi concessi;
- PDF: generazione e condivisione;
- persistenza, aggiornamento sopra la versione precedente, backup JSON;
- testo al 200% e tema scuro (stessi errori C1 e C2 attesi);
- i due nuovi test d'integrazione dovrebbero girare anche sull'emulatore, con il permesso dato via `adb shell pm grant it.zampa.zampa android.permission.POST_NOTIFICATIONS` invece del tocco.
