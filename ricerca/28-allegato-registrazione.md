# 28 — Registrare senza fatica (punto 4)

*13 novembre 2026. Branch `claude/lulu-previsione-v3`. Per chi ha il cane in appartamento senza giardino: ogni uscita è una pipì da segnare, e se segnarla costa fatica il diario si svuota e la previsione peggiora. Qui: cosa è **fatto** (codice e test) e cosa è solo **progettato**.*

---

## 0. In breve

| | Stato |
|---|---|
| **A. Bottoni nella notifica** «Fatta ✓» / «Non ancora» | **Fatto** (Android completo; iPhone app nativa: pronto ma da provare su un iPhone vero, vedi §1.4) |
| **B. Uscita rilevata con il recinto intorno a casa** | **Solo logica** (pura e testata). Manca la lettura della posizione: nessun pacchetto nativo aggiunto |
| **C. Widget Android** | **Solo progetto** (§3) |

### Cosa funziona dove

| Funzione | Android (app) | iPhone come PWA (sito aggiunto alla Home) | Web su computer | iPhone app nativa |
|---|---|---|---|---|
| Notifiche programmate (uscite, dosi, scadenze, pipì mancata) | **Sì** | **No.** Sul web le notifiche programmate locali non esistono; su iPhone le notifiche web arrivano solo con il sito aggiunto alla Home, iOS ≥ 16.4, e solo come *push dal server*: l'app non ha un server di push | **No** (vedi commento in `lib/notifications.dart`): l'app mostra il conto alla rovescia e gli avvisi solo quando è aperta | **Sì** |
| Azioni rapide nella notifica («Fatta ✓», «Non ancora») | **Sì**, anche ad app chiusa, senza aprirla | **No** (non ci sono notifiche) | **No** | **Sì, ma il tocco apre l'app** (scelta voluta, §1.4); da collaudare su dispositivo |
| Widget nella schermata Home | **No, solo progetto** (§3) | **No** (iOS non permette widget ai siti) | **No** | **No** (servirebbe un'estensione WidgetKit in Swift) |
| Uscita rilevata con il recinto (geofence) | **No, solo logica**: manca il pacchetto per la posizione | **No**: il web non può leggere la posizione in background | **No** (non ha senso su un computer) | **No, solo logica** |
| Registrazione con un tocco nell'app | **Sì** | **Sì** (app aperta) | **Sì** | **Sì** |

Su Linux e Windows desktop le notifiche non sono attive: il codice delle azioni non viene mai chiamato e non dà errori.

---

## 1. A — Bottoni nel promemoria della pipì (fatto)

### 1.1 Cosa vede l'utente

Il promemoria «È quasi ora di uscire con Lulù 🐾» ora ha due bottoni:

- **«Fatta ✓»** — registra subito una pipì **fuori casa** (`LogType.pipi`, `indoor: false`) **all'ora del tocco**, per il cane di quella notifica. La notifica sparisce.
- **«Non ancora»** — non registra nulla. Il promemoria torna **tra 15 minuti** con il titolo «Ancora da fare: uscita con Lulù 🐾» e di nuovo i due bottoni. Se nel frattempo si registra una pipì (dall'app o con «Fatta ✓»), il rinvio si annulla e torna il promemoria normale.

Restano **senza bottoni e con i testi di prima**: la notifica di pipì mancata («🔴 … nessuna pipì da N ore?»), le dosi, le conferme delle dosi, le scadenze, gli allarmi immediati e il promemoria della cacca. Tetti (60 notifiche), priorità e testi clinici non cambiano: «Fatta ✓» non tocca né la soglia né il testo dell'urgenza, aggiunge solo una pipì al diario, come se l'utente l'avesse segnata a mano.

### 1.2 Come funziona ad app chiusa: la scelta più sicura

Su Android il bottone non apre l'app: il plugin `flutter_local_notifications` lancia un piccolo motore Dart a parte (isolato in background, funzione `luluNotificationBackground` con `@pragma('vm:entry-point')`).

**Scelta:** l'isolato in background **non apre il diario**. Fa solo due cose:
1. salva il tocco (tipo, cane, ora del tocco, id casuale) in `SharedPreferences`, in **una chiave propria per ogni tocco** (`lulu_qa_<id>`);
2. per «Non ancora», programma subito il promemoria tra 15 minuti (stesso id di notifica, quindi lo sostituisce; puntuale se l'utente ha concesso le sveglie esatte).

Poi avvisa l'app, se è aperta, attraverso una porta tra isolati (`IsolateNameServer`); l'app applica la coda subito. Se l'app è chiusa, la coda si applica **al prossimo avvio** e a ogni ritorno in primo piano.

**Perché così.** Il diario è un unico JSON in `SharedPreferences`. Se l'isolato in background lo aprisse e lo riscrivesse mentre l'app è aperta (su Android i bottoni passano dal background anche con l'app in primo piano), due copie del diario si sovrascriverebbero e **una pipì o un'altra voce andrebbe persa in silenzio**. Con una chiave per tocco nessuno sovrascrive niente: l'isolato scrive solo chiavi nuove, l'app le legge (dopo `reload()`), le applica e cancella **solo quelle applicate**.

**Garanzie** (tutte coperte da `test/quick_actions_test.dart`):
- **idempotente:** la pipì ha id `qa_<id del tocco>`; applicare la coda due volte, o due volte in contemporanea (avviso + ritorno in primo piano), non la duplica (le applicazioni sono messe in fila);
- **conta l'ora del tocco**, non quella in cui si apre l'app; un orario nel futuro (orologio cambiato) diventa «adesso»;
- tocchi per cani cancellati, per il cane di esempio, o più vecchi di 3 giorni: scartati e tolti dalla coda, senza errori;
- payload mancante, rovinato o di un'altra notifica: ignorato.

**Il prezzo, detto chiaro.** Finché l'app non viene riaperta, la pipì segnata con «Fatta ✓» non è ancora nel diario: le notifiche già programmate non si spostano. In pratica l'unico effetto visibile è che la notifica «nessuna pipì da 24 ore?» potrebbe arrivare anche se la pipì era stata segnata dalla notifica, se l'app non viene aperta per un giorno intero. Il testo di quella notifica già dice «Se l'ha fatta, registrala»: è un fastidio, non un rischio. Il contrario (rinunciare a un allarme vero) non può succedere.

### 1.3 Payload della notifica

JSON piccolo e versionato (`ReminderPayload`): `{"v":1,"k":"uscita","need":"pipi","dog":"<id>","name":"<nome>","nid":<id notifica>}`. Il nome serve solo per il titolo del promemoria riproposto in background (dove il diario non si apre). Nessun dato sanitario nel payload.

Il rinvio («Non ancora») è salvato solo sul telefono (`lulu_snooze_v1`), fuori dal backup JSON e dalla sincronizzazione; «Cancella tutti i dati» lo cancella.

### 1.4 iPhone (app nativa)

Bottoni registrati come categoria `lulu_uscita_pipi`. Su iOS l'azione ha l'opzione *foreground*: **il tocco apre l'app**, che applica l'azione subito (anche se era chiusa: si legge `getNotificationAppLaunchDetails`). Così non serve un isolato in background su iOS, che richiederebbe codice Swift in `AppDelegate` per registrare i plugin (`setPluginRegistrantCallback`). **Da fare prima del collaudo su iPhone:** in `ios/Runner/AppDelegate.swift` manca `UNUserNotificationCenter.current().delegate = self`, che il plugin indica come configurazione generale per ricevere i tocchi; non l'ho toccato (fuori dal perimetro di questo lavoro). Non provato su un dispositivo.

### 1.5 File

- `lib/logic/quick_actions.dart` — logica pura: id dei bottoni, payload, tocco in coda, rinvio, `reduceQuickActions` (nessun testo per l'utente: i testi sono in `QuickActionTexts`, in `lib/notifications.dart`, come chiede `l10n_catalog_test`).
- `lib/logic/quick_action_signal*.dart` — avviso tra isolati (su web non fa nulla: lì `dart:isolate` non esiste).
- `lib/notifications.dart` — bottoni Android/iOS, risposta in primo piano e in background, coda in `SharedPreferences`.
- `lib/store.dart` — `snoozes`, `applyQuickActions()`, payload e rinvio in `planNotifications`, cancellazione in `wipe`.
- `lib/main.dart` — collegamento all'avvio e al ritorno in primo piano.
- `android/app/src/main/AndroidManifest.xml` — `ActionBroadcastReceiver` del plugin (necessario per i bottoni).
- `test/quick_actions_test.dart` — 16 test.

**Collaudo su dispositivo ancora da fare:** Android 13/14 con app chiusa, in Doze, dopo un riavvio; build *release* (R8) per verificare che la funzione in background non venga eliminata.

---

## 2. B — Uscita rilevata con il recinto intorno a casa (solo logica)

### 2.1 Regole (`lib/logic/outing_geofence.dart`)

- **Casa:** un punto scelto dall'utente; **raggio** 60 m di base, regolabile tra 40 e 150 m.
- **Posizioni ignorate:** accuratezza peggiore di 100 m, valori non validi, fuori ordine o ripetute.
- **«Uscito»:** quando anche il punto più vicino possibile è fuori (distanza − accuratezza > raggio + 15 m) e si resta fuori **almeno 3 minuti** senza posizioni «dentro» nel mezzo. Orario = prima posizione fuori.
- **«Rientrato»:** **2 posizioni di fila** entro il raggio. Orario = la prima delle due.
- **Isteresi:** le posizioni tra le due soglie non cambiano nulla, così il segnale che balla vicino al portone non crea uscite finte; una sola posizione «dentro» non chiude l'uscita.
- **Suggerimento**, solo a uscita conclusa e tra 3 minuti e 3 ore: «Sei uscito con Lulù alle 07:32 per 20 minuti: ha fatto pipì? cacca?». **Mai registrazione automatica:** il diario si scrive solo se l'utente tocca «Pipì» o «Cacca». Sopra le 3 ore (lavoro, spesa) nessuna domanda.

Il testo della domanda è `QuickActionTexts.outingQuestion` (in `lib/notifications.dart`: sarà mostrata come notifica al rientro). Test: `test/outing_geofence_test.dart` (15 test: soglie, margine di accuratezza, isteresi, rimbalzi, raggio, consenso, privacy).

### 2.2 Privacy

- **Solo con consenso esplicito**, spento di base; l'interruttore lo spegne e **spegnerlo cancella anche il punto casa** (`GeofenceSettings.disabled()`); `active` è vero solo con consenso + interruttore + casa.
- **Tutto in locale:** il punto casa resta solo sul telefono (`toLocalJson`, da non mettere nel backup né nella sincronizzazione); le posizioni servono solo a decidere dentro/fuori e **non si salvano mai**; nello storico va solo l'evento (`OutingEvent`: tipo e orario, nessuna coordinata). Nessuna posizione esce dal telefono.
- Oggi `docs/PRIVACY.md` §3 dice «L'app non usa il GPS e non chiede il permesso di posizione»: resta vero finché la lettura della posizione non è nell'app. **Quando la si aggiunge** bisogna aggiornare l'informativa (§3 e §1), la scheda privacy degli store (Google Play: posizione «in background», con dichiarazione e video; Apple: «Location – Always» con testo di spiegazione) e `ricerca/24`.

### 2.3 Cosa manca per farlo funzionare

Un pacchetto nativo per la posizione o, meglio, per i recinti del sistema (Android `GeofencingClient`, iOS `CLCircularRegion`), che svegliano l'app solo all'attraversamento e consumano poca batteria; poi le posizioni dei primi minuti si passano a `OutingTracker`. Permessi: su Android `ACCESS_FINE_LOCATION` + `ACCESS_BACKGROUND_LOCATION` (richiesta separata, Android 11+); su iOS «Sempre». Stima: 3–5 giorni con collaudo su due telefoni, più la revisione degli store, che per la posizione in background è severa. Sul web e nella PWA su iPhone non si può fare (niente posizione in background).

---

## 3. C — Widget Android (solo progetto)

**Pacchetto consigliato:** `home_widget` (pub.dev, maturo, Android e iOS). L'app scrive i dati del widget in uno spazio condiviso (`HomeWidget.saveWidgetData`) e chiede l'aggiornamento (`HomeWidget.updateWidget`); i tocchi sui bottoni arrivano a Dart con `HomeWidget.registerInteractivityCallback` (callback in background con `@pragma('vm:entry-point')`), quindi si riusa **la stessa coda dei bottoni della notifica** (§1.2): nessun accesso al diario dal background.

**Contenuto** (widget 4×2, testo grande, contrasto come in `ricerca/16`):
- riga 1: «Prossima uscita verso le 15:10» (dal piano dei promemoria; se c'è un rinvio, l'orario del rinvio), nome del cane;
- riga 2: tre bottoni **Pipì** · **Cacca** · **Segnale** («Segnale» = il cane chiede di uscire: apre l'app sulla registrazione, perché serve scegliere cosa);
- Pipì e Cacca registrano fuori casa all'ora del tocco, con un breve «Registrata ✓» sul widget.
- Più cani: il widget mostra il cane scelto quando lo si aggiunge (configurazione) o quello selezionato nell'app.

**Cosa serve in `android/`:** una classe Kotlin `AppWidgetProvider` (o `GlanceAppWidget` con Jetpack Glance) che legge i dati salvati da `home_widget`; un layout XML (o Glance); `res/xml/lulu_widget_info.xml` (dimensioni, aggiornamento); il `<receiver>` del provider nel manifest con `android.appwidget.action.APPWIDGET_UPDATE`; il receiver di `home_widget` per i tocchi in background.

**Aggiornamento:** a ogni salvataggio dello store (come `_reschedule`) e a ogni avvio; Android limita gli aggiornamenti periodici a 30 minuti, quindi l'orario lo calcola l'app, non il widget.

**Stima:** 2–3 giorni per Android (provider, layout, collegamento, test su 2–3 launcher). iPhone: estensione WidgetKit in Swift con App Group, altri 2–3 giorni; nessun widget per la PWA.

---

## 4. Esito dei controlli (13/11/2026)

- `flutter analyze`: pulito per i file di questo lavoro (resta solo un'indicazione di stile in `ricerca/analisi/banco_v3.dart`, lavoro in parallelo).
- `flutter test -j 4`: 198 superati, 22 saltati, 1 fallito: `l10n_catalog_test` segnala testi in `lib/logic/outing_plan.dart` («rischio basso»…), file nuovo del lavoro in parallelo sulla previsione, non di questo. I testi di questo lavoro stanno in `lib/notifications.dart` (`QuickActionTexts`), non in `lib/logic/`. Nuovi: `test/quick_actions_test.dart` (16) e `test/outing_geofence_test.dart` (15), tutti superati.
