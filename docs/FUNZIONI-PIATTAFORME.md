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
| Allarmi e promemoria **come notifiche ad app chiusa** | ✅ | ❌ in silenzio, l'utente non lo sapeva | ✅ **Web Push** (con account; Edge Function + cron) | ❌ in silenzio | ✅ **Web Push** con l'app sulla Home, iOS 16.4+ (con account) |
| Terapie: dosi da confermare, «non raddoppiare» | ✅ | ⚠️ solo ad app aperta | ✅ promemoria via Web Push | ⚠️ solo ad app aperta | ✅ via Web Push (app sulla Home) |
| Previsione bayesiana di pipì e cacca | ✅ | ✅ | ✅ | ✅ | ✅ |
| Compagno in pixel art | ✅ | ✅ | ✅ | ✅ | ✅ |
| Diari: diabete, epilessia, respiri, qualità della vita, riproduzione | ✅ | ✅ | ✅ | ✅ | ✅ |
| Foto (cane, feci, ferite) | ✅ | ⚠️ potevano riempire la memoria e **bloccare il salvataggio di tutti i dati** | ✅ in IndexedDB, senza tetto (ripiego col tetto se IndexedDB manca) | ⚠️ come web | ✅ come web |
| PDF per il veterinario | ✅ condividi | ✅ scarica | ✅ scarica (provato: `Lulu_<cane>_<data>.pdf`) | ✅ condividi/scarica | ✅ |
| Backup «Esporta i miei dati» | ✅ | ✅ scarica il file | ✅ | ✅ foglio di condivisione | ✅ |
| Ripristino del backup | ❌ manca ovunque | ❌ | ❌ | ❌ | ❌ (da fare, importante sul web) |
| Emergenze: chiama veterinario, pronto soccorso, antiveleni | ✅ | ⚠️ `tel:` dipende dal computer | ⚠️ | ✅ | ✅ |
| Avviso caldo (Open-Meteo) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Account e sincronizzazione Supabase (email con codice) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accesso con Google / Apple | ✅ nativo | ⚠️ reindirizzamento OAuth: serve l'indirizzo nei Redirect URLs di Supabase | ⚠️ idem | ⚠️ idem | ⚠️ idem |
| Uso senza rete | ✅ | ❌ (il service worker di Flutter si disinstalla da solo) | ✅ `sw.js` | ❌ | ✅ |
| Installazione | APK | ❌ manifest generico | ✅ PWA installabile | ⚠️ | ✅ «Aggiungi alla schermata Home» |
| Dati al sicuro nel tempo | ✅ | ⚠️ localStorage | ⚠️ + archiviazione persistente richiesta | ❌ Safari può cancellarli dopo ~7 giorni senza visite se non è sulla Home | ⚠️ avviso di aggiungerla alla Home |

## Web Push per i promemoria (fatto)

- **App** (`lib/web/push_client*.dart`, `lib/sync/push_reminders.dart`): sul web la Home dice cosa
  manca (Home su iPhone, account, permesso) e offre «Attiva promemoria»; `AppStore` spedisce al
  server promemoria e allarmi urgenti (questi una volta sola, riprovati se manca la rete).
- **Database** (`supabase/migrations/2026-11-14_promemoria_web.sql`): iscrizioni e coda chiuse
  agli utenti, solo funzioni; 17 test SQL verdi su Postgres 16.
- **Invio** (`supabase/functions/invia-promemoria`): ogni minuto con `pg_cron`, `web-push` con
  chiavi VAPID, scarta le iscrizioni scadute; 3 test Deno e controllo dei tipi.
- **Service worker**: mostra la notifica (gli allarmi restano finché non li tocchi) e al tocco apre
  Lulù. Provato in Chromium consegnando un messaggio push: notifica mostrata.
- **Da fare da Lorenzo**: chiavi VAPID, segreti, deploy e cron (`supabase/LEGGIMI.md` §6); citare
  nell'informativa che i testi dei promemoria passano dal server UE fino all'invio.
- **Non provato qui**: la consegna attraverso i server push veri (Google, Apple, Mozilla), perché il
  Chromium di prova non ha un servizio push funzionante. Va provata su un telefono vero.
