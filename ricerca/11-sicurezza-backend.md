# 11 — Sicurezza del backend (Supabase / Postgres)

Incarico C1-4 di `ricerca/08-piano-ceo.md`. Data: 10 novembre 2026.
Autore: revisore di sicurezza del backend.

In breve: lo schema della versione 1 aveva un difetto **critico**: un familiare poteva
intestarsi il cane e poi espellere il proprietario. C'erano anche difetti **alti**: inviti
riutilizzabili all'infinito, scadenza decisa dal telefono, nessun limite ai tentativi,
funzioni eseguibili da utenti non autenticati.

Tutti questi difetti sono corretti in `supabase/schema.sql` e nella migrazione
`supabase/migrations/2026-11-10_sicurezza.sql`. I 79 test SQL sono verdi, sia sullo schema
nuovo sia sulla versione 1 migrata.

Restano da fare richieste nell'app (`lib/sync/`). Le più importanti sono due:
- il cane di esempio finisce online;
- all'uscita dall'account, i dati restano sul telefono e vengono caricati nell'account
  successivo.

---

## 1. Come è stato provato

- **Ambiente:** Postgres 16.15 (Homebrew) in locale, senza Docker, nessun progetto cloud e
  nessuna credenziale.
- **Supabase simulato** (`supabase/tests/00_supabase_simulato.sql`):
  - ruoli `anon`, `authenticated` e `service_role`;
  - `auth.users`;
  - `auth.uid()`, che come in Supabase legge `request.jwt.claim.sub`;
  - i **privilegi predefiniti di Supabase**: `anon` e `authenticated` ricevono tutti i
    privilegi su tabelle e funzioni di `public`. È lo scenario peggiore realistico.
- **Test** (`supabase/tests/01_sicurezza.sql`): 79 asserzioni in stile TAP. Ogni utente è
  simulato come fa PostgREST, con `set role authenticated` e il `sub` del JWT.
- **Esecuzione:** `supabase/tests/esegui.sh` (istruzioni in testa al file). Fa quattro
  verifiche:
  1. `schema.sql` eseguito **due volte** su un database vuoto, poi i test;
  2. lo schema v1 (dal primo commit) con dei dati, poi la migrazione eseguita **due volte**,
     poi gli stessi test; i dati della v1 vengono conservati;
  3. la struttura del database nuovo e di quello migrato è **identica** (confronto con
     `pg_dump -s`);
  4. la migrazione coincide con la sezione 2 di `schema.sql`, così le due non possono
     divergere.

```
PGPORT=54329 supabase/tests/esegui.sh
== 1. Schema da zero (eseguito due volte) + test
# 79 test, 79 superati, 0 falliti
== 2. Schema versione 1 + dati + migrazione (eseguita due volte) + test
dati della v1 conservati: 1
# 79 test, 79 superati, 0 falliti
== 3. Struttura: schema da zero e schema migrato devono coincidere
ok - identiche
== 4. La migrazione coincide con la sezione 2 di schema.sql
ok - coincidono
== Tutto verde
```

Limite onesto: questa **non** è la piattaforma Supabase vera. Ci sono tre differenze:
- i ruoli interni non sono gli stessi;
- `auth.users` ha molte più colonne;
- non c'è PostgREST.

Il comportamento delle regole RLS e dei permessi è quello di Postgres, quindi è affidabile.
Su Supabase vanno comunque ripetute alcune prove a mano (sezione 6, punto 13).

## 2. Esito dei test (79/79 verdi)

