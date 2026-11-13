# Consenso allo studio della beta di Lulù (v3)

> **Bozza del 13/11/2026.** Da far leggere a un legale prima dell'uso. Non è un parere legale.
> **Versione del testo: `studio-v3-2026-11`.**
> Coerente con `docs/PRIVACY.md`, `docs/CONSENSO-TELEMETRIA.md`, `ricerca/24`,
> `ricerca/12` §5 e `ricerca/27` §6.4. Le parti `[DA COMPLETARE: …]` vanno riempite.

## Note per lo sviluppatore (non è testo per l'utente)

- Questo consenso è **separato**: dall'uso dell'app, dall'account, dalle condizioni d'uso
  e dai rapporti di errore (`ConsentKind.crashReports`). Ha il suo interruttore e i suoi
  due pulsanti dello stesso peso.
- Nel codice corrisponde a `ConsentKind.study` di `lib/consent.dart`. La costante
  `ConsentStore.studyVersion` oggi vale `tele-2026-11`: va portata a `studio-v3-2026-11`
  **dopo** che questo testo è approvato. Così chi aveva detto sì al testo vecchio torna
  allo stato «spento» e deve scegliere di nuovo (è già il comportamento di `allowed`).
- Il consenso si chiede solo a chi ha confermato l'età. Per la beta: almeno **18 anni**
  (scelta dello studio, vedi «Cose da aggiornare», punto 7).
- Valgono tutte le regole 1-8 di `docs/CONSENSO-TELEMETRIA.md` (spento di serie, non è
  una condizione, ritiro con un tocco, prova del consenso salvata sul telefono, il cane di
  esempio non partecipa mai).
- Il primo livello qui sotto va nella schermata di richiesta. Il link «Leggi tutto» apre
  il secondo livello.

---

## Primo livello: il riassunto (5 righe)

### Partecipi allo studio della prova?

1. Ci aiuti a capire se le previsioni e il piano di uscite funzionano davvero.
2. Il diario resta sul telefono. Escono solo numeri già calcolati, legati a un codice casuale.
3. Non escono mai il nome del cane, le note, le foto, gli orari, le date o dove vivi.
4. Teniamo i numeri in UE fino a 12 mesi dopo la fine della prova.
5. Puoi smettere quando vuoi da **Profilo › Privacy**: cancelliamo i tuoi numeri. Se dici di no, l'app funziona uguale.

[ Sì, partecipo ]   [ No, grazie ]

[Leggi tutto](#secondo-livello) · [Informativa privacy](../../docs/PRIVACY.md)

---

## Secondo livello: il testo completo

### 1. Chi è il titolare

**Lorenzo Birindelli**, persona fisica, sviluppatore dell'app come progetto personale
(come in `docs/PRIVACY.md` §2).

- Indirizzo: `[DA COMPLETARE: via, numero civico, CAP, città]`
- Email per la privacy: `[DA COMPLETARE: email privacy dedicata]`
- Email della prova: `[DA COMPLETARE: casella della beta, oggi segnaposto beta@ESEMPIO.invalid]`

`[DA COMPLETARE: confermare il titolare. Se il CNR rivendica diritti sull'app (ricerca/24 §6),
il titolare può cambiare e questo testo va rifatto.]`

Non c'è un Responsabile della protezione dei dati (DPO): non è obbligatorio per questo
trattamento (`docs/PRIVACY.md` §2).

### 2. Perché trattiamo questi dati

Per **valutare se le funzioni della prova funzionano** sui cani veri:
- la previsione della prossima pipì;
- la previsione della cacca dopo i pasti;
- il piano di uscite della giornata (3, 4 o 5 uscite) e il rischio stimato;
- quanto spesso succede un incidente in casa;
- se i segnali del cane (annusa a terra, gira su sé stesso, va alla porta, guaisce, è
  irrequieto) arrivano prima della pipì.

Usiamo i risultati per decidere come migliorare l'app e per scrivere un rapporto. Nel
rapporto ci sono solo tabelle riassuntive.

Non usiamo questi dati per pubblicità, non li vendiamo e non li usiamo per decisioni su
di te.

### 3. Base giuridica

Il tuo **consenso** (art. 6.1.a GDPR), separato da tutto il resto. Puoi ritirarlo in ogni
momento. Il ritiro non rende illecito ciò che è stato fatto prima.

Per leggere e scrivere dati sul telefono vale l'art. 122 del Codice privacy (come in
`docs/REGISTRO-TRATTAMENTI.md`, T4).

