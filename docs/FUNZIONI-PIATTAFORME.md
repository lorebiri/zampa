# Lulù: funzioni per piattaforma (blocco B)

Stato **prima** (fino al commit `9d28010`) e **dopo** questo branch. «Web» è il browser del
computer o di Android; «iPhone» è Safari o la web app aggiunta alla schermata Home.
L'app iOS nativa non verrà più distribuita (niente App Store).

Legenda: ✅ funziona · ⚠️ funziona con limiti · ❌ non funziona · 🔜 proposto, da fare.

Nessuna funzione è stata tolta: il codice è lo stesso su tutte le piattaforme, cambia solo
come il sistema la supporta. Verifica fatta leggendo il codice e i plugin. **L'app vera nel
browser non l'ho potuta aprire**, perché in questa sessione Flutter non si installa.

| Funzione | Android (APK) | Web prima | Web dopo | iPhone prima | iPhone dopo |
|---|---|---|---|---|---|
| Cartella sanitaria: vaccini, antiparassitari, visite, esami, scadenze | ✅ | ✅ | ✅ | ✅ | ✅ |
| Prevenzione stagionale per area, rischi di razza | ✅ | ✅ | ✅ | ✅ | ✅ |
| Nutrizione: calorie, porzioni, pasti per età | ✅ | ✅ | ✅ | ✅ | ✅ |
| Allarmi clinici (4 livelli, rivisti da veterinari) **mostrati nell'app** | ✅ | ✅ | ✅ | ✅ | ✅ |
| Allarmi e promemoria **come notifiche ad app chiusa** | ✅ | ❌ in silenzio, l'utente non lo sapeva | ❌ ma con un avviso chiaro · 🔜 Web Push | ❌ in silenzio | ❌ con avviso · 🔜 Web Push (iOS 16.4+, app sulla Home) |
| Terapie: dosi da confermare, «non raddoppiare» | ✅ | ⚠️ solo ad app aperta | ⚠️ idem, con avviso | ⚠️ idem | ⚠️ idem, con avviso |
| Previsione bayesiana di pipì e cacca | ✅ | ✅ | ✅ | ✅ | ✅ |
| Compagno in pixel art | ✅ | ✅ | ✅ | ✅ | ✅ |
| Diari: diabete, epilessia, respiri, qualità della vita, riproduzione | ✅ | ✅ | ✅ | ✅ | ✅ |
| Foto (cane, feci, ferite) | ✅ | ⚠️ potevano riempire la memoria e **bloccare il salvataggio di tutti i dati** | ⚠️ tetto di 1,5 MB con messaggio · 🔜 IndexedDB | ⚠️ come web | ⚠️ come web |
| PDF per il veterinario | ✅ condividi | ✅ scarica | ✅ scarica | ✅ condividi/scarica | ✅ |
| Backup «Esporta i miei dati» | ✅ | ✅ scarica il file | ✅ | ✅ foglio di condivisione | ✅ |
| Ripristino del backup | ❌ manca ovunque | ❌ | ❌ | ❌ | ❌ (da fare, importante sul web) |
| Emergenze: chiama veterinario, pronto soccorso, antiveleni | ✅ | ⚠️ `tel:` dipende dal computer | ⚠️ | ✅ | ✅ |
| Avviso caldo (Open-Meteo) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Account e sincronizzazione Supabase (email con codice) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accesso con Google / Apple | ✅ nativo | ⚠️ reindirizzamento OAuth: serve l'indirizzo nei Redirect URLs di Supabase | ⚠️ idem | ⚠️ idem | ⚠️ idem |
| Uso senza rete | ✅ | ❌ (il service worker di Flutter si disinstalla da solo) | ✅ `sw.js` | ❌ | ✅ |
| Installazione | APK | ❌ manifest generico | ✅ PWA installabile | ⚠️ | ✅ «Aggiungi alla schermata Home» |
| Dati al sicuro nel tempo | ✅ | ⚠️ localStorage | ⚠️ + archiviazione persistente richiesta | ❌ Safari può cancellarli dopo ~7 giorni senza visite se non è sulla Home | ⚠️ avviso di aggiungerla alla Home |

## Web Push per i promemoria (proposto, da implementare)

Lulù calcola già tutti i promemoria (`AppStore` → `PlannedNotification`, con titolo, testo,
orario e flag «esatto»). Su Android li consegna `flutter_local_notifications`. Sul web il browser
non sa programmare notifiche future: serve un server che le invii all'ora giusta.

1. **Chiavi VAPID** (una coppia, la privata solo nei segreti di Supabase).
2. **`web/sw.js`**: eventi `push` (mostra titolo/testo) e `notificationclick` (apre o porta in
   primo piano Lulù).
3. **App (solo web)**: dopo un tocco su «Attiva promemoria», `PushManager.subscribe` con la chiave
   pubblica e salvataggio dell'iscrizione in Supabase. Su iPhone il pulsante compare solo se
   l'app è aperta dalla schermata Home (`display-mode: standalone`); altrimenti spiega come fare.
4. **Tabelle Supabase**: `push_subscriptions` (utente, endpoint, chiavi, dispositivo) e
   `push_queue` (utente, orario, titolo, testo, id stabile), con RLS «solo i propri».
   L'app, invece di chiamare `Notifier.schedule`, sostituisce le proprie righe in `push_queue`
   a ogni ripianificazione (stessa lista e stesso tetto di 60 di oggi).
5. **Edge Function `invia-promemoria`** lanciata ogni minuto da `pg_cron`: prende le righe
   scadute, invia con la libreria `web-push`, cancella le inviate, toglie le iscrizioni scadute
   (risposta 404/410).

Limiti: serve l'account (i promemoria passano dal server); su iPhone solo iOS 16.4+ e con l'app
sulla Home; gli allarmi urgenti arrivano al massimo con un minuto di ritardo. Privacy: nomi dei
farmaci e orari passano dal server UE → aggiornare informativa, DPIA e registro dei trattamenti.
Costo: piano gratuito di Supabase. Stima: 2-4 giorni, con test.

Non l'ho implementato in questa sessione per due motivi. Il codice Dart dell'iscrizione non si
può compilare né provare qui. E l'invio dal server è una scelta di privacy che spetta a Lorenzo.