| Area | Cosa verificano | Esito |
|---|---|---|
| Estraneo | Non legge cani, voci, membri e inviti. Non modifica, non mette lapidi, non inserisce, non fa upsert su voci altrui, non crea inviti, non toglie membri, non fa delete diretti. I dati restano intatti. | verde |
| anon | Nessun accesso alle tabelle. Non esegue `accept_invite`, `delete_my_account` né `is_member`. | verde |
| Permessi | Nessun `TRUNCATE` (che ignorerebbe RLS). La tabella dei tentativi non è accessibile. anon non esegue alcuna funzione di `public`. Le funzioni dei trigger non sono eseguibili. RLS è attiva su tutte le tabelle. | verde |
| Proprietario | Un familiare non si intesta il cane. Ci sono tre difese, ognuna provata da sola: permesso di colonna, trigger, `with check`. Non cambia l'id. Può aggiornare i dati. | verde |
| Eliminazione da familiare | Se un familiare mette la lapide sul cane, esce dalla condivisione. Il cane resta intatto per il proprietario. | verde |
| Membri | Un familiare non toglie altri familiari né il proprietario. Il proprietario non può togliersi, ma può togliere un familiare. Un familiare può uscire. | verde |
| Inviti | Scadenza (7 giorni) e usi (1) li decide il server. Un codice malformato è rifiutato. Il codice è **monouso**: un secondo utente è rifiutato. Chi è già membro può ripetere il codice. L'invito registra chi l'ha usato. Un invito scaduto è rifiutato. Massimo 10 inviti attivi per cane. `create_invite` funziona. | verde |
| Tentativi | Dopo 5 tentativi falliti in un'ora l'utente è bloccato, anche con un codice valido. Dopo un'ora può riprovare. | verde |
| Voci | Non si spostano su un altro cane e non cambiano tipo. `data` deve essere un oggetto, con `id` e `dogId` coerenti con la riga, e non oltre 256 KiB. Le lapidi non conservano i dati. | verde |
| Orari e autore | `updated_at` lo assegna il server, all'inserimento e alla modifica (date passate e future ignorate). `updated_by` lo assegna il server. | verde |
| `delete_my_account` | L'utente sparisce, con i suoi cani, le voci e gli inviti. Il cane condiviso da altri resta intatto. Le voci che aveva scritto lì restano senza autore. Non resta traccia tra membri e tentativi. | verde |
| `security definer` | Tutte hanno `search_path` vuoto. Un `search_path` ostile del chiamante, con una falsa `dog_members`, non inganna `is_member`. | verde |

### Prova dei difetti sulla versione 1 (stesso ambiente)

Sequenza eseguita sullo schema v1, prima delle correzioni:

```
invito che scade nel 2100 accettato: 2100-01-01
updated_by falsificato: ...000d            (A firma a nome di D)
B accetta: rex
owner dopo update di B: ...000b            (B si è intestato Rex)
D riusa lo stesso codice: rex              (invito riutilizzabile)
membri dopo che B toglie A: b/famiglia,d/famiglia   (A espulso dal proprio cane)
TRUNCATE da authenticated riuscito, voci rimaste: 0
anon può eseguire: touch_updated_at, is_member, add_owner_membership, accept_invite
```

Lo schema v1 si esegue senza errori su Postgres 16: il problema non era la sintassi.

## 3. Difetti dello schema e correzioni