### 4. Il codice casuale (pid)

- Quando dici sì, il telefono crea un **codice casuale**, uno per ogni cane.
- Il codice **non deriva** dal tuo account, dal tuo nome o dal nome del cane.
- La corrispondenza tra codice e cane resta **solo sul tuo telefono**.
- La legge considera questi dati comunque **personali** (sono «pseudonimi»): li trattiamo
  come tali.

### 5. Cosa esce dal telefono

Escono solo **numeri già calcolati sul telefono**. Ci arrivano in uno di questi modi:

**a) Il file che mandi tu.** Nell'app c'è un'esportazione anonima: un file che crei tu e
mandi tu (per esempio per email) all'indirizzo della prova. Lo puoi aprire e leggere prima
di mandarlo.

**b) L'invio automatico, se presente nella tua versione.** `[DA COMPLETARE: dire se la v3
invia anche ogni giorno, senza account, a un server Supabase in UE (Francoforte), come in
ricerca/12 §5.3. Se no, togliere questo punto.]`

Il contenuto è lo stesso:

| Gruppo | Cosa contiene | Come è reso meno preciso |
|---|---|---|
| Sul cane | codice casuale; fascia d'età (cucciolo, adulto, anziano); fascia di taglia (meno di 10, 10-25, 25-45, oltre 45 kg); sesso e se è sterilizzato; malattia cronica sì/no; giardino o terrazzo dove può fare i bisogni da solo sì/no; come esce di solito (quando lo chiede, a orari fissi, un po' e un po', accesso libero al giardino) | solo fasce e categorie, nessun testo libero |
| Per ogni evento (pipì o cacca) | giorno dello studio (0, 1, 2…); parte della giornata; di quanto ha sbagliato la previsione; se è successo in casa (sì/no); se prima hai segnato un segnale (sì/no) | minuti arrotondati a 5; nessun orario, nessuna data |
| Per ogni giorno | numero di uscite | solo il numero |
| Tecnico | versione dell'app, della previsione e di questo testo | |

`[DA COMPLETARE: allineare questa tabella al formato definitivo del file di esportazione
e, se c'è, dell'invio automatico. Ogni campo in più va aggiunto qui prima, e cambia la
versione del testo.]`

### 6. Cosa non esce mai

Il diario, il nome del cane, la razza scritta da te, le note, le foto, il testo delle
malattie, gli orari, le date, la data di nascita, la tua città o la tua posizione, il
veterinario, i sintomi e gli altri eventi di salute, i farmaci e le dosi, il tuo account,
identificativi pubblicitari.

**Nessun dato sulla tua salute.** Non ti chiediamo nulla sulla tua salute. I dati sulla
salute del **cane** non sono «dati sanitari» ai sensi del GDPR, che riguardano le persone.
Li trattiamo comunque con cura, perché insieme agli orari potrebbero dire qualcosa delle
tue abitudini (`docs/DPIA.md` §3). Per questo gli orari non escono.

### 7. Se mandi il file per email

Quando mandi il file per email, **vediamo il tuo indirizzo email** insieme al codice
casuale. Per ridurre questo legame:
- salviamo il file **separato** dall'email, senza il tuo indirizzo;
- teniamo l'email solo il tempo necessario a confermarti che è arrivata, poi la
  cancelliamo `[DA COMPLETARE: entro quanti giorni]`;
- non scriviamo mai il codice casuale accanto ai tuoi dati di contatto del modulo di
  adesione;
- solo `[DA COMPLETARE: chi]` può leggere la casella.

Manda il file **solo** all'indirizzo della prova. Non metterlo in gruppi o chat condivise.

**Attenzione:** non mandarci il backup completo (Profilo › Esporta tutti i dati). Quello
contiene tutto il diario. Ci serve solo il file dell'esportazione anonima.

### 8. Dove sono i dati

- File ricevuti per email: casella `[DA COMPLETARE: fornitore]` con server in UE.
- Tabelle dello studio: `[DA COMPLETARE: dove; se Supabase, in UE (Francoforte), in una
  tabella separata dallo schema dell'app]`.
- Chi li legge: chi analizza i dati dello studio e chi coordina il progetto
  (`docs/REGISTRO-TRATTAMENTI.md`, T4).

### 9. Per quanto tempo

| Dati | Conservazione |
|---|---|
| Numeri dello studio (file e tabelle) | fino a **12 mesi dopo la fine della beta**. Poi restano solo tabelle riassuntive, in cui nessuna casella descrive meno di 5 cani |
| Email con cui mandi il file | `[DA COMPLETARE: N giorni]` |
| Se ritiri il consenso | cancellazione dei tuoi numeri entro 30 giorni |

### 10. Come smetti e come chiedi la cancellazione

- Spegni l'interruttore in **Profilo › Privacy**. Un tocco, senza spiegazioni.
- L'app smette subito di preparare i numeri dello studio `[DA COMPLETARE: e, se c'è
  l'invio automatico, chiede la cancellazione per il codice]`.
- Per i **file che ci hai già mandato**, scrivici a `[DA COMPLETARE: email della prova]`
  con il codice casuale. Lo trovi nel file o in `[DA COMPLETARE: dove l'app mostra il
  codice]`. Cancelliamo entro 30 giorni.
- Se disinstalli l'app senza dirci il codice, non possiamo più trovare i tuoi numeri: in
  quel caso restano fino alla scadenza dei 12 mesi. Prima di disinstallare, spegni lo
  studio o annota il codice.
- Smettere non cambia nulla nell'app: continua a funzionare uguale.

### 11. I tuoi diritti

Puoi chiedere di **accedere** ai tuoi dati, **correggerli**, **cancellarli**,
**limitarne** l'uso e **riceverli** in un file. Puoi **ritirare il consenso** in ogni
momento. Puoi fare **reclamo** al Garante per la protezione dei dati personali
(www.garanteprivacy.it) o all'autorità del Paese UE in cui vivi.

Scrivi a `[DA COMPLETARE: email privacy]`. Rispondiamo entro un mese (art. 12 GDPR).
Per trovare i tuoi dati ci serve il codice casuale.

Non ci sono decisioni automatiche su di te (art. 22 GDPR). Le previsioni riguardano il
cane e sono solo consigli.

### 12. Minori

La prova è solo per persone di **almeno 18 anni**. I minori non possono partecipare né
dare questo consenso.

### 13. Contatti

- Domande sulla prova: `[DA COMPLETARE: email della prova]`
- Domande sulla privacy: `[DA COMPLETARE: email privacy]`
- Informativa completa: `docs/PRIVACY.md` `[DA COMPLETARE: URL pubblico]`

### 14. Modifiche

Se cambia cosa raccogliamo, cambiamo prima questo testo e la sua versione, e ti
chiediamo di nuovo il consenso. Fino ad allora l'interruttore resta spento.

---

## Testo breve per Profilo › Privacy

- **Studio della prova** — Prepara solo numeri calcolati sul telefono, senza diario, nomi,
  orari o posizione. [interruttore] · [Dettagli] · Codice: `[DA COMPLETARE: mostrare il pid?]`

Messaggio al ritiro: «Fatto. Non prepariamo più i numeri dello studio. Per cancellare i
file che ci hai già mandato, scrivici con il tuo codice.»
`[DA COMPLETARE: se c'è l'invio automatico, usare il messaggio di docs/CONSENSO-TELEMETRIA.md]`

---

## Cose da aggiornare (non modificati in questa consegna)

1. **`docs/REGISTRO-TRATTAMENTI.md`, T4 Studio.** Aggiungere: (a) i campi nuovi (giardino
   sì/no, segnale sì/no per evento, numero di uscite al giorno, stile di uscita già
   previsto); (b) il canale «file inviato dal partecipante per email»; (c) la casella
   della beta tra i destinatari; (d) la conservazione delle email; (e) la versione
   `studio-v3-2026-11`.
2. **`docs/REGISTRO-TRATTAMENTI.md`, nuovo trattamento «Reclutamento della beta».**
   Dati del modulo `adesione.html` (contatto, fasce del cane, lavoro fuori casa, tipo di
   telefono); base giuridica da decidere con il legale; conservazione: non inclusi
   cancellati entro 30 giorni dalla chiusura del reclutamento, inclusi `[DA COMPLETARE]`;
   foglio ad accesso limitato.
3. **`docs/REGISTRO-TRATTAMENTI.md`, «Trattamenti esclusi» › Notifiche.** Oggi dice
   «locali, nessun server di notifiche push». Su iPhone come app web (PWA) le notifiche
   con l'app chiusa di norma richiedono un servizio push via server. Se la v3 lo usa,
   è un trattamento nuovo con un destinatario nuovo (servizio push di Apple) e va
   descritto. `[DA VERIFICARE con lo sviluppatore]`
4. **`docs/DPIA.md`, R6 (reidentificazione).** Il canale email lega il codice casuale a un
   indirizzo email: il rischio sale. Misure: file separato dall'email, cancellazione
   dell'email, accesso limitato alla casella, codice mai accanto al contatto del modulo.
5. **`docs/DPIA.md`, rischi nuovi.** (a) Il partecipante manda il backup completo invece
   dell'esportazione anonima; (b) il file viene condiviso in chat o gruppi; (c) il
   foglio delle adesioni lega contatto e caratteristiche del cane. Valutare P, G e misure.
6. **`docs/DPIA.md` §1, criterio 3 (monitoraggio).** Il piano di uscite e i segnali
   aumentano la quantità di dati sul telefono, non quelli che escono: annotarlo.
7. **Età.** `docs/PRIVACY.md` §9, `docs/CONSENSO-TELEMETRIA.md` regola 6, `docs/DPIA.md`
   (criterio 7, R11) e `ConsentStore.ageVersion` parlano di 14 anni. La beta chiede 18.
   Decidere se la regola dei 18 anni vale solo per la beta o per tutto lo studio, e
   scriverlo nei documenti.
8. **`docs/CONSENSO-TELEMETRIA.md`.** Oggi descrive un invio automatico giornaliero e dice
   «non inviamo mai… la tua email». Con il file mandato per email questo non è più vero
   per quel canale: aggiornare il testo o rimandare a questo.
9. **`docs/PRIVACY.md` §4 e §6.** Riga «Studio sull'accuratezza»: aggiungere il canale
   email e la conservazione delle email. Valutare il nome «Lulù» al posto di «Zampa».
10. **`lib/consent.dart`.** `studyVersion` da `tele-2026-11` a `studio-v3-2026-11` (non
    toccato: è in `lib/`).
11. **Schede degli store** (`ricerca/24` §4): se cambia cosa esce, rivedere «Sicurezza dei
    dati» di Google Play e le etichette di Apple.
12. **Posizione (geofence).** Se il recinto intorno a casa (`lib/logic/outing_geofence.dart`)
    entra nella beta, cambia `docs/PRIVACY.md` §3 («non usa il GPS») e servono una voce
    nel registro e una nella DPIA, anche se la posizione resta sul telefono.