| # | Gravità | Difetto (v1) | Correzione |
|---|---|---|---|
| S1 | **Critica** | `dogs_update` non aveva `with check`. In Postgres il `using` vale anche per la riga nuova, quindi un familiare poteva fare `update dogs set owner = sé`. Diventato proprietario, `members_delete` gli permetteva di togliere il vero proprietario: furto completo del cane e dei suoi dati. | Tre difese indipendenti. (1) `authenticated` può aggiornare solo le colonne `data`, `updated_at` e `deleted`. (2) Il trigger `guard_dog_update` vieta il cambio di `owner` e di `id`. Solo l'amministratore (SQL Editor o `service_role`, dove `auth.uid()` è vuoto) può trasferire la proprietà. (3) `with check (is_member(id) and owner = dog_owner(id))`. |
| S2 | Alta | Gli inviti erano riutilizzabili all'infinito fino alla scadenza. | Colonne `max_uses` (1), `uses`, `used_by` e `used_at`. `accept_invite` blocca la riga (`for update`) e consuma il codice. |
| S3 | Alta | Scadenza e codice li decideva il telefono: un invito poteva valere fino al 2100. | Il trigger `guard_invite` impone `created_by`, scadenza a 7 giorni e `max_uses` = 1. Il formato del codice è controllato con un vincolo. Massimo 10 inviti attivi per cane. Nuova RPC `create_invite(dog_id)` con codice generato dal server (40 bit casuali). |
| S4 | Alta | `accept_invite` non aveva limiti ai tentativi. | Tabella `invite_attempts`, con RLS e senza permessi per gli utenti: massimo 5 tentativi falliti all'ora per utente. Un codice non valido restituisce `NULL` invece di un errore: un errore annullerebbe anche la registrazione del tentativo. Questo **cambia il contratto con l'app** (richiesta A3). |
| S5 | Alta | In Postgres le funzioni sono eseguibili da `PUBLIC` per default, e Supabase concede tutto ad anon. anon poteva chiamare `accept_invite` e `is_member`. | `revoke` da `public` e `anon` su ogni funzione. `grant` ad `authenticated` solo per le RPC e gli helper delle regole. Le funzioni dei trigger non sono eseguibili da nessuno. |
| S6 | Media | Le funzioni `security definer` avevano `search_path = public` (`delete_my_account`: `public, auth`). | `set search_path = ''` e nomi completi ovunque. Verificato con un test di dirottamento. |
| S7 | Media | Privilegi predefiniti di Supabase: `TRUNCATE` (che non rispetta RLS), `REFERENCES` e `TRIGGER` per anon e authenticated. Tramite l'API REST `TRUNCATE` non è raggiungibile, quindi il rischio è basso, ma è una difesa in meno. | `revoke all` e poi `grant` minimi per ogni tabella. anon non ha nulla. |
| S8 | Media | `updated_by` lo sceglieva il telefono: si poteva firmare a nome di altri. | Il trigger `guard_entry` lo imposta a `auth.uid()`. Bug trovato dai test e corretto: durante `delete_my_account`, l'`on delete set null` rimetteva l'autore eliminato. Ora il trigger agisce solo sulle scritture dirette (`pg_trigger_depth() = 1`). |
| S9 | Media | Una voce poteva essere spostata su un altro cane o cambiare tipo. `data` poteva contenere un `id` o un `dogId` diverso da quello della riga. L'app applica i dati ricevuti usando gli id dentro `data`, quindi un familiare malevolo poteva far comparire voci nel cane sbagliato sul telefono di un altro. | `dog_id`, `kind` e `id` non si cambiano (trigger). Vincoli `data ->> 'id' = id` e `data ->> 'dogId' = dog_id`; con le lapidi i dati sono vuoti. |
| S10 | Media | `data` poteva essere un array o un numero: `(r['data'] as Map)` fa fallire la sincronizzazione di **tutta la famiglia**. Nessun limite di dimensione. | Vincoli `jsonb_typeof(data) = 'object'` e 256 KiB per riga. |
| S11 | Media | Un familiare che eliminava il cane sul telefono metteva la lapide per tutti: il cane spariva anche dal telefono del proprietario. | Se chi mette la lapide non è il proprietario, il trigger lo fa uscire dalla condivisione e non tocca il cane. |
| S12 | Bassa | Il proprietario poteva togliersi da solo dal proprio cane, che restava orfano e invisibile. | `members_delete`: un familiare può uscire. Il proprietario può togliere gli altri ma non sé stesso. |
| S13 | Bassa (GDPR) | Le lapidi conservavano tutti i dati della voce eliminata. | Il trigger `minimize_tombstone` svuota `data` quando `deleted = true`. |
| S14 | Bassa | `updated_at` era già assegnato dal server (verificato). | Confermato dai test, nessuna modifica. |
| S15 | Bassa | Gli inviti non si potevano revocare. Mancavano gli indici per `memberDogIds` e per la ricezione. | Regola `invites_delete` (per il creatore o il proprietario). Indici su `dog_members(user_id)`, `entries(updated_at)` e `invites(dog_id)`. |

Note sulle correzioni:
- **Vincoli `not valid`:** quelli sui dati non ricontrollano le righe già presenti, quindi la
  migrazione non può fallire su dati vecchi. Valgono per ogni riga nuova o modificata.
- **Transazione unica:** tutto lo script è in `begin … commit`. Se fallisce, non resta nulla
  a metà.
- **Passaggio di proprietà:** non esiste ancora una funzione per l'app. Se serve (per esempio
  quando il proprietario elimina l'account), è una decisione di prodotto. Oggi
  `delete_my_account` cancella i cani anche per i familiari: è scritto nel dialogo dell'app.

## 4. Revisione di `lib/sync/` (solo lettura): richieste allo sviluppatore principale

Priorità: **P0** prima di attivare gli account per chiunque; **P1** prima della
pubblicazione; **P2** presto; **P3** quando possibile.

| # | Pri. | Dove | Problema | Correzione proposta |
|---|---|---|---|---|
| A1 | **P0** | `lib/store.dart:798` (`loadDemo`), `lib/store.dart:165` (`syncItems`) | **Il cane di esempio finisce online.** "Luna" è un `Dog` normale, con un microchip finto (`380260000123456`) e due settimane di diario. Appena l'utente accede, `syncItems` lo include e il motore lo carica nel suo account. Da lì si può anche condividere. | Segnare il cane di esempio (campo `demo: true` in `Dog`, oppure id con prefisso `demo-`) e **escluderlo** in `syncItems()`, con le sue voci. In alternativa, all'accesso chiedere "Vuoi caricare anche Luna (esempio)?". Aggiungere un test in `test/sync_test.dart`. |
| A2 | **P0** | `lib/sync/sync_engine.dart:141-147` e `:128-134` (`reset`), `lib/store.dart:264` (`afterSignOut`), `lib/ui/account_screen.dart:342-345` | **Uscita dall'account e cambio di utente.** Con "Tieni sul telefono", `reset()` dimentica utente, ombra e proprietari. All'accesso successivo **tutti** i dati locali vengono caricati nel nuovo account, inclusi i cani che altri avevano condiviso con il vecchio utente. È un problema di privacy: i dati del familiare finiscono nell'account di uno sconosciuto se il telefono passa di mano. Per i cani altrui l'`insert` fallisce per chiave duplicata, e **la sincronizzazione si blocca per sempre**: `insertDogs` invia tutto in un'unica richiesta. Il commento alla riga 141 descrive questo comportamento come voluto. | Quando si esce tenendo i dati: (a) togliere dal telefono i cani di cui l'utente **non** era proprietario (`ownerOf(id) != uid`); (b) per i cani propri, ricordare l'utente d'origine. All'accesso con dati locali senza stato di sincronizzazione, chiedere: "Caricare N cani nel tuo account?". Se l'account è diverso dall'originale, rigenerare gli id (copia) invece di riusarli. |
| A3 | **P1** | `lib/sync/supabase_backend.dart:140-143` | Con lo schema nuovo, `accept_invite` restituisce `NULL` per un codice non valido, scaduto o già usato. `as String` lancia un `TypeError` e l'utente vede un messaggio incomprensibile. | `final r = await client.rpc(...) as String?; if (r == null) throw Exception('Codice non valido, scaduto o già usato');`. Gestire anche il messaggio "Troppi tentativi…" (`PostgrestException.message`). Il finto backend in `test/sync_test.dart:91` va allineato. |
| A4 | **P1** | `lib/sync/sync_engine.dart:168-179` | **Conflitti dopo un reset.** Con l'ombra vuota, ogni oggetto locale risulta "modifica in attesa". Le modifiche fatte nel frattempo dai familiari sul server vengono **ignorate e sovrascritte** dalla copia vecchia del telefono. | Se l'ombra è vuota e il server ha l'oggetto, considerare in attesa solo gli oggetti **assenti** dal server. Per quelli presenti vince il server, oppure si chiede all'utente. |
| A5 | **P1** | `lib/sync/sync_engine.dart:179` e `:248-255`; `supabase_backend.dart:90-121` | **L'ultima scrittura vince, sull'oggetto intero.** Due telefoni che modificano lo stesso cane o la stessa voce: vince chi invia per ultimo, e l'altra modifica si perde in silenzio. Il server non sa su quale versione si basava il telefono. | Concorrenza ottimistica: inviare l'`updated_at` di base (già ricevuto) e aggiornare con `.eq('updated_at', base)`; se non risulta nessuna riga, riscaricare e riapplicare. Per i cani, valutare l'unione campo per campo. Lo schema supporta già questo schema di lavoro: `updated_at` lo assegna il server. |
| A6 | **P1** | `lib/sync/supabase_backend.dart:90-102` (`updateDogs`) | Un `update` bloccato da RLS non dà errore: aggiorna zero righe. L'ombra viene comunque aggiornata, quindi la modifica **non verrà mai più inviata** e nessuno se ne accorge. | Usare `.update(...).eq('id', id).select('id')` e, se la lista è vuota, lanciare un errore oppure togliere il cane dall'ombra. Così si riprova o si ricarica. |
| A7 | **P1** | `lib/models.dart:4-6` (`newId`) | Gli id sono prevedibili: microsecondi in base 36 più un contatore. Due utenti possono generare lo stesso id. Allora l'`insert` del cane fallisce per chiave duplicata, oppure l'upsert della voce urta la voce altrui (errore RLS), e la sincronizzazione resta bloccata. L'id rivela anche l'ora di creazione. | UUID v4 casuali per i nuovi oggetti (pacchetto `uuid`, oppure 16 byte da `Random.secure()`). Gli id esistenti restano validi. |
| A8 | P2 | `lib/sync/sync_engine.dart:225-247` | Quando un **familiare** elimina un cane condiviso, il motore manda la lapide del cane e di **tutte** le sue voci. Ora il server trasforma la lapide del cane in "esci dalla condivisione". Le lapidi delle voci, inviate subito dopo, falliscono una volta per RLS (non è più membro): un errore passeggero, poi si risolve. | Se `ownerOf(dogId) != uid`, chiamare `backend.leaveDog(dogId)` e togliere dall'ombra le chiavi di quel cane, senza mandare lapidi. Nell'interfaccia, per i cani condivisi, mostrare "Smetti di condividere" invece di "Elimina". |
| A9 | P2 | `lib/sync/supabase_backend.dart:66-75` (`pullEntries`) | Paginazione con `range` su `order('updated_at')`. Molte righe hanno lo stesso `updated_at` (un upsert da 500 righe ha un solo `now()`), e le righe modificate durante la paginazione si spostano in fondo. Il risultato può **saltare righe** al confine tra due pagine. La finestra di 2 minuti non basta se la riga saltata è più vecchia. | Paginazione per chiave: `order('updated_at').order('id')`, poi chiedere le righe successive alla coppia (`updated_at`, `id`) dell'ultima ricevuta. In alternativa, ordinare anche per `id` e ripartire dall'ultimo `updated_at` ricevuto, meno 1 µs. |
| A10 | P2 | `lib/sync/sync_engine.dart:182`, `lib/store.dart:186-206` (`applyRemote`) | `Dog.fromJson` o `LogEntry.fromJson` su dati malformati (scritti da un familiare con un client modificato) lanciano un'eccezione, e la sincronizzazione si blocca per tutta la famiglia. Ora il server limita forma e id, ma non i tipi dei campi. | Avvolgere ogni `applyRemote` in un `try/catch`: saltare la riga e registrarla, senza interrompere la sincronizzazione. |
| A11 | P2 | `lib/sync/supabase_backend.dart:124-137` | Il codice d'invito è generato sul telefono. Ora il server impone scadenza e usi, ma non la casualità del codice. | Usare `client.rpc('create_invite', params: {'p_dog_id': dogId})`, già pronta nello schema. |
| A12 | P2 | `lib/sync/supabase_backend.dart:146-150`, `lib/ui/account_screen.dart:283-290` | Per il **proprietario**, "Smetti di condividere" non fa nulla: il server ora vieta che si tolga, e prima il cane restava orfano. Il messaggio di successo viene mostrato comunque. | Mostrare il pulsante solo se `ownerOf(dog.id) != uid`. Al proprietario offrire "Togli un familiare" o "Elimina il cane". |
| A13 | P3 | `lib/store.dart:151-160`, `lib/sync/sync_engine.dart:138` | **Errori.** Il testo grezzo dell'eccezione finisce in `lastSyncError` e viene mostrato. Non c'è un nuovo tentativo con attesa crescente. Non si distinguono la rete assente e la sessione scaduta (401). Se si modifica qualcosa mentre una sincronizzazione è in corso, `sync()` restituisce `null` e la modifica parte solo alla modifica successiva. | Messaggi in italiano per i casi noti: rete, sessione scaduta, troppi tentativi, codice non valido. Nuovo tentativo dopo 3, 10, 30 e 60 s. Un flag "di nuovo" per rilanciare `sync()` quando finisce quella in corso. |
| A14 | P3 | `lib/sync/supabase_backend.dart:82, 97, 115-116` | Inviano `updated_at` e `updated_by`, che il server ora ignora e riscrive. | Si possono togliere; nessun impatto sulla sicurezza. |
| A15 | P3 | `lib/sync/supabase_backend.dart:165-166` | Nell'alfabeto del nonce Apple manca la lettera `W` (`…UVXYZ…`). È innocuo: 63 simboli su 32 caratteri bastano. | Correzione cosmetica. |

**Chiavi** (punto richiesto dal piano): sono lette solo a compilazione. Va bene così.
- **Dove:** `String.fromEnvironment`, in `lib/sync/supabase_backend.dart:17-18`; usate in
  `lib/main.dart:24-30`.
- **Da dove:** arrivano da `config/supabase.json`, che è escluso da git (`.gitignore:51`). Nel
  repository non ci sono segreti.
- **Chiave pubblica:** la chiave *publishable/anon* è pubblica per natura, si può estrarre
  dal binario. È accettabile proprio perché la sicurezza sta in RLS e nei permessi corretti
  sopra.
- **Regola:** non mettere **mai** la chiave `service_role` (o *secret*) in
  `config/supabase.json` né in altri file dell'app.

**Uscita dall'account** (punto richiesto dal piano):
- con "Cancella dal telefono" i dati locali vengono cancellati (`wipe()`);
- con "Tieni sul telefono" restano tutti, **compresi i cani condivisi da altri**: richiesta A2;
- l'uscita da Google è gestita;
- la sessione di Supabase viene chiusa solo su questo dispositivo.
- Dopo `delete_my_account` il token resta valido fino alla scadenza (di norma un'ora), ma
  non serve più a nulla: l'utente non esiste.

## 5. File consegnati

- `supabase/schema.sql`: schema corretto, rieseguibile e in una sola transazione. Sezione 1:
  tabelle v1. Sezione 2: sicurezza.
- `supabase/migrations/2026-11-10_sicurezza.sql`: migrazione dalla v1, rieseguibile.
  Coincide con la sezione 2 dello schema, e `esegui.sh` lo controlla.
- `supabase/tests/00_supabase_simulato.sql`: ambiente Supabase minimo.
- `supabase/tests/01_sicurezza.sql`: 79 test.
- `supabase/tests/esegui.sh`: esecuzione completa (schema nuovo, migrazione, confronto).
- `supabase/LEGGIMI.md`: aggiornato (migrazione, test, inviti monouso).

Il server Postgres di prova gira solo nella cartella temporanea della sessione. Per rifare
le prove bastano `brew install postgresql@16` e le istruzioni in testa a `esegui.sh`.

## 6. Checklist di produzione per Lorenzo

Le configurazioni le fai tu nel pannello di Supabase. Io non ho toccato nessun progetto.

1. **Regione UE.** Il progetto va creato in *Central EU (Frankfurt)*. La regione non si
   cambia dopo: se il progetto esiste già altrove, va ricreato.
2. **DPA.** Firma il Data Processing Addendum di Supabase. Si trova tra i documenti legali
   dell'organizzazione nel pannello; verifica la voce esatta. Conserva la copia firmata.
   Supabase è un'azienda USA: nell'informativa privacy (`docs/PRIVACY.md`) indica Supabase
   come responsabile del trattamento e le garanzie per il trasferimento (clausole
   contrattuali standard del DPA).
3. **Schema.** Esegui `schema.sql` su un progetto nuovo, oppure la migrazione se c'è già la
   v1. Prima prova `supabase/tests/esegui.sh` in locale.
4. **Password compromesse.** Attiva *Leaked password protection* in Authentication. L'app non
   usa password (codice via email, Apple, Google), ma l'opzione protegge da account creati
   con password tramite l'API. Meglio ancora: **disattiva l'accesso con password** se non
   serve, e lascia solo il codice OTP.
5. **Limiti sulle email.** L'SMTP predefinito di Supabase ha limiti molto bassi e non è
   pensato per la produzione. Configura un **SMTP tuo** (provider UE, con SPF/DKIM/DMARC sul
   dominio). Poi imposta in *Rate Limits* i limiti per invio di email/OTP e verifica, per
   esempio qualche invio all'ora per indirizzo. Controlla anche la durata (es. 10 minuti) e
   la lunghezza del codice OTP.
6. **CAPTCHA / anti-abuso.** Attiva la protezione CAPTCHA in Authentication (hCaptcha o
   Cloudflare Turnstile). **Attenzione:** l'app deve poi passare il `captchaToken` a
   `signInWithOtp`. Senza questa modifica, l'accesso via email smette di funzionare. Va
   coordinato con lo sviluppatore principale: attivalo solo insieme alla nuova versione
   dell'app.
7. **Accessi.** Disattiva i provider non usati e gli *anonymous sign-ins*. Imposta *Site URL*
   e *Redirect URLs* solo sui valori dell'app.
8. **Backup e PITR.** Il piano gratuito non ha backup utilizzabili per il ripristino. Il
   piano Pro ha i backup giornalieri. Il **PITR** (ripristino a un istante preciso) è
   un'opzione a pagamento in più: attivalo prima di avere utenti veri. Prova almeno una volta
   il ripristino su un progetto di prova.
9. **Advisor.** Apri *Security Advisor* e *Performance Advisor* nel pannello e risolvi gli
   avvisi. Con questo schema non dovrebbero segnalare funzioni senza `search_path` né tabelle
   senza RLS.
10. **Chiavi.** Nell'app solo la chiave *publishable/anon*. La chiave `service_role` resta
    solo nel pannello o in un gestore di segreti, mai in git né in chat. Se è stata esposta
    anche una sola volta, va ruotata.
11. **Tetto di spesa.** Se passi a Pro, attiva il *spend cap* e gli avvisi di consumo.
12. **Pulizia periodica (facoltativa).** Con `pg_cron` puoi cancellare gli inviti scaduti da
    più di 30 giorni e i tentativi più vecchi di un giorno; questi ultimi
    `accept_invite` li pulisce già per l'utente. Le lapidi più vecchie di un anno si possono
    togliere solo dopo una decisione di prodotto: un telefono offline per più tempo non
    saprebbe dell'eliminazione.
13. **Prove a mano sul progetto vero**, con due account di prova:
    - `delete_my_account` cancella davvero l'utente: dipende dai permessi del ruolo
      `postgres` su `auth.users` in Supabase, e va verificato lì;
    - un invito si usa una sola volta;
    - il familiare non vede il pulsante "Elimina" sul cane altrui (dopo A8 e A12).
